@tool
extends Node

const HUMAN_SCENE_PATH = "res://scenes/human.tscn"
const POLICE_SCENE_PATH = "res://scenes/police_officer.tscn"
const ZOMBIE_SCENE_PATH = "res://scenes/zombie.tscn"
const TARGET_SCENE_PATH = "res://scenes/phase-2-main.tscn"

@export var run_conversion_now: bool = false:
	set(value):
		if value:
			_convert_npcs()
			call_deferred("set", "run_conversion_now", false)

func _find_node_recursively(node, node_name):
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found = _find_node_recursively(child, node_name)
		if found:
			return found
	return null

func _print_tree(node, depth):
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent + node.name)
	for child in node.get_children():
		_print_tree(child, depth + 1)

func _convert_npcs():
	print("Starting NPC to Zombie conversion...")

	var zombie_scene = load(ZOMBIE_SCENE_PATH)
	if not zombie_scene:
		printerr("Could not load Zombie scene at path: ", ZOMBIE_SCENE_PATH)
		return

	var target_scene = load(TARGET_SCENE_PATH)
	if not target_scene:
		printerr("Could not load target scene at path: ", TARGET_SCENE_PATH)
		return

	var scene_instance = target_scene.instantiate()
	
	print("--- Instantiated Scene Structure ---")
	_print_tree(scene_instance, 0)
	print("------------------------------------")

	var npcs_node = _find_node_recursively(scene_instance, "NPCS")
	
	if not npcs_node:
		printerr("ERROR: Could not find a node named 'NPCS' anywhere in the scene.")
		scene_instance.free()
		return

	var nodes_to_replace = []
	for child in npcs_node.get_children():
		if child.scene_file_path == HUMAN_SCENE_PATH or child.scene_file_path == POLICE_SCENE_PATH:
			nodes_to_replace.append(child)

	if nodes_to_replace.is_empty():
		print("No Humans or Police Officers found to replace in the 'NPCS' node.")
		scene_instance.free()
		return

	print("Found ", nodes_to_replace.size(), " NPCs to replace.")

	for old_npc in nodes_to_replace:
		var old_position = old_npc.position
		var old_name = old_npc.name
		
		var new_zombie = zombie_scene.instantiate()
		new_zombie.position = old_position
		new_zombie.name = old_name.replace("Human", "Zombie").replace("PoliceOfficer", "Zombie")

		npcs_node.remove_child(old_npc)
		npcs_node.add_child(new_zombie)
		new_zombie.owner = scene_instance
		old_npc.queue_free()

	print("Conversion complete. Saving modified scene...")
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(scene_instance)
	
	scene_instance.free()

	if result == OK:
		result = ResourceSaver.save(packed_scene, TARGET_SCENE_PATH)
		if result == OK:
			print("Successfully saved modified scene to: ", TARGET_SCENE_PATH)
		else:
			printerr("Failed to save the scene. Error code: ", result)
	else:
		printerr("Failed to pack the scene. Error code: ", result)

	print("Script finished.")
