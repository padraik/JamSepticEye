extends CanvasLayer

@onready var timer = $Timer
@onready var news_screen = $NewsScreen
@onready var win_screen = $WinScreen

var news_screen_active = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	get_tree().paused = true
	
	news_screen.visible = true
	win_screen.visible = false
	news_screen_active = true
	
	timer.wait_time = 5.0
	timer.start()

func _unhandled_input(event):
	if news_screen_active and event.is_action_pressed("ui_accept"):
		timer.stop()
		_show_win_screen()

func _on_timer_timeout():
	if news_screen_active:
		_show_win_screen()
	else:
		# Timer for the final win screen has finished
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/phase-2-main.tscn")
		queue_free()

func _show_win_screen():
	news_screen_active = false
	news_screen.visible = false
	win_screen.visible = true
	
	# Start a new, shorter timer for the win screen itself
	timer.wait_time = 3.0
	timer.start()

