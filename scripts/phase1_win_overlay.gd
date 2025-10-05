extends CanvasLayer

@onready var timer = $Timer

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = true
	get_tree().paused = true
	timer.start()

func _on_timer_timeout():
	# After displaying the win screen, go back to title. Adjust if needed.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

