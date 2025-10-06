extends CharacterBody2D

const HUMAN_SCENE = preload("res://scenes/human.tscn")

@export var speed = 300.0
@onready var conversion_area = $ConversionArea
@onready var animated_sprite = $AnimatedSprite2D
@onready var dezombie_cloud = $DezombieCloud
@onready var dezombie_area = $DezombieArea
@onready var dezombie_timer = $DezombieTimer

var is_stabbing = false
var stab_timer: Timer
var can_dezombify = true

func _ready():
	add_to_group("player")
	# Connect to animation finished signal
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Create timer for stab animation
	stab_timer = Timer.new()
	stab_timer.wait_time = 0.5
	stab_timer.one_shot = true
	stab_timer.timeout.connect(_on_stab_timer_timeout)
	add_child(stab_timer)
	dezombie_timer.timeout.connect(_on_dezombie_timer_timeout)

func _physics_process(_delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	
	update_animation(direction)
	update_facing_direction(direction)

	if Input.is_action_just_pressed("ui_accept"):
		var scene_name = get_tree().current_scene.scene_file_path
		if "phase-2-main" in scene_name:
			_attempt_dezombification()
		else:
			_attempt_conversion()
			is_stabbing = true
			animated_sprite.play("stab")
			# Start timer as backup
			stab_timer.start()

func update_animation(direction):
	if not is_stabbing:
		if direction.length() > 0:
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

func update_facing_direction(direction):
	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false

func _attempt_conversion():
	var bodies = conversion_area.get_overlapping_bodies()
	var closest_body = null
	var min_distance = INF

	for body in bodies:
		if body.is_in_group("humans"):
			var distance = position.distance_to(body.position)
			if distance < min_distance:
				min_distance = distance
				closest_body = body
	
	if closest_body:
		closest_body.infect()

func _attempt_dezombification():
	if not can_dezombify:
		return
	
	can_dezombify = false
	dezombie_cloud.visible = true
	
	var tween = create_tween()
	tween.tween_property(dezombie_cloud, "modulate:a", 1.0, 0.2)
	
	dezombie_timer.start()
	
	var zombies_in_area = dezombie_area.get_overlapping_bodies()
	for zombie in zombies_in_area:
		if zombie.is_in_group("zombies"):
			var z_pos = zombie.global_position
			zombie.queue_free()
			
			var new_human = HUMAN_SCENE.instantiate()
			get_tree().current_scene.get_node("World/NPCS").add_child(new_human)
			new_human.global_position = z_pos

func _on_dezombie_timer_timeout():
	var tween = create_tween()
	tween.tween_property(dezombie_cloud, "modulate:a", 0.0, 0.3)
	await tween.finished
	dezombie_cloud.visible = false
	can_dezombify = true

func _on_animation_finished():
	if animated_sprite.animation == "stab":
		_return_to_movement_animation()

func _on_stab_timer_timeout():
	if is_stabbing:
		_return_to_movement_animation()

func _return_to_movement_animation():
	is_stabbing = false
	stab_timer.stop()
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length() > 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
