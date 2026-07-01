extends Control

@onready var score_label: Label = $UI/ScoreLabel

var ship_dot_pos := Vector2.ZERO
var route_points: Array[Vector2] = []
var draw_progress: float = 0.0
var drawing_route := true
var ship_arrived := false

const MAP_W := 320
const MAP_H := 480

# Ports
var shanghai_port := Vector2(10, 150)
var la_port := Vector2(270, 120)

# Waypoint stops along the route (t values 0-1 along the route)
# 3 stops + final destination = 4 segments
var stop_t_values: Array[float] = [0.33, 0.66, 1.0]
var stop_positions: Array[Vector2] = []
var target_t: float = 0.0
var start_t: float = 0.0

func _ready() -> void:
	score_label.text = "FINAL SCORE: %d" % GameManager.score
	_build_route()
	# Compute stop positions along route
	for st in stop_t_values:
		var idx: int = int(st * (route_points.size() - 1))
		stop_positions.append(route_points[idx])

	var level: int = GameManager.current_level
	# Animate from current position to next stop
	if level > 0:
		start_t = stop_t_values[level - 1]
	else:
		start_t = 0.0
	target_t = stop_t_values[mini(level, stop_t_values.size() - 1)]
	draw_progress = start_t
	var start_idx: int = int(start_t * (route_points.size() - 1))
	ship_dot_pos = route_points[start_idx]

func _build_route() -> void:
	var num_points := 80
	for i in range(num_points + 1):
		var t: float = float(i) / float(num_points)
		var x: float = lerpf(shanghai_port.x, la_port.x, t)
		# Great circle arc - peaks north around the middle of the Pacific
		var arc: float = sin(t * PI) * -55.0
		var y: float = lerpf(shanghai_port.y, la_port.y, t) + arc
		# Wiggly path - multiple frequencies
		y += sin(t * PI * 5.0) * 8.0
		y += sin(t * PI * 11.0) * 3.0
		x += sin(t * PI * 4.0) * 10.0
		x += sin(t * PI * 9.0) * 4.0
		route_points.append(Vector2(x, y))

func _process(delta: float) -> void:
	if drawing_route:
		draw_progress += delta * 0.35
		if draw_progress >= target_t:
			draw_progress = target_t
			drawing_route = false
			ship_arrived = true
		var idx: int = int(draw_progress * (route_points.size() - 1))
		ship_dot_pos = route_points[idx]
	queue_redraw()

func _draw() -> void:
	# Ocean - same as in-game water
	var ocean := Color(0.05, 0.08, 0.18)
	draw_rect(Rect2(0, 0, MAP_W, MAP_H), ocean)

	# Subtle depth variation
	for y_band in range(0, MAP_H, 40):
		var depth_alpha: float = 0.02 + sin(y_band * 0.04) * 0.015
		draw_rect(Rect2(0, y_band, MAP_W, 20), Color(0.05, 0.08, 0.15, depth_alpha))

	# Draw landmasses from Natural Earth data
	_draw_all_land()

	# Route line
	var draw_count: int = int(draw_progress * (route_points.size() - 1))
	if draw_count >= 2:
		for i in range(draw_count - 1):
			# Dashed: draw 3, skip 1
			if i % 4 < 3:
				draw_line(route_points[i], route_points[i + 1], Color(0.2, 0.45, 0.85, 0.8), 1.0)

	# Port dots
	_draw_port(shanghai_port, Color(0.85, 0.2, 0.2))
	_draw_port(la_port, Color(0.2, 0.3, 0.85))

	# Waypoint stops
	for i in range(stop_positions.size()):
		var spos: Vector2 = stop_positions[i]
		draw_circle(spos, 3.0, Color(0.9, 0.7, 0.2))
		draw_circle(spos, 1.5, Color(1, 1, 1, 0.8))
		pass

	# Ship dot with glow
	draw_circle(ship_dot_pos, 5.0, Color(0.2, 0.85, 0.3, 0.3))
	draw_circle(ship_dot_pos, 3.0, Color(0.2, 0.9, 0.3))
	draw_circle(ship_dot_pos, 1.5, Color(0.6, 1.0, 0.7))

	# Labels - countries only

	# Country labels on land
	draw_string(ThemeDB.fallback_font, Vector2(4, 130), "China", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7, 0.7, 0.65, 0.7))
	draw_string(ThemeDB.fallback_font, Vector2(265, 100), "USA", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7, 0.7, 0.65, 0.7))

func _draw_port(pos: Vector2, col: Color) -> void:
	draw_circle(pos, 3.0, col)
	draw_circle(pos, 1.5, Color(1, 1, 1, 0.8))

var land := Color(0.9, 0.89, 0.84)
var land_alt := Color(0.85, 0.83, 0.77)
var land_green := Color(0.78, 0.83, 0.72)
var coast_line := Color(0.12, 0.18, 0.3)

const X_SHIFT := -40.0

func _draw_land(points: PackedVector2Array, col: Color) -> void:
	if points.size() < 3:
		return
	# Shift all points left to show more of Americas
	var shifted: PackedVector2Array = []
	for p in points:
		shifted.append(Vector2(p.x + X_SHIFT, p.y))
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(shifted)
	if indices.size() > 0:
		draw_colored_polygon(shifted, col)
	for i in range(shifted.size()):
		var next_i: int = (i + 1) % shifted.size()
		draw_line(shifted[i], shifted[next_i], coast_line, 1.0)

func _draw_all_land() -> void:
	_draw_land([Vector2(107.5, 461.1), Vector2(112.4, 461.2), Vector2(113.8, 466.8), Vector2(112.9, 472.0), Vector2(108.9, 473.5), Vector2(107.6, 469.7), Vector2(106.1, 462.8)] as PackedVector2Array, land_green)
	_draw_land([Vector2(166.4, 461.7), Vector2(169.1, 465.5), Vector2(166.9, 470.9), Vector2(166.6, 474.9), Vector2(163.1, 476.6), Vector2(161.3, 480), Vector2(156.4, 476.1), Vector2(159.3, 473.5), Vector2(162.4, 468.8), Vector2(164.2, 464.4), Vector2(166.0, 459.8)] as PackedVector2Array, land_green)
	_draw_land([Vector2(169.8, 440.3), Vector2(171.4, 445.1), Vector2(174.4, 448.1), Vector2(178.2, 447.2), Vector2(177.7, 451.2), Vector2(174.8, 455.1), Vector2(173.9, 460.3), Vector2(171.2, 465.1), Vector2(171.2, 459.6), Vector2(168.2, 455.4), Vector2(169.8, 452.2), Vector2(170.1, 448.7), Vector2(169.2, 442.8), Vector2(166.5, 436.2), Vector2(166.4, 432.7), Vector2(169.2, 436.3), Vector2(169.8, 440.3)] as PackedVector2Array, land_green)
	_draw_land([Vector2(153.9, 377.5), Vector2(150.3, 375.4), Vector2(147.6, 369.8), Vector2(151.0, 372.7), Vector2(153.9, 377.5)] as PackedVector2Array, land_green)
	_draw_land([Vector2(177.9, 355.9), Vector2(178.2, 359.6), Vector2(176.4, 356.1)] as PackedVector2Array, land_green)
	_draw_land([Vector2(103.6, 339.9), Vector2(104.4, 343.4), Vector2(107.5, 345.4), Vector2(107.7, 351.2), Vector2(109.1, 357.8), Vector2(109.6, 363.2), Vector2(113.4, 367.7), Vector2(115.8, 373.5), Vector2(116.6, 378.4), Vector2(119.3, 383.4), Vector2(121.8, 387.8), Vector2(123.4, 391.5), Vector2(124.0, 395.1), Vector2(123.9, 400.4), Vector2(124.9, 404.2), Vector2(124.8, 408.2), Vector2(123.9, 414.3), Vector2(123.5, 420.1), Vector2(122.6, 424.1), Vector2(120.2, 429.8), Vector2(118.9, 435.9), Vector2(117.5, 441.5), Vector2(117.3, 446.0), Vector2(113.7, 447.7), Vector2(110.8, 451.3), Vector2(106.4, 450.5), Vector2(101.9, 451.0), Vector2(97.4, 448.7), Vector2(95.6, 442.5), Vector2(94.0, 438.4), Vector2(92.2, 432.4), Vector2(89.2, 436.3), Vector2(90.7, 431.2), Vector2(91.3, 425.7), Vector2(89.6, 429.5), Vector2(87.4, 434.6), Vector2(85.8, 430.4), Vector2(83.4, 425.5), Vector2(81.0, 421.7), Vector2(77.5, 419.4), Vector2(73.7, 419.8), Vector2(68.5, 422.9), Vector2(64.2, 425.0), Vector2(61.9, 428.3), Vector2(58.0, 430.7), Vector2(53.1, 430.5), Vector2(50.1, 434.0), Vector2(46.1, 435.3), Vector2(43.9, 432.4), Vector2(42.8, 429.0), Vector2(44.1, 425.7), Vector2(44.1, 419.9), Vector2(43.0, 415.4), Vector2(42.8, 410.3), Vector2(41.8, 406.1), Vector2(40.6, 400.8), Vector2(39.4, 397.2), Vector2(39.3, 393.1), Vector2(39.7, 388.9), Vector2(39.5, 384.9), Vector2(40.0, 379.0), Vector2(43.6, 374.6), Vector2(46.3, 371.0), Vector2(49.6, 369.5), Vector2(52.9, 367.7), Vector2(56.3, 364.4), Vector2(58.1, 359.8), Vector2(58.3, 355.5), Vector2(59.8, 351.7), Vector2(60.7, 355.6), Vector2(61.5, 350.4), Vector2(63.8, 345.8), Vector2(65.5, 342.0), Vector2(70.0, 342.2), Vector2(72.5, 344.9), Vector2(74.4, 339.2), Vector2(76.0, 334.4), Vector2(80.2, 332.5), Vector2(78.6, 328.7), Vector2(82.2, 331.0), Vector2(86.0, 333.1), Vector2(89.5, 333.5), Vector2(88.1, 337.8), Vector2(87.0, 341.9), Vector2(86.4, 345.4), Vector2(89.7, 349.3), Vector2(92.4, 353.5), Vector2(96.5, 357.6), Vector2(98.3, 353.6), Vector2(99.0, 349.2), Vector2(99.6, 345.6), Vector2(99.5, 342.1), Vector2(99.5, 336.2), Vector2(100.1, 331.4), Vector2(100.6, 327.7), Vector2(102.1, 331.0), Vector2(103.5, 335.7), Vector2(103.6, 339.9)] as PackedVector2Array, land_green)
	_draw_land([Vector2(62.8, 323.6), Vector2(61.8, 319.8), Vector2(64.2, 317.0), Vector2(67.5, 315.8), Vector2(66.0, 319.0), Vector2(62.8, 323.6)] as PackedVector2Array, land_green)
	_draw_land([Vector2(48.9, 314.4), Vector2(51.5, 317.2), Vector2(47.5, 318.7), Vector2(48.9, 314.4)] as PackedVector2Array, land_green)
	_draw_land([Vector2(59.5, 314.4), Vector2(56.0, 318.2), Vector2(53.2, 316.0), Vector2(57.6, 316.1)] as PackedVector2Array, land_green)
	_draw_land([Vector2(29.1, 308.5), Vector2(33.2, 309.0), Vector2(37.6, 309.3), Vector2(41.6, 313.0), Vector2(44.2, 315.7), Vector2(39.4, 315.6), Vector2(35.2, 315.4), Vector2(30.8, 312.9), Vector2(24.4, 311.1), Vector2(23.6, 304.6), Vector2(27.9, 306.6)] as PackedVector2Array, land)
	_draw_land([Vector2(129.9, 308.7), Vector2(127.4, 304.6), Vector2(127.3, 300.8), Vector2(129.2, 305.9)] as PackedVector2Array, land_green)
	_draw_land([Vector2(121.6, 302.7), Vector2(118.9, 305.4), Vector2(115.0, 305.2), Vector2(117.3, 300.7), Vector2(120.8, 299.5)] as PackedVector2Array, land_green)
	_draw_land([Vector2(124.0, 298.3), Vector2(122.5, 295.1), Vector2(120.3, 291.7), Vector2(123.0, 294.5), Vector2(124.0, 298.3)] as PackedVector2Array, land_green)
	_draw_land([Vector2(83.5, 283.3), Vector2(84.1, 290.6), Vector2(88.1, 288.5), Vector2(90.5, 285.8), Vector2(94.3, 287.3), Vector2(98.1, 289.8), Vector2(101.8, 292.9), Vector2(105.8, 295.5), Vector2(108.4, 300.0), Vector2(112.3, 305.4), Vector2(111.3, 311.3), Vector2(114.6, 319.0), Vector2(117.4, 321.6), Vector2(118.8, 325.6), Vector2(115.0, 324.3), Vector2(111.2, 320.7), Vector2(108.9, 314.3), Vector2(104.3, 313.6), Vector2(103.3, 318.4), Vector2(98.2, 319.0), Vector2(96.3, 315.4), Vector2(90.9, 315.9), Vector2(91.8, 312.2), Vector2(92.6, 306.1), Vector2(91.6, 302.3), Vector2(87.4, 298.5), Vector2(82.5, 294.0), Vector2(78.9, 290.8), Vector2(82.7, 289.3), Vector2(79.4, 288.1), Vector2(76.7, 284.6), Vector2(78.7, 281.3), Vector2(83.2, 281.6)] as PackedVector2Array, land_green)
	_draw_land([Vector2(64.5, 271.8), Vector2(62.8, 276.2), Vector2(59.1, 276.2), Vector2(55.6, 276.4), Vector2(53.4, 280.5), Vector2(55.3, 284.5), Vector2(60.5, 280.9), Vector2(58.4, 284.9), Vector2(58.6, 292.4), Vector2(60.1, 299.1), Vector2(58.9, 303.4), Vector2(59.1, 298.2), Vector2(55.2, 294.3), Vector2(55.4, 289.9), Vector2(54.2, 296.5), Vector2(54.3, 302.9), Vector2(52.6, 298.1), Vector2(52.3, 293.8), Vector2(51.6, 287.8), Vector2(51.9, 284.2), Vector2(53.0, 277.4), Vector2(55.2, 272.3), Vector2(59.6, 274.2), Vector2(64.1, 270.8)] as PackedVector2Array, land)
	_draw_land([Vector2(71.9, 273.1), Vector2(71.8, 277.0), Vector2(71.2, 281.6), Vector2(69.1, 273.6), Vector2(69.5, 270.0), Vector2(71.9, 273.1)] as PackedVector2Array, land_green)
	_draw_land([Vector2(23.1, 304.4), Vector2(18.9, 300.7), Vector2(16.2, 297.1), Vector2(13.7, 290.7), Vector2(12.6, 287.3), Vector2(11.0, 281.0), Vector2(9.1, 277.3), Vector2(8.5, 273.5), Vector2(7.7, 270.0), Vector2(4.6, 263.3), Vector2(0.8, 255.8), Vector2(5.3, 254.6), Vector2(7.2, 259.0), Vector2(10.0, 263.9), Vector2(12.0, 268.7), Vector2(16.0, 271.9), Vector2(17.2, 275.6), Vector2(18.0, 281.3), Vector2(20.4, 286.1), Vector2(22.7, 289.0), Vector2(23.2, 297.4), Vector2(23.1, 304.4)] as PackedVector2Array, land)
	_draw_land([Vector2(48.8, 269.9), Vector2(51.2, 274.1), Vector2(48.0, 277.7), Vector2(48.0, 281.7), Vector2(46.0, 284.8), Vector2(45.9, 289.3), Vector2(45.1, 296.1), Vector2(41.5, 293.8), Vector2(36.4, 293.7), Vector2(32.5, 291.3), Vector2(32.2, 285.3), Vector2(30.1, 280.2), Vector2(29.8, 276.3), Vector2(30.0, 272.1), Vector2(34.5, 269.8), Vector2(34.9, 266.0), Vector2(38.4, 264.2), Vector2(39.9, 260.7), Vector2(41.8, 256.1), Vector2(45.3, 250.6), Vector2(46.3, 247.1), Vector2(48.4, 251.3), Vector2(51.6, 253.9), Vector2(50.4, 258.0), Vector2(47.6, 263.6), Vector2(49.2, 267.9)] as PackedVector2Array, land)
	_draw_land([Vector2(66.9, 240.4), Vector2(67.3, 245.9), Vector2(66.6, 250.0), Vector2(65.8, 245.4), Vector2(65.5, 251.0), Vector2(61.7, 247.2), Vector2(61.0, 243.0), Vector2(57.8, 247.2), Vector2(58.3, 242.1), Vector2(60.8, 239.1), Vector2(65.0, 237.8), Vector2(64.9, 234.3), Vector2(66.8, 238.7)] as PackedVector2Array, land_green)
	_draw_land([Vector2(61.8, 232.0), Vector2(60.4, 236.3), Vector2(59.4, 232.1), Vector2(62.0, 227.7), Vector2(61.8, 232.0)] as PackedVector2Array, land_green)
	_draw_land([Vector2(50.1, 236.3), Vector2(47.3, 240.6), Vector2(49.9, 234.7), Vector2(52.3, 227.1), Vector2(52.7, 230.8), Vector2(50.1, 236.3)] as PackedVector2Array, land_green)
	_draw_land([Vector2(56.2, 195.1), Vector2(58.0, 198.2), Vector2(58.1, 205.2), Vector2(56.5, 210.3), Vector2(57.0, 213.9), Vector2(61.8, 216.3), Vector2(62.3, 219.8), Vector2(59.6, 217.3), Vector2(55.7, 217.0), Vector2(55.4, 213.0), Vector2(53.2, 209.0), Vector2(53.1, 204.7), Vector2(54.2, 199.2), Vector2(54.9, 195.1)] as PackedVector2Array, land)
	_draw_land([Vector2(32.7, 194.3), Vector2(29.1, 195.1), Vector2(29.1, 191.2), Vector2(32.5, 188.0), Vector2(33.2, 191.7)] as PackedVector2Array, land_green)
	_draw_land([Vector2(233.5, 192.5), Vector2(232.9, 188.5), Vector2(234.2, 191.8)] as PackedVector2Array, land_green)
	_draw_land([Vector2(55.8, 175.9), Vector2(54.9, 179.6), Vector2(53.8, 175.8), Vector2(54.8, 168.1), Vector2(56.5, 164.7), Vector2(57.1, 168.7), Vector2(55.8, 175.9)] as PackedVector2Array, land_green)
	_draw_land([Vector2(84.6, 124.9), Vector2(83.6, 129.2), Vector2(79.7, 130.1), Vector2(80.9, 125.3), Vector2(84.6, 124.9)] as PackedVector2Array, land_green)
	_draw_land([Vector2(98.1, 111.5), Vector2(97.3, 115.1), Vector2(96.5, 120.5), Vector2(90.1, 122.9), Vector2(87.0, 128.0), Vector2(85.5, 122.9), Vector2(81.8, 123.9), Vector2(76.8, 126.1), Vector2(78.9, 129.4), Vector2(77.5, 137.0), Vector2(75.6, 133.1), Vector2(73.4, 128.8), Vector2(76.5, 124.6), Vector2(80.3, 119.2), Vector2(84.5, 117.8), Vector2(89.0, 110.8), Vector2(93.6, 108.4), Vector2(96.1, 101.2), Vector2(95.8, 96.2), Vector2(98.9, 92.5), Vector2(100.1, 98.7), Vector2(100.0, 102.4), Vector2(98.0, 106.9), Vector2(98.1, 111.5)] as PackedVector2Array, land_green)
	_draw_land([Vector2(104.3, 80.0), Vector2(107.8, 84.1), Vector2(102.8, 89.7), Vector2(99.4, 86.7), Vector2(98.3, 91.6), Vector2(95.6, 87.2), Vector2(96.7, 83.7), Vector2(99.6, 77.3), Vector2(100.2, 73.8), Vector2(102.7, 78.5)] as PackedVector2Array, land_green)
	_draw_land([Vector2(301.8, 60.5), Vector2(297.3, 59.1), Vector2(294.7, 55.9), Vector2(291.3, 51.4), Vector2(295.1, 52.0), Vector2(298.8, 56.2), Vector2(301.8, 60.5)] as PackedVector2Array, land_green)
	_draw_land([Vector2(282.2, 35.7), Vector2(283.6, 40.4), Vector2(285.5, 44.1), Vector2(282.6, 39.9), Vector2(281.1, 36.6)] as PackedVector2Array, land_green)
	_draw_land([Vector2(103.8, 50.5), Vector2(105.9, 58.4), Vector2(101.5, 63.4), Vector2(103.5, 68.0), Vector2(100.5, 71.9), Vector2(100.1, 68.2), Vector2(100.3, 63.8), Vector2(100.1, 58.9), Vector2(100.7, 49.6), Vector2(99.4, 45.1), Vector2(99.6, 39.0), Vector2(100.7, 34.9), Vector2(103.0, 41.5), Vector2(102.9, 46.0), Vector2(103.8, 50.5)] as PackedVector2Array, land_green)
	_draw_land([Vector2(238.9, 21.9), Vector2(235.4, 20.4), Vector2(238.4, 18.1), Vector2(238.9, 21.9)] as PackedVector2Array, land_green)
	_draw_land([Vector2(212.1, 9.4), Vector2(208.1, 8.0), Vector2(211.9, 7.7)] as PackedVector2Array, land_green)
	# Americas - full right side (Alaska down to Mexico, filled to right edge)
	_draw_land([Vector2(320, 0), Vector2(210.9, 0), Vector2(210.9, 2.2), Vector2(213.8, 34.1), Vector2(221.4, 29.8), Vector2(228.0, 24.8), Vector2(231.9, 20.5), Vector2(236.8, 11.9), Vector2(242.3, 5.7), Vector2(241.7, 12.8), Vector2(245.9, 10.3), Vector2(249.1, 6.0), Vector2(258.2, 9.0), Vector2(266.9, 11.0), Vector2(273.9, 17.0), Vector2(280.4, 21.6), Vector2(283.2, 25.3), Vector2(285.7, 30.6), Vector2(286.9, 34.6), Vector2(289.5, 37.9), Vector2(289.9, 41.5), Vector2(292.3, 46.1), Vector2(293.5, 50.1), Vector2(298.9, 53.9), Vector2(303.3, 58.3), Vector2(304.0, 62.0), Vector2(300.0, 64.1), Vector2(300.6, 67.9), Vector2(301.0, 73.9), Vector2(300.5, 82.1), Vector2(300.3, 89.7), Vector2(301.1, 99.7), Vector2(301.4, 103.4), Vector2(303.9, 109.7), Vector2(305.7, 115.9), Vector2(310.5, 124.0), Vector2(313.7, 127.3), Vector2(316.3, 136.2), Vector2(318.9, 145.5), Vector2(320, 156.3), Vector2(320, 0)] as PackedVector2Array, land_alt)
	# Eurasia - Russia/China (left edge, filled to edge)
	_draw_land([Vector2(0, 0), Vector2(100.7, 13.3), Vector2(93.8, 22.0), Vector2(85.6, 32.6), Vector2(90.0, 36.0), Vector2(98.9, 40.0), Vector2(98.9, 43.8), Vector2(97.3, 48.3), Vector2(96.1, 60.8), Vector2(92.9, 67.3), Vector2(89.3, 75.6), Vector2(82.2, 86.1), Vector2(76.7, 87.2), Vector2(74.0, 94.7), Vector2(71.8, 97.8), Vector2(69.3, 101.7), Vector2(73.0, 110.2), Vector2(73.5, 118.3), Vector2(70.8, 121.6), Vector2(67.2, 123.9), Vector2(66.4, 113.4), Vector2(64.0, 105.2), Vector2(59.5, 100.3), Vector2(55.6, 103.6), Vector2(52.6, 99.1), Vector2(49.2, 102.3), Vector2(49.2, 107.4), Vector2(55.1, 108.2), Vector2(55.7, 113.7), Vector2(52.6, 118.4), Vector2(53.8, 124.0), Vector2(56.0, 132.5), Vector2(57.4, 136.0), Vector2(57.5, 148.0), Vector2(54.2, 156.8), Vector2(50.5, 168.0), Vector2(44.6, 175.9), Vector2(35.9, 181.5), Vector2(32.9, 186.9), Vector2(25.0, 185.3), Vector2(23.2, 189.5), Vector2(24.4, 197.4), Vector2(29.6, 209.6), Vector2(30.6, 217.9), Vector2(30.3, 225.8), Vector2(24.3, 235.4), Vector2(21.7, 239.6), Vector2(18.1, 230.4), Vector2(12.8, 218.0), Vector2(10.7, 222.9), Vector2(9.6, 229.5), Vector2(11.3, 240.9), Vector2(14.1, 247.9), Vector2(17.0, 253.3), Vector2(18.0, 259.4), Vector2(19.7, 270.8), Vector2(13.6, 265.7), Vector2(11.3, 251.0), Vector2(8.5, 242.7), Vector2(7.0, 237.9), Vector2(7.5, 219.3), Vector2(5.5, 205.9), Vector2(0.8, 207.6), Vector2(0, 210), Vector2(0, 0)] as PackedVector2Array, land)

func _input(event: InputEvent) -> void:
	if ship_arrived and event is InputEventKey and event.pressed:
		if GameManager.current_level >= stop_t_values.size():
			get_tree().change_scene_to_file("res://scenes/victory.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/game.tscn")
