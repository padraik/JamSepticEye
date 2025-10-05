extends Node2D

const ZOMBIE_SCENE = preload("res://scenes/zombie.tscn")
const PHASE1_OVERLAY_SCENE = preload("res://scenes/phase1_overlay.tscn")
const PHASE1_WIN_OVERLAY_SCENE = preload("res://scenes/phase1_win_overlay.tscn")

@onready var ui = $GameUI/HUD

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	var humans = get_tree().get_nodes_in_group("humans")
	for human in humans:
		human.conversion_complete.connect(_on_conversion_complete)

	# Show Phase 1 overlay at start
	var overlay = PHASE1_OVERLAY_SCENE.instantiate()
	add_child(overlay)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var humans = get_tree().get_nodes_in_group("humans").size()
	var police = get_tree().get_nodes_in_group("police").size()
	var zombies = get_tree().get_nodes_in_group("zombies").size()
	
	ui.update_counts(humans - police, zombies, police)

	# Win condition: no humans and no police
	if humans - police <= 0 and police <= 0:
		_trigger_phase1_win()

func _on_conversion_complete(person):
	if person.is_queued_for_deletion():
		return
		
	var person_position = person.position
	person.queue_free()

	var new_zombie = ZOMBIE_SCENE.instantiate()
	new_zombie.position = person_position
	add_child(new_zombie)

var _win_triggered := false

func _trigger_phase1_win():
	if _win_triggered:
		return
	_win_triggered = true
	var overlay = PHASE1_WIN_OVERLAY_SCENE.instantiate()
	add_child(overlay)
