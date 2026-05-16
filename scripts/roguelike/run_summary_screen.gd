class_name RunSummaryScreen
extends CanvasLayer

## Run end screen showing stats and outcome.

signal continue_pressed

const BOARD_W := 540.0
const BOARD_H := 960.0

var _won: bool = false
var _stats: Dictionary = {}
var _input_ready: bool = false


func setup(won: bool, stats: Dictionary) -> void:
	_won = won
	_stats = stats


func _ready() -> void:
	layer = 20
	_build()
	call_deferred("_enable_input")


func _enable_input() -> void:
	_input_ready = true


func _build() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.005, 0.0, 0.03, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Theme colors
	var title_color: Color
	var accent_color: Color
	var title_text: String

	if _won:
		title_color = Color(1.0, 0.85, 0.2)
		accent_color = Color(1.0, 0.9, 0.4)
		title_text = "★  RUN COMPLETE  ★"
	else:
		title_color = Color(1.0, 0.3, 0.2)
		accent_color = Color(0.8, 0.3, 0.3)
		title_text = "RUN OVER"

	# Title
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", title_color)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(BOARD_W, 50)
	title.position = Vector2(0, 150)
	add_child(title)

	# Decorative line
	var line := ColorRect.new()
	line.color = Color(title_color.r, title_color.g, title_color.b, 0.4)
	line.size = Vector2(280, 2)
	line.position = Vector2((BOARD_W - 280) / 2.0, 210)
	add_child(line)

	# Stats container
	var stats_y := 250.0
	var stats_gap := 35.0

	_add_stat_line("Floors Cleared", str(_stats.get("floors_cleared", 0)), stats_y, accent_color)
	stats_y += stats_gap
	_add_stat_line("Final Score", str(_stats.get("final_score", 0)), stats_y, accent_color)
	stats_y += stats_gap
	_add_stat_line("Balls Remaining", str(_stats.get("balls_remaining", 0)), stats_y, accent_color)
	stats_y += stats_gap
	_add_stat_line("Total Captures", str(_stats.get("total_captures", 0)), stats_y, accent_color)
	stats_y += stats_gap
	_add_stat_line("Total Jackpots", str(_stats.get("total_jackpots", 0)), stats_y, accent_color)
	stats_y += stats_gap

	# Relics section
	var relics: Array = _stats.get("relics", [])
	if not relics.is_empty():
		stats_y += 15.0
		var relics_title := Label.new()
		relics_title.text = "RELICS COLLECTED"
		relics_title.add_theme_font_size_override("font_size", 16)
		relics_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		relics_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		relics_title.size = Vector2(BOARD_W, 25)
		relics_title.position = Vector2(0, stats_y)
		add_child(relics_title)
		stats_y += 30.0

		# Relic icons in a row
		var relic_text := ""
		for relic_id in relics:
			var relic_data: Dictionary = RelicManager.get_relic_data(relic_id)
			if not relic_data.is_empty():
				relic_text += relic_data.get("icon_char", "?") + " "

		if not relic_text.is_empty():
			var relic_icons := Label.new()
			relic_icons.text = relic_text.strip_edges()
			relic_icons.add_theme_font_size_override("font_size", 24)
			relic_icons.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			relic_icons.size = Vector2(BOARD_W, 35)
			relic_icons.position = Vector2(0, stats_y)
			add_child(relic_icons)
			stats_y += 40.0

	# Return button
	var btn_label := Label.new()
	btn_label.text = "[ RETURN TO MENU ]"
	btn_label.add_theme_font_size_override("font_size", 20)
	btn_label.add_theme_color_override("font_color", accent_color)
	btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_label.size = Vector2(BOARD_W, 30)
	btn_label.position = Vector2(0, 720)
	add_child(btn_label)

	# Controls hint
	var hint := Label.new()
	hint.text = "SPACE  Continue"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(BOARD_W, 20)
	hint.position = Vector2(0, 760)
	add_child(hint)


func _add_stat_line(label_text: String, value_text: String, y: float, color: Color) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	label.position = Vector2(80, y)
	label.size = Vector2(200, 25)
	add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size = Vector2(200, 25)
	value.position = Vector2(260, y)
	add_child(value)


func _process(_delta: float) -> void:
	if not _input_ready:
		return
	if Input.is_action_just_pressed("launch") or Input.is_action_just_pressed("ui_accept"):
		continue_pressed.emit()
		queue_free()
