extends Control

@onready var humans_label = $VBoxContainer/HumansLabel
@onready var zombies_label = $VBoxContainer/ZombiesLabel
@onready var police_label = $VBoxContainer/PoliceLabel

func update_counts(humans, zombies, police):
	humans_label.text = "Humans: " + str(humans)
	zombies_label.text = "Zombies: " + str(zombies)
	police_label.text = "Police Officers: " + str(police)
