extends Node2D

@onready var idle_sprite = $Idle
@onready var search_sprite = $Search
@onready var chase_sprite = $Chase
@onready var down_sprite = $Down

var sprites

func _ready():
	# This maps the integer value of the Zombie's state enum to the correct sprite
	sprites = {
		0: idle_sprite, # IDLE
		1: search_sprite, # SEARCHING
		2: chase_sprite, # CHASING
		3: down_sprite # DOWN
	}

func update_animation(state):
	for s in sprites.values():
		s.visible = false
	
	if sprites.has(state):
		print("Animator: Setting state to ", state, ". Showing sprite: ", sprites[state].name)
		sprites[state].visible = true
	else:
		print("Animator: Unknown state received: ", state)
