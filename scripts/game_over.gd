extends Control

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var high_score_label: Label = $CenterContainer/VBoxContainer/HighScoreLabel

func _ready() -> void:
	score_label.text = "SCORE: %d" % GameManager.score
	high_score_label.text = "HIGH SCORE: %d" % GameManager.high_score

func _on_retry_button_pressed() -> void:
	if GameManager.max_lives >= 5:
		# Easy mode - checkpoint at current level
		pass
	else:
		GameManager.current_level = 0
		GameManager.score = 0
	GameManager.lives = GameManager.max_lives
	get_tree().change_scene_to_file("res://scenes/map_screen.tscn")

func _on_menu_button_pressed() -> void:
	GameManager.current_level = 0
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
