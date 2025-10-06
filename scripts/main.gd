extends Node2D

const ZOMBIE_SCENE = preload("res://scenes/zombie.tscn")
const PHASE1_OVERLAY_SCENE = preload("res://scenes/phase1_overlay.tscn")
const PHASE1_WIN_OVERLAY_SCENE = preload("res://scenes/phase1_win_overlay.tscn")
const GAME_OVER_SCENE = preload("res://scenes/game_over_screen.tscn")
const PHASE2_WIN_OVERLAY_SCENE = preload("res://scenes/phase2_win_overlay.tscn")

@onready var ui = $GameUI/HUD
var game_over = false

# Called when the node enters the scene tree for the first time.
func _ready():
	GameEvents.player_caught.connect(_on_player_caught)
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

	# Check win conditions based on the current scene
	var scene_name = get_tree().current_scene.scene_file_path
	if "phase-2-main" in scene_name:
		# Phase 2 Win Condition: No zombies left
		if zombies <= 0 and not game_over:
			_trigger_phase2_win()
	else:
		# Phase 1 Win Condition: No humans and no police
		if humans - police <= 0 and police <= 0 and not game_over:
			_trigger_phase1_win()

func _unhandled_input(event):
	# Debug: Press 'P' to instantly win the current phase
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:
			var scene_name = get_tree().current_scene.scene_file_path
			if "phase-2-main" in scene_name:
				_trigger_phase2_win()
			else:
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

func _trigger_phase2_win():
	if _win_triggered:
		return
	_win_triggered = true
	var overlay = PHASE2_WIN_OVERLAY_SCENE.instantiate()
	add_child(overlay)

func _on_player_caught(zombie, player):
	if game_over:
		return
	game_over = true
	
	# 1 - Pause all characters
	get_tree().call_group("humans", "set_physics_process", false)
	get_tree().call_group("police", "set_physics_process", false)
	get_tree().call_group("zombies", "set_physics_process", false)
	player.set_physics_process(false)
	
	# 2 - Tween the camera
	var camera = player.get_node("Camera2D")
	var tween = get_tree().create_tween()
	var target_pos = (zombie.global_position + player.global_position) / 2
	
	tween.tween_property(camera, "global_position", target_pos, 1.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "zoom", Vector2(1.5, 1.5), 1.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# 3 - Display the game over screen
	var game_over_screen = GAME_OVER_SCENE.instantiate()
	add_child(game_over_screen)
	
	# 4 - Wait and restart
	await get_tree().create_timer(5.0).timeout
	get_tree().reload_current_scene()
