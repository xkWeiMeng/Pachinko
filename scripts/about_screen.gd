class_name AboutScreen
extends CanvasLayer

## Geeky terminal-style About page with matrix rain background,
## line-by-line text reveal, and blinking cursor.

signal back_requested

const MatrixRainScript = preload("res://scripts/matrix_rain.gd")

const BOARD_W := 540.0
const PANEL_X := 55.0
const PANEL_Y := 260.0
const PANEL_W := 430.0
const PANEL_H := 420.0
const LINE_H := 28.0
const LINE_INTERVAL := 0.07

const ACCENT := Color(0.0, 0.88, 0.55)
const ACCENT_DIM := Color(0.0, 0.55, 0.35)
const TEXT_CLR := Color(0.88, 0.92, 0.88)
const BORDER_CLR := Color(0.0, 0.65, 0.4, 0.35)
const PANEL_BG := Color(0.01, 0.025, 0.04, 0.88)

var _time: float = 0.0
var _phase: int = 0
var _timer: float = 0.0
var _panel_group: Array[CanvasItem] = []
var _lines: Array[CanvasItem] = []
var _line_idx: int = 0
var _cursor: Label
var _back_label: Label
var _can_exit: bool = false


func _ready() -> void:
	# Dark base
	var bg := ColorRect.new()
	bg.color = Color(0.003, 0.005, 0.015)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Matrix rain background
	add_child(MatrixRainScript.new())

	# Header
	var hdr := Label.new()
	hdr.text = "A B O U T"
	hdr.add_theme_font_size_override("font_size", 28)
	hdr.add_theme_color_override("font_color", ACCENT)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.size = Vector2(BOARD_W, 40)
	hdr.position = Vector2(0, 195)
	hdr.modulate.a = 0.0
	add_child(hdr)
	_panel_group.append(hdr)

	# Panel background
	var pbg := ColorRect.new()
	pbg.color = PANEL_BG
	pbg.size = Vector2(PANEL_W, PANEL_H)
	pbg.position = Vector2(PANEL_X, PANEL_Y)
	pbg.modulate.a = 0.0
	add_child(pbg)
	_panel_group.append(pbg)

	# Panel borders
	_add_panel_rect(PANEL_X, PANEL_Y, PANEL_W, 1)
	_add_panel_rect(PANEL_X, PANEL_Y + PANEL_H - 1, PANEL_W, 1)
	_add_panel_rect(PANEL_X, PANEL_Y, 1, PANEL_H)
	_add_panel_rect(PANEL_X + PANEL_W - 1, PANEL_Y, 1, PANEL_H)

	# Corner markers
	for d in [
		["┌", PANEL_X - 12, PANEL_Y - 6],
		["┐", PANEL_X + PANEL_W + 2, PANEL_Y - 6],
		["└", PANEL_X - 12, PANEL_Y + PANEL_H - 8],
		["┘", PANEL_X + PANEL_W + 2, PANEL_Y + PANEL_H - 8],
	]:
		var c := Label.new()
		c.text = d[0]
		c.add_theme_font_size_override("font_size", 14)
		c.add_theme_color_override("font_color", ACCENT_DIM)
		c.position = Vector2(d[1], d[2])
		c.modulate.a = 0.0
		add_child(c)
		_panel_group.append(c)

	# === Terminal content ===
	var cx := PANEL_X + 25.0
	var cy := PANEL_Y + 18.0

	# Command line
	_add_text_line(cx, cy, "> SYS.QUERY(AUTHOR)", 14, ACCENT)
	cy += LINE_H

	# Separator
	_add_text_line(cx, cy, "═══════════════════════════════", 10, ACCENT_DIM)
	cy += LINE_H + 4

	# Data entries
	var entries := [
		["NAME", "XieKang"],
		["ROLE", "Creator  /  Developer"],
		["PROJECT", "パチンコ  PACHINKO"],
		["ENGINE", "Godot 4.x"],
		["RENDERER", "100%  Procedural  _draw()"],
		["ASSETS", "0  External  Files"],
		["AUDIO", "PCM  Waveform  Synthesis"],
		["PHYSICS", "120Hz  RigidBody2D"],
	]
	for e in entries:
		_add_data_line(cx, cy, e[0], e[1])
		cy += LINE_H

	cy += 4
	# Bottom separator
	_add_text_line(cx, cy, "═══════════════════════════════", 10, ACCENT_DIM)
	cy += LINE_H

	# Cursor
	_cursor = Label.new()
	_cursor.text = "> ▮"
	_cursor.add_theme_font_size_override("font_size", 14)
	_cursor.add_theme_color_override("font_color", ACCENT)
	_cursor.position = Vector2(cx, cy)
	_cursor.modulate.a = 0.0
	add_child(_cursor)
	_lines.append(_cursor)

	# Back hint
	_back_label = Label.new()
	_back_label.text = "PRESS  SPACE  TO  RETURN"
	_back_label.add_theme_font_size_override("font_size", 12)
	_back_label.add_theme_color_override("font_color", Color(0.35, 0.45, 0.4))
	_back_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back_label.size = Vector2(BOARD_W, 20)
	_back_label.position = Vector2(0, 740)
	_back_label.modulate.a = 0.0
	add_child(_back_label)


func _add_panel_rect(x: float, y: float, w: float, h: float) -> void:
	var r := ColorRect.new()
	r.color = BORDER_CLR
	r.size = Vector2(w, h)
	r.position = Vector2(x, y)
	r.modulate.a = 0.0
	add_child(r)
	_panel_group.append(r)


func _add_text_line(x: float, y: float, text: String, sz: int, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", sz)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = Vector2(x, y)
	lbl.modulate.a = 0.0
	add_child(lbl)
	_lines.append(lbl)


func _add_data_line(x: float, y: float, key: String, value: String) -> void:
	# Container so key + value reveal together as one unit
	var cont := Control.new()
	cont.modulate.a = 0.0
	add_child(cont)

	var k := Label.new()
	k.text = key
	k.add_theme_font_size_override("font_size", 13)
	k.add_theme_color_override("font_color", ACCENT)
	k.position = Vector2(x, y)
	cont.add_child(k)

	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 13)
	v.add_theme_color_override("font_color", TEXT_CLR)
	v.position = Vector2(x + 130, y)
	cont.add_child(v)

	_lines.append(cont)


func _process(delta: float) -> void:
	_time += delta
	_timer += delta

	match _phase:
		0:  # Wait briefly, then reveal panel frame
			if _timer >= 0.3:
				for n in _panel_group:
					n.modulate.a = 1.0
				_phase = 1
				_timer = 0.0
		1:  # Reveal terminal lines one by one
			while _timer >= LINE_INTERVAL and _line_idx < _lines.size():
				_lines[_line_idx].modulate.a = 1.0
				_line_idx += 1
				_timer -= LINE_INTERVAL
			if _line_idx >= _lines.size():
				_phase = 2
				_timer = 0.0
		2:  # Show back hint
			if _timer >= 0.3:
				_back_label.modulate.a = 1.0
				_can_exit = true
				_phase = 3
		3:  # Idle with blinking cursor
			_cursor.modulate.a = 1.0 if fmod(_time, 0.9) < 0.55 else 0.15

	# Input
	if Input.is_action_just_pressed("launch") or Input.is_action_just_pressed("ui_accept"):
		if _can_exit:
			back_requested.emit()
		elif _phase < 3:
			# Skip animation — reveal everything instantly
			for n in _panel_group:
				n.modulate.a = 1.0
			for n in _lines:
				n.modulate.a = 1.0
			_back_label.modulate.a = 1.0
			_can_exit = true
			_phase = 3
			_line_idx = _lines.size()
