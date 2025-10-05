extends CharacterBody2D

signal conversion_complete(person)

const IDLE = 0
const WANDER = 1
const INFECTED = 2

@export var speed = 100.0
@export var wander_range = 200

var rng = RandomNumberGenerator.new()
var state = IDLE
var target_position = Vector2.ZERO
var map_rect = Rect2()

func _ready():
	call_deferred("_initialize_map_boundaries")
	rng.randomize()
	add_to_group("humans")
	target_position = global_position
	_start_idle_timer()

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
	match state:
		IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
		WANDER:
			if global_position.distance_to(target_position) > 5.0:
				var direction = global_position.direction_to(target_position)
				velocity = direction * speed
				move_and_slide()
			else:
				state = IDLE
				velocity = Vector2.ZERO
				_start_idle_timer()
		INFECTED:
			velocity = Vector2.ZERO
			move_and_slide()
	
	update_facing_direction()

func update_facing_direction():
	if velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
	elif velocity.x > 0:
		$AnimatedSprite2D.flip_h = false

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
	
	print("New wander destination for ", name, ": from ", global_position, " to ", target_position)

func _start_idle_timer():
	$WanderTimer.wait_time = randf_range(1.0, 2.0)
	$WanderTimer.start()

func infect():
	if state == INFECTED:
		return
	
	state = INFECTED
	$WanderTimer.stop()
	$ConversionTimer.start()

func _on_wander_timer_timeout():
	if state == IDLE:
		state = WANDER
		_pick_new_wander_destination()

func _on_conversion_timer_timeout():
	emit_signal("conversion_complete", self)

func has_line_of_sight(target):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position, 4) # 4 is the mask for layer 3, "walls"
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.is_empty()