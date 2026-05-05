extends Control

## Drawable panel for the bottom button bar.
## Renders 4 icon buttons (back, left, right, launch) and a board indicator.

signal button_pressed(index: int)
signal launch_hold_started
signal launch_hold_ended

const BOARD_W := 540.0
const BAR_H := 56.0
const BTN_W := 56.0
const BTN_H := 40.0
const BTN_RADIUS := 10

const ICON_CLR := Color(0.82, 0.82, 0.88)
const ICON_ACCENT := Color(1.0, 0.85, 0.2)
const BG_NORMAL := Color(0.08, 0.08, 0.14, 0.85)
const BG_HOVER := Color(0.15, 0.15, 0.24, 0.9)
const BG_PRESSED := Color(0.04, 0.04, 0.08, 0.95)

var board_count: int = 3
var current_board: int = 0
var board_name: String = "CLASSIC"

var _btn_rects: Array[Rect2] = []
var _hover_idx: int = -1
var _press_idx: int = -1
var _sb_normal: StyleBoxFlat
var _sb_hover: StyleBoxFlat
var _sb_pressed: StyleBoxFlat


func _ready() -> void:
	size = Vector2(BOARD_W, BAR_H)
	position = Vector2(0, 960.0 - BAR_H)
	mouse_filter = MOUSE_FILTER_STOP

	var spacing := BOARD_W / 4.0
	for i in 4:
		var x := spacing * i + (spacing - BTN_W) / 2.0
		var y := (BAR_H - BTN_H) / 2.0
		_btn_rects.append(Rect2(x, y, BTN_W, BTN_H))

	_sb_normal = _make_sb(BG_NORMAL)
	_sb_hover = _make_sb(BG_HOVER)
	_sb_pressed = _make_sb(BG_PRESSED)


func _make_sb(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(BTN_RADIUS)
	sb.border_color = Color(0.3, 0.3, 0.4, 0.25)
	sb.set_border_width_all(1)
	return sb


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var new_hover := _hit_test(event.position)
		if new_hover != _hover_idx:
			_hover_idx = new_hover
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_idx = _hit_test(event.position)
			if _press_idx == 3:
				launch_hold_started.emit()
			queue_redraw()
		else:
			if _press_idx == 3:
				launch_hold_ended.emit()
			var idx := _hit_test(event.position)
			if idx >= 0 and idx < 3 and idx == _press_idx:
				button_pressed.emit(idx)
			_press_idx = -1
			queue_redraw()


func _hit_test(pos: Vector2) -> int:
	for i in _btn_rects.size():
		if _btn_rects[i].has_point(pos):
			return i
	return -1


func _draw() -> void:
	# Bar background
	draw_rect(Rect2(0, 0, BOARD_W, BAR_H), Color(0.012, 0.012, 0.025, 0.92))
	draw_line(Vector2(0, 0), Vector2(BOARD_W, 0), Color(0.25, 0.25, 0.35, 0.4), 1.0)

	# Buttons
	for i in 4:
		var rect := _btn_rects[i]
		var sb: StyleBoxFlat
		if i == _press_idx:
			sb = _sb_pressed
		elif i == _hover_idx:
			sb = _sb_hover
		else:
			sb = _sb_normal
		draw_style_box(sb, rect)

		var center := rect.position + rect.size / 2.0
		match i:
			0: _draw_back_icon(center)
			1: _draw_left_icon(center)
			2: _draw_right_icon(center)
			3: _draw_launch_icon(center)

	# Board indicator dots + name
	var dot_y := 5.0
	var dot_spacing := 10.0
	var total_w := (board_count - 1) * dot_spacing
	var start_x := BOARD_W / 2.0 - total_w / 2.0
	for i in board_count:
		var dx := start_x + i * dot_spacing
		if i == current_board:
			draw_circle(Vector2(dx, dot_y), 3.0, ICON_ACCENT)
		else:
			draw_circle(Vector2(dx, dot_y), 2.0, Color(0.4, 0.4, 0.5, 0.6))

	# Board name label
	var font := ThemeDB.fallback_font
	var name_w := font.get_string_size(board_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 9).x
	draw_string(font, Vector2((BOARD_W - name_w) / 2.0, 16.0), board_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.5, 0.5, 0.6, 0.7))


func _draw_back_icon(c: Vector2) -> void:
	# "Exit" icon: vertical bar + left arrow
	var clr := ICON_CLR
	draw_rect(Rect2(c.x - 11, c.y - 7, 3, 14), clr)
	var pts := PackedVector2Array([
		Vector2(c.x - 3, c.y),
		Vector2(c.x + 6, c.y - 7),
		Vector2(c.x + 6, c.y + 7),
	])
	draw_polygon(pts, PackedColorArray([clr, clr, clr]))


func _draw_left_icon(c: Vector2) -> void:
	var clr := ICON_CLR
	var pts := PackedVector2Array([
		Vector2(c.x - 7, c.y),
		Vector2(c.x + 5, c.y - 8),
		Vector2(c.x + 5, c.y + 8),
	])
	draw_polygon(pts, PackedColorArray([clr, clr, clr]))


func _draw_right_icon(c: Vector2) -> void:
	var clr := ICON_CLR
	var pts := PackedVector2Array([
		Vector2(c.x + 7, c.y),
		Vector2(c.x - 5, c.y - 8),
		Vector2(c.x - 5, c.y + 8),
	])
	draw_polygon(pts, PackedColorArray([clr, clr, clr]))


func _draw_launch_icon(c: Vector2) -> void:
	# Up arrow with bar — gold accent
	var clr := ICON_ACCENT
	var pts := PackedVector2Array([
		Vector2(c.x, c.y - 9),
		Vector2(c.x - 9, c.y + 3),
		Vector2(c.x + 9, c.y + 3),
	])
	draw_polygon(pts, PackedColorArray([clr, clr, clr]))
	draw_rect(Rect2(c.x - 5, c.y + 6, 10, 3), clr)
