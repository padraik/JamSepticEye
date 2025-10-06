extends CanvasLayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	$Timer.start()

func _on_timer_timeout():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	queue_free()
