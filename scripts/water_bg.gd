extends ColorRect

var scroll_offset: float = 0.0
var wave_lines: Array[float] = []

func _ready() -> void:
	# Pre-generate some wave line positions
	for i in range(20):
		wave_lines.append(randf() * size.y)

func _process(delta: float) -> void:
	scroll_offset += 30.0 * delta
	if scroll_offset > 24.0:
		scroll_offset -= 24.0
	queue_redraw()

func _draw() -> void:
	# Draw subtle wave lines scrolling down
	var wave_color := Color(0.1, 0.12, 0.2, 0.3)
	for i in range(wave_lines.size()):
		var y_pos := fmod(wave_lines[i] + scroll_offset * (1.0 + i * 0.1), size.y)
		var x_offset := sin(y_pos * 0.05 + scroll_offset) * 10.0
		draw_line(
			Vector2(x_offset, y_pos),
			Vector2(size.x + x_offset, y_pos),
			wave_color,
			1.0
		)
