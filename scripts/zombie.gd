extends CharacterBody2D

@export var speed = 60.0
@export var wander_range = 150

enum State { IDLE, SEARCHING, CHASING, DOWN }

@onready var animated_sprite = $AnimatedSprite2D
@onready var state_label = $StateLabel

var state = State.IDLE:
	set(new_state):
		if state == new_state:
			return
		state = new_state
		_update_animation()
		if state_label:
			state_label.text = State.keys()[new_state].to_upper()

var target_position = Vector2.ZERO
var chase_target = null

func _ready():
	add_to_group("zombies")
	target_position = position
	_start_idle_timer()
	SoundManager.sound_emitted.connect(_on_sound_emitted)

func _physics_process(_delta):
	if state == State.IDLE or state == State.SEARCHING:
		_scan_for_targets()

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
				self.state = State.IDLE
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
				self.state = State.IDLE
				chase_target = null
				_start_idle_timer()
		State.DOWN:
			velocity = Vector2.ZERO
			move_and_slide()
	
	# Update movement animations
	_update_movement_animation()
	update_facing_direction()

func update_facing_direction():
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false

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
		self.state = State.SEARCHING
		_pick_new_wander_destination()

func _on_detection_area_body_exited(body):
	if state == State.DOWN:
		return
	if body == chase_target:
		self.state = State.IDLE
		chase_target = null
		_start_idle_timer()

func go_down():
	self.state = State.DOWN
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
			self.state = State.SEARCHING
			target_position = sound_position

func _scan_for_targets():
	var bodies = $DetectionArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("humans") or body.is_in_group("police"):
			if has_line_of_sight(body):
				if not is_instance_valid(chase_target):
					self.state = State.CHASING
					chase_target = body
					$WanderTimer.stop()
					return

func has_line_of_sight(target):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position, 4) # 4 is the mask for layer 3, "walls"
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func _update_animation():
	# Handle state-based animations
	match state:
		State.IDLE:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
		State.SEARCHING:
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		State.CHASING:
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		State.DOWN:
			if animated_sprite.animation != "die":
				animated_sprite.play("die")

func _update_movement_animation():
	# Handle movement-based animations (override state animations when moving)
	if velocity.length() > 0 and state != State.DOWN:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	elif state == State.IDLE and velocity.length() == 0:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
