class_name StartChacker
extends Node2D

## Central "START チャッカー" — small opening that rewards balls and triggers
## tulip trigger pins to glow. Narrower than regular cups.

@export var opening_width: float = 30.0
@export var depth: float = 20.0
@export var reward_balls: int = 3

const CHACKER_COLOR := Color(0.9, 0.2, 0.55)

var _glow: float = 0.0:
	set(value):
		_glow = value
		queue_redraw()


func _ready() -> void:
	_create_physics()
	_create_detection()


func _create_physics() -> void:
	var hw := opening_width / 2.0

	# Left funnel wall (angled slightly outward)
	var left := StaticBody2D.new()
	left.collision_layer = 4
	left.collision_mask = 1
	left.rotation = -0.15
	var ls := CollisionShape2D.new()
	var lr := RectangleShape2D.new()
	lr.size = Vector2(4, depth + 8)
	ls.shape = lr
	ls.position = Vector2(0, depth / 2.0)
	left.add_child(ls)
	left.position = Vector2(-hw - 2, 0)
	add_child(left)

	# Right funnel wall
	var right := StaticBody2D.new()
	right.collision_layer = 4
	right.collision_mask = 1
	right.rotation = 0.15
	var rs := CollisionShape2D.new()
	var rr := RectangleShape2D.new()
	rr.size = Vector2(4, depth + 8)
	rs.shape = rr
	rs.position = Vector2(0, depth / 2.0)
	right.add_child(rs)
	right.position = Vector2(hw + 2, 0)
	add_child(right)

	# Bottom
	var bottom := StaticBody2D.new()
	bottom.collision_layer = 4
	bottom.collision_mask = 1
	var bs := CollisionShape2D.new()
	var br := RectangleShape2D.new()
	br.size = Vector2(opening_width + 8, 4)
	bs.shape = br
	bs.position = Vector2(0, depth + 2)
	bottom.add_child(bs)
	add_child(bottom)


func _create_detection() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(opening_width - 6, depth - 4)
	shape.shape = rect
	shape.position = Vector2(0, depth / 2.0 + 1)
	area.add_child(shape)
	area.body_entered.connect(_on_ball_entered)
	add_child(area)


func _on_ball_entered(body: Node2D) -> void:
	if body.is_in_group("ball") and body.has_method("captured"):
		body.captured(false, reward_balls)
		AudioManager.play_capture()
		_play_effect()


func _play_effect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_glow", 1.0, 0.05)
	tween.tween_property(self, "_glow", 0.0, 0.4)


func _draw() -> void:
	var hw := opening_width / 2.0

	if _glow > 0.0:
		draw_circle(
			Vector2(0, depth / 2.0), opening_width * 0.6,
			Color(CHACKER_COLOR.r, CHACKER_COLOR.g, CHACKER_COLOR.b, 0.3 * _glow),
			true, -1.0, true
		)

	# Funnel shape
	var points := PackedVector2Array([
		Vector2(-hw - 8, -4),
		Vector2(-hw - 2, depth),
		Vector2(-hw + 2, depth + 4),
		Vector2(hw - 2, depth + 4),
		Vector2(hw + 2, depth),
		Vector2(hw + 8, -4),
	])
	draw_polyline(points, CHACKER_COLOR, 2.0, true)

	# Fill
	var fill := PackedVector2Array([
		Vector2(-hw, 0),
		Vector2(-hw, depth),
		Vector2(hw, depth),
		Vector2(hw, 0),
	])
	draw_colored_polygon(fill, Color(CHACKER_COLOR.r, CHACKER_COLOR.g, CHACKER_COLOR.b, 0.1))

	# "START" label
	var font := ThemeDB.fallback_font
	draw_string(
		font, Vector2(-16, depth + 16),
		"START", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0.9, 0.5, 0.7)
	)
