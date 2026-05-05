class_name PachinkoSlots
extends Control

signal jackpot_hit

@export var spin_duration: float = 2.0

var wheel_values: Array[String] = ["1", "1", "1", "2", "3", "4", "5", "7"]

var wheel_1_spinning: bool = false
var wheel_2_spinning: bool = false
var wheel_3_spinning: bool = false

var spin_timer: Timer

var wheel_1: Label
var wheel_2: Label
var wheel_3: Label
var bg_panel: Panel

const FONT_SIZE: int = 48
const SLOT_WIDTH: int = 50
const SLOT_HEIGHT: int = 60
const GAP: int = 8


func _ready() -> void:
	_build_ui()

	spin_timer = Timer.new()
	add_child(spin_timer)
	spin_timer.timeout.connect(_on_spin_timer_timeout)
	spin_timer.wait_time = 0.02
	spin_timer.one_shot = false

	EventBus.spin_started.connect(_on_spin_requested)


func _build_ui() -> void:
	var total_size := Vector2(SLOT_WIDTH * 3 + GAP * 4, SLOT_HEIGHT + GAP * 2)
	custom_minimum_size = total_size
	size = total_size

	# Background panel
	bg_panel = Panel.new()
	bg_panel.size = total_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.08, 0.9)
	style.border_color = Color(0.4, 0.35, 0.1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	bg_panel.add_theme_stylebox_override("panel", style)
	add_child(bg_panel)

	# Title
	var title := Label.new()
	title.text = "PACHINKO"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 2)
	title.size = Vector2(SLOT_WIDTH * 3 + GAP * 4, 16)
	add_child(title)

	# Wheel labels
	wheel_1 = _create_wheel_label(0)
	wheel_2 = _create_wheel_label(1)
	wheel_3 = _create_wheel_label(2)

	# Separators
	for i in range(2):
		var sep := Label.new()
		sep.text = "|"
		sep.add_theme_font_size_override("font_size", FONT_SIZE)
		sep.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
		sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sep.position = Vector2(GAP + (i + 1) * (SLOT_WIDTH + GAP) - GAP / 2, 16)
		sep.size = Vector2(GAP, SLOT_HEIGHT)
		add_child(sep)


func _create_wheel_label(index: int) -> Label:
	var label := Label.new()
	label.text = "0"
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(GAP + index * (SLOT_WIDTH + GAP), 16)
	label.size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)
	add_child(label)
	return label


func _on_spin_timer_timeout() -> void:
	if wheel_1_spinning:
		wheel_1.text = wheel_values[randi() % wheel_values.size()]
	if wheel_2_spinning:
		wheel_2.text = wheel_values[randi() % wheel_values.size()]
	if wheel_3_spinning:
		wheel_3.text = wheel_values[randi() % wheel_values.size()]


func _on_spin_requested() -> void:
	if wheel_1_spinning or wheel_2_spinning or wheel_3_spinning:
		return
	start_spin()


func start_spin() -> void:
	spin_timer.start()
	wheel_1_spinning = true
	wheel_2_spinning = true
	wheel_3_spinning = true

	wheel_1.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
	wheel_2.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
	wheel_3.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))

	await get_tree().create_timer(spin_duration * 0.35).timeout
	wheel_1_spinning = false

	await get_tree().create_timer(spin_duration * 0.35).timeout
	wheel_2_spinning = false

	# Check for "reach" (first two match) — add suspense
	if wheel_1.text == wheel_2.text:
		wheel_1.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		wheel_2.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		await get_tree().create_timer(spin_duration * 0.6).timeout
	else:
		await get_tree().create_timer(spin_duration * 0.3).timeout

	wheel_3_spinning = false
	spin_timer.stop()
	_check_jackpot()


func _check_jackpot() -> void:
	if wheel_1.text == wheel_2.text and wheel_2.text == wheel_3.text:
		_play_jackpot_effect()
		jackpot_hit.emit()
		EventBus.jackpot_hit.emit()
	else:
		# Reset colors
		wheel_1.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		wheel_2.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		wheel_3.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		var reset_tween := create_tween()
		reset_tween.tween_interval(1.0)
		reset_tween.tween_callback(func():
			wheel_1.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
			wheel_2.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
			wheel_3.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
		)


func _play_jackpot_effect() -> void:
	# Flash all wheels gold
	var gold := Color(1.0, 0.85, 0.0)
	wheel_1.add_theme_color_override("font_color", gold)
	wheel_2.add_theme_color_override("font_color", gold)
	wheel_3.add_theme_color_override("font_color", gold)

	# Scale bounce
	var tween := create_tween().set_loops(4)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and bg_panel:
		bg_panel.size = size
