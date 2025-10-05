extends CharacterBody2D

@export var speed = 110.0
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
var rng = RandomNumberGenerator.new()
var map_rect = Rect2()
var stuck_timer = 0.0
const STUCK_THRESHOLD_WALL = 1.5
const STUCK_THRESHOLD_NPC = 0.5

func _ready():
	call_deferred("_initialize_map_boundaries")
	rng.randomize()
	add_to_group("zombies")
	target_position = global_position
	_start_idle_timer()
	SoundManager.sound_emitted.connect(_on_sound_emitted)

func _initialize_map_boundaries():
	var ground_map = get_tree().get_first_node_in_group("ground_map")
	if ground_map and ground_map is TileMapLayer:
		var used_rect = ground_map.get_used_rect()
		var tile_size = ground_map.tile_set.tile_size
		map_rect = Rect2(
			ground_map.to_global(used_rect.position * tile_size),
			used_rect.size * tile_size
		)
	else:
		print_debug("ERROR: Could not find a TileMapLayer in group 'ground_map'. Wander boundaries will be incorrect.")
		map_rect = Rect2(0, 0, 1024, 600)

func _physics_process(_delta):
	if state == State.IDLE or state == State.SEARCHING:
		_scan_for_targets()

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
			stuck_timer = 0.0
		State.SEARCHING:
			if global_position.distance_to(target_position) > 5.0:
				var direction = global_position.direction_to(target_position)
				velocity = direction * speed

				var position_before_move = global_position
				move_and_slide()

				var stuck_threshold = STUCK_THRESHOLD_WALL
				if get_slide_collision_count() > 0:
					var collision = get_slide_collision(0)
					if collision.get_collider().is_in_group("humans") or collision.get_collider().is_in_group("police") or collision.get_collider().is_in_group("zombies"):
						stuck_threshold = STUCK_THRESHOLD_NPC

				var distance_moved = position_before_move.distance_to(global_position)
				if distance_moved < 0.1:
					stuck_timer += _delta
					if stuck_timer > stuck_threshold:
						stuck_timer = 0.0
						self.state = State.IDLE
						_start_idle_timer()
				else:
					stuck_timer = 0.0
			else:
				self.state = State.IDLE
				_start_idle_timer()
		State.CHASING:
			if is_instance_valid(chase_target):
				var direction = global_position.direction_to(chase_target.global_position)
				velocity = direction * speed * 1.5 # Chase faster than wandering
				
				var position_before_move = global_position
				move_and_slide()

				var stuck_threshold = STUCK_THRESHOLD_WALL
				var is_stuck_on_npc = false
				var collider = null
				
				if get_slide_collision_count() > 0:
					var collision = get_slide_collision(0)
					collider = collision.get_collider()
					if collider.is_in_group("humans") or collider.is_in_group("police") or collider.is_in_group("zombies"):
						stuck_threshold = STUCK_THRESHOLD_NPC
						is_stuck_on_npc = true
				
				var distance_moved = position_before_move.distance_to(global_position)
				if distance_moved < 0.1:
					stuck_timer += _delta
					if stuck_timer > stuck_threshold:
						stuck_timer = 0.0
						if is_stuck_on_npc and is_instance_valid(collider):
							_pick_evasive_destination_while_chasing(collider)
						else:
							self.state = State.IDLE
							chase_target = null
							_start_idle_timer()
				else:
					stuck_timer = 0.0
				
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

func _pick_evasive_destination_while_chasing(obstacle):
	var away_direction = obstacle.global_position.direction_to(global_position)
	var random_angle = rng.randf_range(-PI / 2, PI / 2) # -90 to +90 degrees for more variance
	var evasive_direction = away_direction.rotated(random_angle)
	
	# Aim for a point "around" the obstacle, but still generally towards the chase target
	var point_around_obstacle = global_position + evasive_direction * 75
	var direction_to_target = point_around_obstacle.direction_to(chase_target.global_position)
	
	target_position = point_around_obstacle + direction_to_target * 50
	
	state = State.SEARCHING # Temporarily search for this new point
	
func _pick_new_wander_destination():
	if map_rect.size == Vector2.ZERO:
		return

	var min_x = max(map_rect.position.x, global_position.x - wander_range)
	var max_x = min(map_rect.end.x, global_position.x + wander_range)
	var min_y = max(map_rect.position.y, global_position.y - wander_range)
	var max_y = min(map_rect.end.y, global_position.y + wander_range)

	if min_x > max_x or min_y > max_y:
		target_position = Vector2(
			rng.randf_range(map_rect.position.x, map_rect.end.x),
			rng.randf_range(map_rect.position.y, map_rect.end.y)
		)
	else:
		target_position = Vector2(
			rng.randf_range(min_x, max_x),
			rng.randf_range(min_y, max_y)
		)

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
	z_index = -1
	collision_layer = 0
	collision_mask = 0
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
	
	# Prioritize the player
	for body in bodies:
		if body.is_in_group("player"):
			if has_line_of_sight(body):
				if not is_instance_valid(chase_target):
					self.state = State.CHASING
					chase_target = body
					$WanderTimer.stop()
					return
	
	# If player not found or not visible, scan for others
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

	if not result.is_empty():
		print_debug("Line of sight from ", name, " to ", target.name, " is blocked by: ", result.collider.name)

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
