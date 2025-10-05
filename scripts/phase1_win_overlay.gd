extends CanvasLayer

@onready var timer = $Timer

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = true
	get_tree().paused = true
	timer.start()

func _on_timer_timeout():
	# After the win screen, continue to Phase 2 main scene
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/phase2_main.tscn")

