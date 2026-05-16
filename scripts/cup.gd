class_name PachinkoCup
extends Node2D

@export var is_crit: bool = false
@export var cup_width: float = 50.0
@export var cup_depth: float = 35.0
@export var reward_balls: int = 15
@export var label_text: String = ""

const NORMAL_COLOR := Color(0.12, 0.56, 1.0)
const CRIT_COLOR := Color(1.0, 0.27, 0.0)
const SMALL_COLOR := Color(0.3, 0.75, 0.5)

var _glow: float = 0.0:
	set(value):
		_glow = value
		queue_redraw()

var _cup_color: Color = NORMAL_COLOR


func _ready() -> void:
	if is_crit:
		_cup_color = CRIT_COLOR
	elif reward_balls <= 10:
		_cup_color = SMALL_COLOR
	else:
		_cup_color = NORMAL_COLOR
	if label_text.is_empty():
		label_text = "★" if is_crit else str(reward_balls)
	# Apply relic width modifier
	if is_instance_valid(RelicManager):
		cup_width *= RelicManager.get_modifier("cup_width_mult", 1.0)
	_create_physics_walls()
	_create_detection_area()


func _create_physics_walls() -> void:
	var hw := cup_width / 2.0

	# Left wall
	var left_wall := StaticBody2D.new()
	left_wall.collision_layer = 4
	left_wall.collision_mask = 1
	var left_shape := CollisionShape2D.new()
	var left_rect := RectangleShape2D.new()
	left_rect.size = Vector2(6, cup_depth + 10)
	left_shape.shape = left_rect
	left_shape.position = Vector2(-hw - 3, cup_depth / 2.0)
	left_wall.add_child(left_shape)
	add_child(left_wall)

	# Right wall
	var right_wall := StaticBody2D.new()
	right_wall.collision_layer = 4
	right_wall.collision_mask = 1
	var right_shape := CollisionShape2D.new()
	var right_rect := RectangleShape2D.new()
	right_rect.size = Vector2(6, cup_depth + 10)
	right_shape.shape = right_rect
	right_shape.position = Vector2(hw + 3, cup_depth / 2.0)
	right_wall.add_child(right_shape)
	add_child(right_wall)

	# Bottom wall
	var bottom_wall := StaticBody2D.new()
	bottom_wall.collision_layer = 4
	bottom_wall.collision_mask = 1
	var bottom_shape := CollisionShape2D.new()
	var bottom_rect := RectangleShape2D.new()
	bottom_rect.size = Vector2(cup_width, 6)
	bottom_shape.shape = bottom_rect
	bottom_shape.position = Vector2(0, cup_depth + 3)
	bottom_wall.add_child(bottom_shape)
	add_child(bottom_wall)


func _create_detection_area() -> void:
	var interior := Area2D.new()
	interior.collision_layer = 0
	interior.collision_mask = 1
	interior.monitoring = true

	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(cup_width - 14, cup_depth - 8)
	area_shape.shape = area_rect
	area_shape.position = Vector2(0, cup_depth / 2.0 + 2)
	interior.add_child(area_shape)
	interior.body_entered.connect(_on_ball_entered)
	add_child(interior)


func _on_ball_entered(body: Node2D) -> void:
	if body.is_in_group("ball") and body.has_method("captured"):
		body.captured(is_crit, reward_balls)
		AudioManager.play_capture()
		if is_crit:
			EventBus.spin_started.emit()
		elif is_instance_valid(RelicManager) and RelicManager.get_modifier("any_cup_triggers_slot", false):
			EventBus.spin_started.emit()
		_play_capture_effect()


func _play_capture_effect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_glow", 1.0, 0.05)
	tween.tween_property(self, "_glow", 0.0, 0.5)


func _draw() -> void:
	var hw := cup_width / 2.0
	var color := _cup_color

	# Glow
	if _glow > 0.0:
		draw_circle(
			Vector2(0, cup_depth / 2.0), cup_width * 0.8,
			Color(color.r, color.g, color.b, 0.2 * _glow), true, -1.0, true
		)

	# Cup shape (U-shape)
	var points := PackedVector2Array([
		Vector2(-hw - 4, -2),
		Vector2(-hw - 4, cup_depth),
		Vector2(-hw, cup_depth + 4),
		Vector2(hw, cup_depth + 4),
		Vector2(hw + 4, cup_depth),
		Vector2(hw + 4, -2),
	])
	draw_polyline(points, color, 2.5, true)

	# Fill
	var fill_points := PackedVector2Array([
		Vector2(-hw, 0),
		Vector2(-hw, cup_depth),
		Vector2(hw, cup_depth),
		Vector2(hw, 0),
	])
	draw_colored_polygon(fill_points, Color(color.r, color.g, color.b, 0.12))

	# Reward label
	var font := ThemeDB.fallback_font
	var font_size := 11 if label_text.length() > 2 else 14
	var text_width := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	draw_string(
		font, Vector2(-text_width / 2.0, cup_depth + 18),
		label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size,
		Color(0.9, 0.85, 0.3) if is_crit else Color(0.7, 0.7, 0.8)
	)
