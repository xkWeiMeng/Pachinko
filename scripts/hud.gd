class_name HUD
extends CanvasLayer

var score_label: Label
var balls_label: Label
var high_score_label: Label
var game_over_panel: Control
var final_score_label: Label
var jackpot_label: Label
var jackpot_tween: Tween

const LABEL_COLOR := Color(0.85, 0.85, 0.9)
const ACCENT_COLOR := Color(0.9, 0.85, 0.3)


func _ready() -> void:
	_build_ui()
	GameState.score_changed.connect(_on_score_changed)
	GameState.balls_changed.connect(_on_balls_changed)
	GameState.game_over.connect(_on_game_over)
	EventBus.jackpot_hit.connect(_on_jackpot)
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

	# Game Over panel
	_build_game_over_panel()


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
