extends CanvasLayer

@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var difficulty_label: Label = $MarginContainer/VBoxContainer/DifficultyLabel
@onready var go_label: Label = $GoLabel
@onready var boss_bar_bg: ColorRect = $BossBarBG
@onready var boss_bar: ColorRect = $BossBar
@onready var boss_label: Label = $BossLabel
@onready var shoot_label: Label = $ShootLabel

var showing_go := false
var boss_max_hp: int = 100
var showing_shoot := false
var heart_sprites: Array[Sprite2D] = []

func _ready() -> void:
	_create_hearts()
	GameManager.lives_changed.connect(_on_lives_changed)

func _create_hearts() -> void:
	var heart_img := Image.create(9, 8, false, Image.FORMAT_RGBA8)
	var red := Color(0.9, 0.15, 0.2)
	var red_light := Color(1.0, 0.35, 0.4)
	# Heart shape
	# Row 0:  _##_##_
	for x in [1, 2, 4, 5]:
		heart_img.set_pixel(x + 1, 0, red)
	# Row 1: #####
	for x in range(1, 8):
		heart_img.set_pixel(x, 1, red)
	heart_img.set_pixel(2, 1, red_light)
	# Row 2-3: full width
	for y in range(2, 4):
		for x in range(0, 9):
			heart_img.set_pixel(x, y, red)
	heart_img.set_pixel(1, 2, red_light)
	# Row 4: narrower
	for x in range(1, 8):
		heart_img.set_pixel(x, 4, red)
	# Row 5: narrower
	for x in range(2, 7):
		heart_img.set_pixel(x, 5, red)
	# Row 6:
	for x in range(3, 6):
		heart_img.set_pixel(x, 6, red)
	# Row 7: tip
	heart_img.set_pixel(4, 7, red)

	var heart_tex := ImageTexture.create_from_image(heart_img)

	for i in range(GameManager.max_lives):
		var sprite := Sprite2D.new()
		sprite.texture = heart_tex
		sprite.position = Vector2(308 - i * 14, 12)
		add_child(sprite)
		heart_sprites.append(sprite)

func _on_lives_changed(lives: int) -> void:
	for i in range(heart_sprites.size()):
		heart_sprites[i].modulate.a = 1.0 if i < lives else 0.2

func _process(_delta: float) -> void:
	score_label.text = "SCORE: %d" % GameManager.score
	difficulty_label.text = "TRADE WAR LV. %d" % (GameManager.current_level + 1)

	if not showing_go and GameManager.score >= GameManager.get_boss_threshold():
		showing_go = true
		_show_go_message()

	if not showing_shoot and GameManager.can_shoot:
		showing_shoot = true
		_show_shoot_message()

func _show_go_message() -> void:
	go_label.visible = true
	for i in range(5):
		go_label.modulate.a = 1.0
		await get_tree().create_timer(0.4).timeout
		go_label.modulate.a = 0.3
		await get_tree().create_timer(0.2).timeout
	go_label.modulate.a = 1.0

func _show_shoot_message() -> void:
	shoot_label.visible = true
	for i in range(5):
		shoot_label.modulate.a = 1.0
		await get_tree().create_timer(0.4).timeout
		shoot_label.modulate.a = 0.3
		await get_tree().create_timer(0.2).timeout
	shoot_label.modulate.a = 1.0

var boss_name_str: String = "BOSS"

func show_boss_bar(max_hp: int, boss_name: String = "BOSS") -> void:
	boss_max_hp = max_hp
	boss_name_str = boss_name
	boss_bar_bg.visible = true
	boss_bar.visible = true
	boss_label.visible = true
	go_label.visible = false
	update_boss_bar(max_hp)

func update_boss_bar(hp: int) -> void:
	var ratio: float = float(maxi(hp, 0)) / float(boss_max_hp)
	boss_bar.size.x = 200.0 * ratio
	boss_label.text = "%s  %d/%d" % [boss_name_str, maxi(hp, 0), boss_max_hp]
