extends CanvasLayer

@onready var texture_rect = $TextureRect

func _ready():
	# Ensure this overlay processes inputs when the game is paused (Godot 4)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# Show overlay and pause the game until the player presses WASD
	visible = true
	get_tree().paused = true

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		_dismiss_overlay()

func _dismiss_overlay():
	visible = false
	get_tree().paused = false
	queue_free()
