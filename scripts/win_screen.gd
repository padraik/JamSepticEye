extends Control

func _ready():
	# Timer in scene handles auto-advance; allow skip too
	pass

func _on_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		_on_timer_timeout()
	elif event is InputEventMouseButton and event.pressed:
		_on_timer_timeout()

