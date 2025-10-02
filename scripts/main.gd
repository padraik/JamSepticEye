extends Node2D

const ZOMBIE_SCENE = preload("res://scenes/zombie.tscn")

@onready var ui = $GameUI/HUD

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var zombies = get_tree().get_nodes_in_group("zombies")
	for zombie in zombies:
		zombie.human_caught.connect(_convert_to_zombie)
	
	get_node("Player").conversion_initiated.connect(_on_conversion_initiated)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var humans = get_tree().get_nodes_in_group("humans").size()
	var police = get_tree().get_nodes_in_group("police").size()
	var zombies = get_tree().get_nodes_in_group("zombies").size()
	
	ui.update_counts(humans - police, zombies, police)

func _convert_to_zombie(human):
	if human.is_queued_for_deletion():
		return
		
	var human_position = human.position
	human.queue_free()

	var new_zombie = ZOMBIE_SCENE.instantiate()
	new_zombie.position = human_position
	add_child(new_zombie)
	new_zombie.human_caught.connect(_convert_to_zombie)

func _on_conversion_initiated(target):
	if target.is_being_converted:
		return
	
	target.is_being_converted = true
	await get_tree().create_timer(3.0).timeout
	
	if is_instance_valid(target):
		_convert_to_zombie(target)
