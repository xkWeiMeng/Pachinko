class_name HUD
extends CanvasLayer

var score_label: Label
var balls_label: Label
var high_score_label: Label
var game_over_panel: Control
var final_score_label: Label
var jackpot_label: Label
var jackpot_tween: Tween

# Roguelike HUD elements
var roguelike_mode: bool = false
var _floor_info_label: Label
var _objective_label: Label
var _objective_bar_bg: ColorRect
var _objective_bar_fill: ColorRect
var _relic_strip_label: Label
var _combo_label: Label
var _combo_tween: Tween
var _low_balls_overlay: ColorRect
var _low_balls_tween: Tween

const LABEL_COLOR := Color(0.85, 0.85, 0.9)
const ACCENT_COLOR := Color(0.9, 0.85, 0.3)


func _ready() -> void:
	_build_ui()
	GameState.score_changed.connect(_on_score_changed)
	GameState.balls_changed.connect(_on_balls_changed)
	GameState.game_over.connect(_on_game_over)
	EventBus.jackpot_hit.connect(_on_jackpot)
	EventBus.floor_objective_updated.connect(_on_objective_updated)
	EventBus.combo_updated.connect(_on_combo_updated)
	EventBus.relic_acquired.connect(_on_relic_acquired)
	_update_display()


func _build_ui() -> void:
	# Top-left info panel
	var info_container := VBoxContainer.new()
	info_container.position = Vector2(20, 20)
	add_child(info_container)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", LABEL_COLOR)
	info_container.add_child(score_label)

	balls_label = Label.new()
	balls_label.add_theme_font_size_override("font_size", 16)
	balls_label.add_theme_color_override("font_color", ACCENT_COLOR)
	info_container.add_child(balls_label)

	high_score_label = Label.new()
	high_score_label.add_theme_font_size_override("font_size", 12)
	high_score_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	info_container.add_child(high_score_label)

	# Jackpot announcement
	jackpot_label = Label.new()
	jackpot_label.text = "★ JACKPOT! ★"
	jackpot_label.add_theme_font_size_override("font_size", 36)
	jackpot_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	jackpot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jackpot_label.size = Vector2(540, 50)
	jackpot_label.position = Vector2(0, 120)
	jackpot_label.visible = false
	add_child(jackpot_label)

	# Roguelike: Floor info (top-right)
	_floor_info_label = Label.new()
	_floor_info_label.add_theme_font_size_override("font_size", 14)
	_floor_info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_floor_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_floor_info_label.size = Vector2(200, 20)
	_floor_info_label.position = Vector2(320, 20)
	_floor_info_label.visible = false
	add_child(_floor_info_label)

	# Roguelike: Objective progress bar
	_objective_bar_bg = ColorRect.new()
	_objective_bar_bg.color = Color(0.15, 0.15, 0.2)
	_objective_bar_bg.size = Vector2(200, 12)
	_objective_bar_bg.position = Vector2(320, 42)
	_objective_bar_bg.visible = false
	add_child(_objective_bar_bg)

	_objective_bar_fill = ColorRect.new()
	_objective_bar_fill.color = Color(0.3, 0.8, 0.4)
	_objective_bar_fill.size = Vector2(0, 12)
	_objective_bar_fill.position = Vector2(320, 42)
	_objective_bar_fill.visible = false
	add_child(_objective_bar_fill)

	# Roguelike: Objective text
	_objective_label = Label.new()
	_objective_label.add_theme_font_size_override("font_size", 11)
	_objective_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective_label.size = Vector2(200, 18)
	_objective_label.position = Vector2(320, 56)
	_objective_label.visible = false
	add_child(_objective_label)

	# Roguelike: Relic icon strip (bottom area)
	_relic_strip_label = Label.new()
	_relic_strip_label.add_theme_font_size_override("font_size", 16)
	_relic_strip_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	_relic_strip_label.position = Vector2(15, 870)
	_relic_strip_label.size = Vector2(400, 25)
	_relic_strip_label.visible = false
	add_child(_relic_strip_label)

	# Roguelike: Combo counter (center)
	_combo_label = Label.new()
	_combo_label.add_theme_font_size_override("font_size", 40)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.size = Vector2(540, 55)
	_combo_label.position = Vector2(0, 170)
	_combo_label.visible = false
	add_child(_combo_label)

	# Roguelike: Low balls warning overlay
	_low_balls_overlay = ColorRect.new()
	_low_balls_overlay.color = Color(1.0, 0.1, 0.1, 0.0)
	_low_balls_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_low_balls_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_low_balls_overlay.visible = false
	add_child(_low_balls_overlay)

	# Game Over panel
	_build_game_over_panel()


func setup_roguelike(floor_num: int, act: int, objective_desc: String) -> void:
	roguelike_mode = true
	_floor_info_label.text = "Act %d - Floor %d" % [act, floor_num]
	_floor_info_label.visible = true
	_objective_label.text = objective_desc
	_objective_label.visible = true
	_objective_bar_bg.visible = true
	_objective_bar_fill.visible = true
	_objective_bar_fill.size.x = 0
	_relic_strip_label.visible = true
	_update_relic_strip()
	high_score_label.visible = false


func _build_game_over_panel() -> void:
	game_over_panel = Control.new()
	game_over_panel.visible = false
	game_over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(game_over_panel)

	# Dim background
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_panel.add_child(dim)

	# Center container
	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.position = Vector2(120, 350)
	center.custom_minimum_size = Vector2(300, 200)
	game_over_panel.add_child(center)

	var title := Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	center.add_child(spacer)

	final_score_label = Label.new()
	final_score_label.add_theme_font_size_override("font_size", 24)
	final_score_label.add_theme_color_override("font_color", ACCENT_COLOR)
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(final_score_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	center.add_child(spacer2)

	var restart_btn := Button.new()
	restart_btn.text = "RESTART"
	restart_btn.add_theme_font_size_override("font_size", 20)
	restart_btn.custom_minimum_size = Vector2(200, 50)
	restart_btn.pressed.connect(_on_restart_pressed)
	center.add_child(restart_btn)


func _update_display() -> void:
	score_label.text = "SCORE  %d" % GameState.score
	balls_label.text = "BALLS  %04d" % GameState.balls_remaining
	high_score_label.text = "BEST  %d" % GameState.high_score


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE  %d" % new_score
	# Score bump animation
	var tween := create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.05)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)


func _on_balls_changed(remaining: int) -> void:
	balls_label.text = "BALLS  %04d" % maxi(remaining, 0)
	# Low balls warning in roguelike mode
	if roguelike_mode and remaining < 10 and remaining > 0:
		_low_balls_overlay.visible = true
		if _low_balls_tween:
			_low_balls_tween.kill()
		_low_balls_tween = create_tween().set_loops(3)
		_low_balls_tween.tween_property(_low_balls_overlay, "color:a", 0.08, 0.3)
		_low_balls_tween.tween_property(_low_balls_overlay, "color:a", 0.0, 0.3)
		_low_balls_tween.finished.connect(func(): _low_balls_overlay.visible = false)
	elif remaining >= 10 or remaining <= 0:
		_low_balls_overlay.visible = false


func _on_game_over() -> void:
	final_score_label.text = "SCORE: %d" % GameState.score
	high_score_label.text = "BEST  %d" % GameState.high_score
	game_over_panel.visible = true


func _on_jackpot() -> void:
	jackpot_label.visible = true
	if jackpot_tween:
		jackpot_tween.kill()
	jackpot_tween = create_tween().set_loops(5)
	jackpot_tween.tween_property(jackpot_label, "modulate", Color(1.0, 0.85, 0.0), 0.15)
	jackpot_tween.tween_property(jackpot_label, "modulate", Color(1.0, 1.0, 1.0), 0.15)
	jackpot_tween.finished.connect(func(): jackpot_label.visible = false)


func _on_restart_pressed() -> void:
	game_over_panel.visible = false
	get_tree().reload_current_scene()


func _on_objective_updated(current: int, target: int, desc: String) -> void:
	if not roguelike_mode:
		return
	if target > 0:
		var progress := clampf(float(current) / float(target), 0.0, 1.0)
		_objective_bar_fill.size.x = 200.0 * progress
		_objective_label.text = "%s  %d/%d" % [desc, current, target]


func _on_combo_updated(count: int) -> void:
	if not roguelike_mode:
		return
	if count >= 2:
		_combo_label.text = "COMBO x%d" % count
		_combo_label.visible = true
		if _combo_tween:
			_combo_tween.kill()
		_combo_tween = create_tween()
		_combo_label.scale = Vector2(1.3, 1.3)
		_combo_tween.tween_property(_combo_label, "scale", Vector2(1.0, 1.0), 0.15)
		_combo_tween.tween_interval(1.5)
		_combo_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.3)
		_combo_tween.finished.connect(func():
			_combo_label.visible = false
			_combo_label.modulate.a = 1.0
		)
	else:
		_combo_label.visible = false


func _on_relic_acquired(_relic: Dictionary) -> void:
	if roguelike_mode:
		_update_relic_strip()


func _update_relic_strip() -> void:
	if not is_instance_valid(RelicManager):
		return
	var icons := ""
	for relic in RelicManager.active_relics:
		icons += relic.get("icon_char", "?") + " "
	_relic_strip_label.text = icons.strip_edges()
