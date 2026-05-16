class_name MetaScreen
extends CanvasLayer

signal back_requested

const BOARD_W := 540.0
const GOLD := Color(1.0, 0.85, 0.2)
const DIM := Color(0.5, 0.5, 0.6)
const BG_COLOR := Color(0.005, 0.0, 0.03)
const CHECK_COLOR := Color(0.3, 0.9, 0.3)
const LOCKED_COLOR := Color(0.35, 0.35, 0.4)

var _input_ready: bool = false


func _ready() -> void:
	layer = 20
	_build()
	call_deferred("_enable_input")


func _enable_input() -> void:
	_input_ready = true


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "STATS & ACHIEVEMENTS"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(BOARD_W, 40)
	title.position = Vector2(0, 40)
	add_child(title)

	# Decorative line
	var line := ColorRect.new()
	line.color = Color(0.5, 0.4, 0.1, 0.35)
	line.size = Vector2(300, 1)
	line.position = Vector2(120, 90)
	add_child(line)

	# Stats section
	var stats_y := 110.0
	var stats: Array[Array] = [
		["Total Runs", str(MetaProgress.total_runs)],
		["Total Wins", str(MetaProgress.total_wins)],
		["Best Floor", str(MetaProgress.best_floor)],
		["Best Score", str(MetaProgress.best_score)],
	]

	for stat in stats:
		var row := _create_stat_row(stat[0], stat[1], stats_y)
		add_child(row)
		stats_y += 35.0

	# Achievement section header
	stats_y += 20.0
	var ach_title := Label.new()
	ach_title.text = "ACHIEVEMENTS"
	ach_title.add_theme_font_size_override("font_size", 20)
	ach_title.add_theme_color_override("font_color", GOLD)
	ach_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ach_title.size = Vector2(BOARD_W, 30)
	ach_title.position = Vector2(0, stats_y)
	add_child(ach_title)
	stats_y += 40.0

	# Achievement list
	for def in MetaProgress.ACHIEVEMENT_DEFS:
		var unlocked: bool = MetaProgress.achievements.get(def["id"], false)
		var ach_row := _create_achievement_row(def, unlocked, stats_y)
		add_child(ach_row)
		stats_y += 50.0

	# Back hint
	var hint := Label.new()
	hint.text = "SPACE / ESC  Back"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(BOARD_W, 20)
	hint.position = Vector2(0, 910)
	add_child(hint)


func _create_stat_row(label_text: String, value_text: String, y_pos: float) -> Control:
	var container := Control.new()
	container.size = Vector2(BOARD_W, 30)
	container.position = Vector2(0, y_pos)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", DIM)
	name_label.size = Vector2(250, 25)
	name_label.position = Vector2(80, 0)
	container.add_child(name_label)

	var val_label := Label.new()
	val_label.text = value_text
	val_label.add_theme_font_size_override("font_size", 18)
	val_label.add_theme_color_override("font_color", GOLD)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_label.size = Vector2(120, 25)
	val_label.position = Vector2(340, 0)
	container.add_child(val_label)

	return container


func _create_achievement_row(def: Dictionary, unlocked: bool, y_pos: float) -> Control:
	var container := Control.new()
	container.size = Vector2(BOARD_W, 45)
	container.position = Vector2(0, y_pos)

	var check := Label.new()
	check.text = "✓" if unlocked else "○"
	check.add_theme_font_size_override("font_size", 18)
	check.add_theme_color_override("font_color", CHECK_COLOR if unlocked else LOCKED_COLOR)
	check.size = Vector2(30, 25)
	check.position = Vector2(50, 0)
	container.add_child(check)

	var name_label := Label.new()
	name_label.text = def["name"]
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", GOLD if unlocked else LOCKED_COLOR)
	name_label.size = Vector2(200, 22)
	name_label.position = Vector2(85, 0)
	container.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = def["desc"]
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", DIM if unlocked else LOCKED_COLOR)
	desc_label.size = Vector2(350, 18)
	desc_label.position = Vector2(85, 22)
	container.add_child(desc_label)

	return container


func _process(_delta: float) -> void:
	if not _input_ready:
		return
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("launch") or Input.is_action_just_pressed("ui_accept"):
		back_requested.emit()
