extends Node

signal score_changed(new_score: int)
signal game_over_triggered
signal victory_triggered
signal boss_phase_started
signal boss_defeated
signal lives_changed(lives: int)

var score: int = 0
var high_score: int = 0
var difficulty: float = 1.0
var is_game_active: bool = false
var deliveries: int = 0
var boss_phase: bool = false
var can_shoot: bool = false
var current_level: int = 0
var lives: int = 3
var max_lives: int = 3  # set by difficulty

func _ready() -> void:
	load_high_score()

func reset() -> void:
	# Score persists across levels - record starting score for threshold
	level_start_score = score
	# Start difficulty higher each level
	difficulty = 1.0 + current_level * 0.5
	is_game_active = true
	# Don't reset lives here - they persist across levels
	boss_phase = false
	can_shoot = false

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func add_delivery() -> void:
	deliveries += 1
	add_score(25)

var level_start_score: int = 0

func get_boss_threshold() -> int:
	return level_start_score + 100

func increase_difficulty() -> void:
	difficulty += 0.15 + current_level * 0.05

func get_spawn_interval() -> float:
	return maxf(0.15, 0.8 / difficulty)

func get_bullet_speed() -> float:
	return 60.0 + (difficulty * 15.0)

func start_boss_phase() -> void:
	boss_phase = true
	boss_phase_started.emit()

func enable_shooting() -> void:
	can_shoot = true

func trigger_game_over() -> void:
	if not is_game_active:
		return
	is_game_active = false
	if score > high_score:
		high_score = score
		save_high_score()
	game_over_triggered.emit()

func trigger_victory() -> void:
	if not is_game_active:
		return
	is_game_active = false
	if score > high_score:
		high_score = score
		save_high_score()
	victory_triggered.emit()

func save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "high_score", high_score)
	config.save("user://highscore.cfg")

func load_high_score() -> void:
	var config := ConfigFile.new()
	if config.load("user://highscore.cfg") == OK:
		high_score = config.get_value("game", "high_score", 0)
