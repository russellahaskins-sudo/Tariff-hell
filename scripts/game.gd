extends Node2D

@onready var player: Area2D = $Player
@onready var spawner: Node2D = $Spawner
@onready var difficulty_timer: Timer = $DifficultyTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var delivery_timer: Timer = $DeliveryTimer

var coastline_spawned := false
var coastline_scene: PackedScene = preload("res://scenes/coastline.tscn")
var boss: Node2D = null
var boss_spawned := false

func _ready() -> void:
	GameManager.reset()
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.victory_triggered.connect(_on_victory)
	GameManager.boss_phase_started.connect(_on_boss_phase)
	spawner.set_player(player)

	difficulty_timer.timeout.connect(_on_difficulty_tick)
	difficulty_timer.start(10.0)

	score_timer.timeout.connect(_on_score_tick)
	score_timer.start(1.0)

	delivery_timer.timeout.connect(_on_delivery_tick)
	delivery_timer.start(15.0)

func _process(_delta: float) -> void:
	if not coastline_spawned and GameManager.score >= GameManager.get_boss_threshold():
		_spawn_coastline()

	# Check cargo box -> boss collisions
	if boss and is_instance_valid(boss):
		_check_boss_hits()

func _check_boss_hits() -> void:
	if boss.get("dying"):
		return
	var hit_size: Vector2 = boss.get("hit_size") if boss.get("hit_size") else Vector2(48, 40)
	var boss_rect := Rect2(boss.position - hit_size * 0.5, hit_size)
	for child in get_children():
		if child.get_script() == preload("res://scripts/cargo_box.gd"):
			if boss_rect.has_point(child.position):
				boss.take_damage(child.DAMAGE)
				child.queue_free()

func _spawn_coastline() -> void:
	coastline_spawned = true
	var coast := coastline_scene.instantiate()
	coast.position = Vector2(0, 0)
	add_child(coast)

func _on_boss_phase() -> void:
	if boss_spawned:
		return
	boss_spawned = true

	# Remove the coastline
	for child in get_children():
		if child.get_script() == preload("res://scripts/coastline.gd"):
			child.queue_free()

	# Stop normal timers
	difficulty_timer.stop()
	score_timer.stop()
	delivery_timer.stop()

	# Spawn boss based on current level
	var boss_script: GDScript
	var boss_name: String
	match GameManager.current_level:
		0:  # Pacific area
			boss_script = preload("res://scripts/ice_boss.gd")
			boss_name = "ICE AGENT"
		1:  # Around Hawaii
			boss_script = preload("res://scripts/border_wall_boss.gd")
			boss_name = "BORDER WALL"
		2:  # America - final boss
			boss_script = preload("res://scripts/trump_boss.gd")
			boss_name = "THE PRESIDENT"
		_:
			boss_script = preload("res://scripts/ice_boss.gd")
			boss_name = "ICE AGENT"

	boss = Node2D.new()
	boss.set_script(boss_script)
	add_child(boss)
	boss.setup(player, preload("res://scenes/bullets/tariff_bullet.tscn"))
	boss.defeated.connect(_on_boss_defeated)
	boss.health_changed.connect(_on_boss_health_changed)

	# Tell HUD to show boss bar
	$HUD.show_boss_bar(boss.max_health, boss_name)

func _on_boss_health_changed(hp: int) -> void:
	$HUD.update_boss_bar(hp)

func _on_boss_defeated() -> void:
	boss = null
	GameManager.trigger_victory()

func _on_difficulty_tick() -> void:
	GameManager.increase_difficulty()

func _on_score_tick() -> void:
	if GameManager.is_game_active:
		GameManager.add_score(int(GameManager.difficulty))

func _on_delivery_tick() -> void:
	if GameManager.is_game_active:
		GameManager.add_delivery()

func _on_game_over() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _on_victory() -> void:
	await get_tree().create_timer(0.3).timeout
	GameManager.current_level += 1  # advance before showing map
	get_tree().change_scene_to_file("res://scenes/map_screen.tscn")
