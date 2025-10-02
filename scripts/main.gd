extends Node2D

const ZOMBIE_SCENE = preload("res://scenes/zombie.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var zombies = get_tree().get_nodes_in_group("zombies")
	for zombie in zombies:
		zombie.human_caught.connect(_on_zombie_human_caught)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_zombie_human_caught(human):
	if human.is_queued_for_deletion():
		return
		
	var human_position = human.position
	human.queue_free()

	var new_zombie = ZOMBIE_SCENE.instantiate()
	new_zombie.position = human_position
	add_child(new_zombie)
	new_zombie.human_caught.connect(_on_zombie_human_caught)
