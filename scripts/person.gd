extends CharacterBody2D

signal conversion_complete(person)

const IDLE = 0
const WANDER = 1
const INFECTED = 2

@export var speed = 100.0
@export var wander_range = 200

var state = IDLE
var target_position = Vector2.ZERO

func _ready():
	add_to_group("humans")
	target_position = position
	_start_idle_timer()

func _physics_process(_delta):
	match state:
		IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
		WANDER:
			if position.distance_to(target_position) > 5.0:
				var direction = position.direction_to(target_position)
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
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	target_position = position + random_offset
	target_position.x = clamp(target_position.x, 0, 1024)
	target_position.y = clamp(target_position.y, 0, 600)

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