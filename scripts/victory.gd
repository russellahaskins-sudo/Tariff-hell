extends Control

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel

func _ready() -> void:
	score_label.text = "FINAL SCORE: %d" % GameManager.score

func _on_retry_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
