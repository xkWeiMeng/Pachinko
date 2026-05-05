class_name PachinkoCup
extends Node2D

@export var is_crit: bool = false
@export var cup_width: float = 50.0
@export var cup_depth: float = 35.0

const NORMAL_COLOR := Color(0.12, 0.56, 1.0)
const CRIT_COLOR := Color(1.0, 0.27, 0.0)

var _glow: float = 0.0:
	set(value):
		_glow = value
		queue_redraw()


func _ready() -> void:
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
		body.captured(is_crit)
		if is_crit:
			EventBus.spin_started.emit()
		_play_capture_effect()


func _play_capture_effect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_glow", 1.0, 0.05)
	tween.tween_property(self, "_glow", 0.0, 0.5)


func _draw() -> void:
	var hw := cup_width / 2.0
	var color := CRIT_COLOR if is_crit else NORMAL_COLOR

	# Glow
	if _glow > 0.0:
		draw_circle(
			Vector2(0, cup_depth / 2.0), cup_width * 0.8,
			Color(color.r, color.g, color.b, 0.2 * _glow), true, -1.0, true
		)

	# Cup shape (U-shape)
	var points := PackedVector2Array([
		Vector2(-hw - 6, -2),
		Vector2(-hw - 6, cup_depth),
		Vector2(-hw, cup_depth + 6),
		Vector2(hw, cup_depth + 6),
		Vector2(hw + 6, cup_depth),
		Vector2(hw + 6, -2),
	])
	draw_polyline(points, color, 3.0, true)

	# Fill
	var fill_points := PackedVector2Array([
		Vector2(-hw, 0),
		Vector2(-hw, cup_depth),
		Vector2(hw, cup_depth),
		Vector2(hw, 0),
	])
	draw_colored_polygon(fill_points, Color(color.r, color.g, color.b, 0.15))

	# Label
	if is_crit:
		draw_string(
			ThemeDB.fallback_font, Vector2(-10, cup_depth + 22),
			"★", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1.0, 0.85, 0.0)
		)
