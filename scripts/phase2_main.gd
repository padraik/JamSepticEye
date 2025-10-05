extends Node2D

@onready var ui = $GameUI/HUD

func _process(_delta):
	var humans = get_tree().get_nodes_in_group("humans").size()
	var police = get_tree().get_nodes_in_group("police").size()
	var zombies = get_tree().get_nodes_in_group("zombies").size()
	ui.update_counts(humans - police, zombies, police)

	# Win condition for Phase 2: no zombies remain
	if zombies <= 0:
		get_tree().change_scene_to_file("res://scenes/win_screen.tscn")

func _unhandled_input(event):
	# Debug: Press 'P' to instantly win Phase 2
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:
			get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
