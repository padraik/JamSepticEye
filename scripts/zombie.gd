extends CharacterBody2D

signal human_caught(human)

@export var speed = 60.0
@export var wander_range = 150

enum State { IDLE, SEARCHING, CHASING }
var state = State.IDLE
var target_position = Vector2.ZERO
var chase_target = null

var _state_label

func _ready():
	add_to_group("zombies")
	target_position = position
	_start_idle_timer()
	_create_debug_visuals()

func _create_debug_visuals():
	# Create the state label
	_state_label = Label.new()
	add_child(_state_label)
	_state_label.position = Vector2(-25, -75)
	
	# Draw the detection radius
	var detection_radius = $DetectionArea/CollisionShape2D.shape.radius
	var points = PackedVector2Array()
	for i in range(33):
		var angle = i * (2 * PI / 32)
		points.append(Vector2(cos(angle), sin(angle)) * detection_radius)
	$DetectionRadiusVisual.polygon = points

func _physics_process(delta):
	_state_label.text = State.keys()[state]
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
		State.SEARCHING:
			if position.distance_to(target_position) > 5.0:
				var direction = position.direction_to(target_position)
				velocity = direction * speed
				move_and_slide()
			else:
				state = State.IDLE
				_start_idle_timer()
		State.CHASING:
			if is_instance_valid(chase_target):
				var direction = position.direction_to(chase_target.position)
				velocity = direction * speed * 1.5 # Chase faster than wandering
				var collision = move_and_collide(velocity * delta)
				if collision:
					if collision.get_collider().is_in_group("humans"):
						emit_signal("human_caught", collision.get_collider())
			else:
				state = State.IDLE
				chase_target = null
				_start_idle_timer()

func _pick_new_wander_destination():
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	target_position = position + random_offset
	target_position.x = clamp(target_position.x, 0, 1024)
	target_position.y = clamp(target_position.y, 0, 600)

func _start_idle_timer():
	$WanderTimer.wait_time = randf_range(2.0, 4.0)
	$WanderTimer.start()

func _on_wander_timer_timeout():
	if state == State.IDLE:
		state = State.SEARCHING
		_pick_new_wander_destination()

func _on_detection_area_body_entered(body):
	if body.is_in_group("humans"):
		if chase_target == null:
			state = State.CHASING
			chase_target = body
			$WanderTimer.stop()

func _on_detection_area_body_exited(body):
	if body == chase_target:
		state = State.IDLE
		chase_target = null
		_start_idle_timer()
