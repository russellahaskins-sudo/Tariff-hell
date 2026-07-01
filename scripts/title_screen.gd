extends Control

func _start_game(max_lives_val: int) -> void:
	GameManager.current_level = 0
	GameManager.max_lives = max_lives_val
	GameManager.lives = max_lives_val
	GameManager.score = 0
	get_tree().change_scene_to_file("res://scenes/map_screen.tscn")

func _on_easy_button_pressed() -> void:
	_start_game(5)

func _on_normal_button_pressed() -> void:
	_start_game(3)

func _on_hard_button_pressed() -> void:
	_start_game(1)
