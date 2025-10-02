extends Node

signal sound_emitted(sound_position, sound_radius)

func emit_sound(position, radius):
	emit_signal("sound_emitted", position, radius)
