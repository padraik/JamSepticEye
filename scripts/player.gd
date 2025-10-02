extends CharacterBody2D

signal conversion_initiated(target)

@export var speed = 300.0
@onready var conversion_area = $ConversionArea

func _physics_process(_delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		_attempt_conversion()

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
		conversion_initiated.emit(closest_body)
