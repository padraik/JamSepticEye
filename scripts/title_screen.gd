extends Control

func _ready():
	# Make sure the button is focused for keyboard navigation
	$PlayButton.grab_focus()

func _on_play_button_pressed():
	# Load the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event):
	# Allow Enter key to start the game
	if event.is_action_pressed("ui_accept"):
		_on_play_button_pressed()
