extends Node2D

@export var bullet_scene: PackedScene
var spawn_timer: Timer
var player: Node2D = null

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start(GameManager.get_spawn_interval())

func set_player(p: Node2D) -> void:
	player = p

func _process(_delta: float) -> void:
	if GameManager.is_game_active:
		spawn_timer.wait_time = GameManager.get_spawn_interval()

func _on_spawn_timer_timeout() -> void:
	if not GameManager.is_game_active:
		return
	if GameManager.score >= GameManager.get_boss_threshold():
		return

	var bullet_type := _pick_bullet_type()
	_spawn_bullet(bullet_type)

	# At higher difficulty, spawn clusters
	if GameManager.difficulty > 2.5 and randf() < 0.3:
		_spawn_bullet(_pick_bullet_type())
	if GameManager.difficulty > 4.0 and randf() < 0.2:
		_spawn_bullet(_pick_bullet_type())

func _pick_bullet_type() -> int:
	var roll := randf()
	var paper_chance := clampf(0.1 + GameManager.difficulty * 0.05, 0.0, 0.35)
	var form_chance := clampf((GameManager.difficulty - 2.0) * 0.05, 0.0, 0.2)

	if roll < form_chance:
		return 2  # CUSTOMS_FORM
	elif roll < form_chance + paper_chance:
		return 1  # TARIFF_PAPER
	else:
		return 0  # TAX_STAMP

func _spawn_bullet(type: int) -> void:
	if not bullet_scene:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	var vp_width := get_viewport_rect().size.x
	bullet.position = Vector2(randf_range(16.0, vp_width - 16.0), -10.0)
	bullet.setup(type, GameManager.get_bullet_speed(), player)
	get_parent().add_child(bullet)
