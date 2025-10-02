extends CharacterBody2D

@export var speed = 60.0
@export var wander_range = 150

enum State { IDLE, SEARCHING, CHASING, DOWN }

@onready var animator = $ZombieAnimator
@onready var state_label = $StateLabel

var state = State.IDLE:
	set(new_state):
		if state == new_state:
			return
		state = new_state
		if animator:
			animator.update_animation(state)
		if state_label:
			state_label.text = State.keys()[new_state].to_upper()

var target_position = Vector2.ZERO
var chase_target = null

func _ready():
	add_to_group("zombies")
	target_position = position
	_start_idle_timer()
	SoundManager.sound_emitted.connect(_on_sound_emitted)
	animator.update_animation(state)

func _physics_process(_delta):
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
				move_and_slide()
				
				for i in get_slide_collision_count():
					var collision = get_slide_collision(i)
					if collision.get_collider().is_in_group("humans"):
						collision.get_collider().infect()
			else:
				state = State.IDLE
				chase_target = null
				_start_idle_timer()
		State.DOWN:
			velocity = Vector2.ZERO
			move_and_slide()

func _pick_new_wander_destination():
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	target_position = position + random_offset
	target_position.x = clamp(target_position.x, 0, 1024)
	target_position.y = clamp(target_position.y, 0, 600)

func _start_idle_timer():
	if not is_inside_tree():
		return
	$WanderTimer.wait_time = randf_range(2.0, 4.0)
	$WanderTimer.start()

func _on_wander_timer_timeout():
	if state == State.IDLE:
		state = State.SEARCHING
		_pick_new_wander_destination()

func _on_detection_area_body_entered(body):
	if state == State.DOWN:
		return
	if body.is_in_group("humans"):
		if chase_target == null:
			state = State.CHASING
			chase_target = body
			$WanderTimer.stop()

func _on_detection_area_body_exited(body):
	if state == State.DOWN:
		return
	if body == chase_target:
		state = State.IDLE
		chase_target = null
		_start_idle_timer()

func go_down():
	state = State.DOWN
	$CollisionShape2D.disabled = true
	$DetectionArea/CollisionShape2D.disabled = true
	$WanderTimer.stop()

func is_down():
	return state == State.DOWN

func _on_sound_emitted(sound_position, sound_radius):
	if state == State.DOWN:
		return
	if state == State.IDLE or state == State.SEARCHING:
		if position.distance_to(sound_position) <= sound_radius:
			state = State.SEARCHING
			target_position = sound_position
