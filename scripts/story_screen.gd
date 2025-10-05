extends Control

func _ready():
	# The timer will automatically start and count down 6 seconds
	pass

func _on_timer_timeout():
	# After 6 seconds, load the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event):
	# Allow player to skip by pressing any key or clicking
	if event is InputEventKey and event.pressed:
		_on_timer_timeout()
	elif event is InputEventMouseButton and event.pressed:
		_on_timer_timeout()
