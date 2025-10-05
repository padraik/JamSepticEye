extends Control

@onready var humans_label = $HudPanel/HBoxContainer/HumansLabel
@onready var zombies_label = $HudPanel/HBoxContainer/ZombiesLabel
@onready var police_label = $HudPanel/HBoxContainer/PoliceLabel

func update_counts(humans, zombies, police):
	humans_label.text = "Humans: " + str(humans)
	zombies_label.text = "Zombies: " + str(zombies)
	police_label.text = "Police Officers: " + str(police)
