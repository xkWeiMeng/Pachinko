extends Control

## Matrix-style falling character rain with CRT scan lines.
## Used as a background effect on the About screen.

const CHAR_SET := "アイウエオカキクケコサシスセソタチツテトナニヌネノ0123456789"
const COL_COUNT := 22
const CHAR_H := 14
const W := 540.0
const H := 960.0

var _cols: Array = []
var _time: float = 0.0


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	for i in COL_COUNT:
		_cols.append(_new_col(true))


func _new_col(random_start: bool) -> Dictionary:
	return {
		"x": snapped(randf() * W, 20.0),
		"y": (randf() * H * 1.5 - H * 0.5) if random_start else -randf_range(30, 400),
		"spd": randf_range(35.0, 130.0),
		"len": randi_range(8, 22),
		"ch": _rand_chars(26),
	}


func _rand_chars(n: int) -> Array:
	var a: Array = []
	for i in n:
		a.append(CHAR_SET[randi() % CHAR_SET.length()])
	return a


func _process(delta: float) -> void:
	_time += delta
	for c in _cols:
		c["y"] += c["spd"] * delta
		if c["y"] - c["len"] * CHAR_H > H:
			var nc := _new_col(false)
			c["x"] = nc["x"]
			c["y"] = nc["y"]
			c["spd"] = nc["spd"]
			c["len"] = nc["len"]
			c["ch"] = nc["ch"]
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font

	# Rain columns
	for c in _cols:
		var x: float = c["x"]
		var hy: float = c["y"]
		var tlen: int = c["len"]
		var chars: Array = c["ch"]
		for i in tlen:
			var y: float = hy - i * CHAR_H
			if y < -CHAR_H or y > H + CHAR_H:
				continue
			var t: float = float(i) / float(tlen)
			var a: float = (1.0 - t) * 0.5
			var col: Color
			if i == 0:
				col = Color(0.5, 1.0, 0.65, minf(a * 1.6, 0.75))
			elif i < 3:
				col = Color(0.15, 0.8, 0.4, a)
			else:
				col = Color(0.0, 0.5, 0.2, a * 0.6)
			var ci: int = (i + int(_time * 3.5 + x * 0.1)) % chars.size()
			draw_char(font, Vector2(x, y), chars[ci], CHAR_H, col)

	# CRT scan lines (scroll slowly downward)
	var sc := Color(0.0, 0.0, 0.0, 0.05)
	var sy: float = fmod(_time * 25.0, 4.0)
	while sy < H:
		draw_line(Vector2(0, sy), Vector2(W, sy), sc, 1.0)
		sy += 4.0
