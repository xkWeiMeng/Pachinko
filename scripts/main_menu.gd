class_name MainMenu
extends CanvasLayer

signal start_game_requested
signal about_requested
signal roguelike_requested

const BOARD_W := 540.0
const SELECTED_COLOR := Color(1.0, 0.85, 0.2)
const NORMAL_COLOR := Color(0.5, 0.5, 0.6)
const GOLD_DIM := Color(0.6, 0.55, 0.2)
const ITEMS := ["ROGUELIKE", "CLASSIC", "ABOUT"]
const MENU_Y := 450.0
const ITEM_GAP := 55.0
const DOT_COUNT := 25

var _selected: int = 0
var _labels: Array[Label] = []
var _selector: Label
var _time: float = 0.0
var _dots: Array[Dictionary] = []
var _input_ready: bool = false


func _ready() -> void:
	_build()
	call_deferred("_enable_input")


func _enable_input() -> void:
	_input_ready = true


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.005, 0.0, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Floating golden dust particles
	for i in DOT_COUNT:
		var sz := randf_range(1.5, 3.0)
		var dot := ColorRect.new()
		dot.size = Vector2(sz, sz)
		dot.color = Color(1.0, 0.85, 0.3, randf_range(0.03, 0.12))
		dot.position = Vector2(randf() * BOARD_W, randf() * 960.0)
		add_child(dot)
		_dots.append({"node": dot, "speed": randf_range(10.0, 30.0)})

	# Title
	var title := Label.new()
	title.text = "パチンコ"
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", SELECTED_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(BOARD_W, 80)
	title.position = Vector2(0, 200)
	add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "P  A  C  H  I  N  K  O"
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", GOLD_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(BOARD_W, 25)
	sub.position = Vector2(0, 290)
	add_child(sub)

	# Decorative double line
	for dy in [330, 332]:
		var line := ColorRect.new()
		line.color = Color(0.5, 0.4, 0.1, 0.35)
		line.size = Vector2(240, 1)
		line.position = Vector2(150, dy)
		add_child(line)

	# High score (only if > 0)
	if GameState.high_score > 0:
		var hs := Label.new()
		hs.text = "BEST  %d" % GameState.high_score
		hs.add_theme_font_size_override("font_size", 13)
		hs.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
		hs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hs.size = Vector2(BOARD_W, 20)
		hs.position = Vector2(0, 370)
		add_child(hs)

	# Menu items
	for i in ITEMS.size():
		var lbl := Label.new()
		lbl.text = ITEMS[i]
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size = Vector2(BOARD_W, 35)
		lbl.position = Vector2(0, MENU_Y + i * ITEM_GAP)
		add_child(lbl)
		_labels.append(lbl)

	# Selector arrow
	_selector = Label.new()
	_selector.text = "▸"
	_selector.add_theme_font_size_override("font_size", 24)
	_selector.add_theme_color_override("font_color", SELECTED_COLOR)
	add_child(_selector)

	# Controls hint
	var hint := Label.new()
	hint.text = "↑ ↓  Select    SPACE  Confirm"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(BOARD_W, 20)
	hint.position = Vector2(0, 700)
	add_child(hint)

	# Version tag
	var ver := Label.new()
	ver.text = "v1.0"
	ver.add_theme_font_size_override("font_size", 9)
	ver.add_theme_color_override("font_color", Color(0.25, 0.25, 0.3))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.size = Vector2(BOARD_W, 15)
	ver.position = Vector2(0, 920)
	add_child(ver)

	_refresh()


func _process(delta: float) -> void:
	_time += delta

	# Animate floating dust
	for d in _dots:
		d["node"].position.y -= d["speed"] * delta
		if d["node"].position.y < -5:
			d["node"].position.y = 965
			d["node"].position.x = randf() * BOARD_W

	# Pulse selector
	_selector.modulate.a = 0.45 + 0.55 * sin(_time * 3.5)

	if not _input_ready:
		return

	# Navigation
	if Input.is_action_just_pressed("ui_down"):
		_selected = (_selected + 1) % ITEMS.size()
		_refresh()
	elif Input.is_action_just_pressed("ui_up"):
		_selected = (_selected - 1 + ITEMS.size()) % ITEMS.size()
		_refresh()
	elif Input.is_action_just_pressed("launch") or Input.is_action_just_pressed("ui_accept"):
		_confirm()


func _refresh() -> void:
	for i in _labels.size():
		_labels[i].add_theme_color_override(
			"font_color", SELECTED_COLOR if i == _selected else NORMAL_COLOR
		)
	_selector.position = Vector2(158, MENU_Y + _selected * ITEM_GAP)


func _confirm() -> void:
	match _selected:
		0: roguelike_requested.emit()
		1: start_game_requested.emit()
		2: about_requested.emit()
