extends Node2D

const ZOMBIE_SCENE = preload("res://scenes/zombie.tscn")

@onready var ui = $GameUI/HUD

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	# Force window size for Mac - try multiple approaches
	call_deferred("_set_window_size")
	
	# Also try setting it immediately
	get_window().size = Vector2i(2560, 1440)
	get_window().position = Vector2i(100, 100)
	
	var humans = get_tree().get_nodes_in_group("humans")
	for human in humans:
		human.conversion_complete.connect(_on_conversion_complete)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var humans = get_tree().get_nodes_in_group("humans").size()
	var police = get_tree().get_nodes_in_group("police").size()
	var zombies = get_tree().get_nodes_in_group("zombies").size()
	
	ui.update_counts(humans - police, zombies, police)

func _set_window_size():
	# Try setting window size after everything is initialized
	get_window().size = Vector2i(2560, 1440)
	get_window().position = Vector2i(100, 100)
	print("Window size set to: ", get_window().size)

func _on_conversion_complete(person):
	if person.is_queued_for_deletion():
		return
		
	var person_position = person.position
	person.queue_free()

	var new_zombie = ZOMBIE_SCENE.instantiate()
	new_zombie.position = person_position
	add_child(new_zombie)
