class_name RelicSelectionScreen
extends CanvasLayer

## 3-pick-1 relic selection screen shown after clearing a floor.

signal relic_selected(relic_id: String)
signal selection_skipped

const BOARD_W := 540.0
const BOARD_H := 960.0
const CARD_W := 140.0
const CARD_H := 200.0
const CARD_GAP := 20.0
const RARITY_COLORS := {
	0: Color(0.5, 0.5, 0.55),    # COMMON — gray
	1: Color(0.3, 0.5, 1.0),     # RARE — blue
	2: Color(0.65, 0.3, 0.85),   # EPIC — purple
	3: Color(1.0, 0.8, 0.2),     # LEGENDARY — gold
}

var _relics: Array[Dictionary] = []
var _selected: int = 0
var _labels: Array[Label] = []
var _card_panels: Array[Control] = []
var _bg: ColorRect
var _input_ready: bool = false
var _draw_node: Control


func setup(relics: Array[Dictionary]) -> void:
	_relics = relics


func _ready() -> void:
	layer = 20
	_build()
	call_deferred("_enable_input")


func _enable_input() -> void:
	_input_ready = true


func _build() -> void:
	# Dark overlay
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.02, 0.85)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	# Title
	var title := Label.new()
	title.text = "CHOOSE A RELIC"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(BOARD_W, 40)
	title.position = Vector2(0, 180)
	add_child(title)

	# Cards
	var total_w := CARD_W * _relics.size() + CARD_GAP * (_relics.size() - 1)
	var start_x := (BOARD_W - total_w) / 2.0

	for i in _relics.size():
		var card := _create_card(i, start_x + i * (CARD_W + CARD_GAP))
		add_child(card)
		_card_panels.append(card)

	# Skip button
	var skip_label := Label.new()
	skip_label.text = "[ SKIP ]"
	skip_label.add_theme_font_size_override("font_size", 16)
	skip_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.size = Vector2(BOARD_W, 25)
	skip_label.position = Vector2(0, 700)
	add_child(skip_label)

	# Controls hint
	var hint := Label.new()
	hint.text = "← →  Select    SPACE  Confirm    S  Skip"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(BOARD_W, 20)
	hint.position = Vector2(0, 740)
	add_child(hint)

	_refresh_selection()


func _create_card(idx: int, x_pos: float) -> Control:
	var relic: Dictionary = _relics[idx]
	var rarity: int = relic.get("rarity", 0)
	var border_color: Color = RARITY_COLORS.get(rarity, Color.WHITE)

	var card := Control.new()
	card.position = Vector2(x_pos, 280)
	card.size = Vector2(CARD_W, CARD_H)

	# Card background (drawn via a ColorRect)
	var card_bg := ColorRect.new()
	card_bg.color = Color(0.05, 0.04, 0.08)
	card_bg.size = Vector2(CARD_W, CARD_H)
	card.add_child(card_bg)

	# Border (top)
	var border_top := ColorRect.new()
	border_top.color = border_color
	border_top.size = Vector2(CARD_W, 3)
	card.add_child(border_top)

	# Border (bottom)
	var border_bot := ColorRect.new()
	border_bot.color = border_color
	border_bot.size = Vector2(CARD_W, 3)
	border_bot.position = Vector2(0, CARD_H - 3)
	card.add_child(border_bot)

	# Border (left)
	var border_left := ColorRect.new()
	border_left.color = border_color
	border_left.size = Vector2(3, CARD_H)
	card.add_child(border_left)

	# Border (right)
	var border_right := ColorRect.new()
	border_right.color = border_color
	border_right.size = Vector2(3, CARD_H)
	border_right.position = Vector2(CARD_W - 3, 0)
	card.add_child(border_right)

	# Icon character
	var icon_lbl := Label.new()
	icon_lbl.text = relic.get("icon_char", "?")
	icon_lbl.add_theme_font_size_override("font_size", 36)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.size = Vector2(CARD_W, 50)
	icon_lbl.position = Vector2(0, 20)
	card.add_child(icon_lbl)

	# Relic name
	var name_lbl := Label.new()
	name_lbl.text = relic.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", border_color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.size = Vector2(CARD_W, 25)
	name_lbl.position = Vector2(0, 80)
	card.add_child(name_lbl)

	# Description (wrapped)
	var desc_lbl := Label.new()
	desc_lbl.text = relic.get("description", "")
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size = Vector2(CARD_W - 12, 70)
	desc_lbl.position = Vector2(6, 115)
	card.add_child(desc_lbl)

	return card


func _refresh_selection() -> void:
	for i in _card_panels.size():
		var rarity: int = _relics[i].get("rarity", 0)
		var border_color: Color = RARITY_COLORS.get(rarity, Color.WHITE)
		if i == _selected:
			_card_panels[i].modulate = Color.WHITE
			_card_panels[i].scale = Vector2(1.05, 1.05)
		else:
			_card_panels[i].modulate = Color(0.6, 0.6, 0.65)
			_card_panels[i].scale = Vector2(1.0, 1.0)


func _process(_delta: float) -> void:
	if not _input_ready:
		return
	if _relics.is_empty():
		return

	if Input.is_action_just_pressed("ui_left"):
		_selected = (_selected - 1 + _relics.size()) % _relics.size()
		_refresh_selection()
	elif Input.is_action_just_pressed("ui_right"):
		_selected = (_selected + 1) % _relics.size()
		_refresh_selection()
	elif Input.is_action_just_pressed("launch") or Input.is_action_just_pressed("ui_accept"):
		_confirm()
	elif Input.is_key_pressed(KEY_S):
		_skip()


func _confirm() -> void:
	if _selected >= 0 and _selected < _relics.size():
		var relic_id: String = _relics[_selected]["id"]
		relic_selected.emit(relic_id)
		queue_free()


func _skip() -> void:
	selection_skipped.emit()
	queue_free()
