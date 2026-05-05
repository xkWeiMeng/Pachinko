class_name LaunchRail
extends Node2D

const CHANNEL_WIDTH: float = 24.0
const WALL_THICKNESS: float = 6.0
const DEFLECT_LENGTH: float = 40.0
const DEFLECTOR_ANGLE := PI / 4.0
const CAP_EXTEND: float = 50.0

const WALL_COLOR := Color(0.3, 0.3, 0.4)
const WALL_HIGHLIGHT := Color(0.5, 0.5, 0.6)
const WALL_SHADOW := Color(0.15, 0.15, 0.22)
const CHANNEL_BG := Color(0.02, 0.0, 0.04)

var channel_top: float = 100.0
var channel_bottom: float = 850.0

# Cached deflector geometry (computed once in _ready)
var _deflect_dir: Vector2
var _cap_top_y: float
var _outer_start: Vector2
var _outer_end: Vector2
var _inner_start: Vector2
var _inner_end: Vector2
var _tip: Vector2


func _ready() -> void:
	var half_w := CHANNEL_WIDTH / 2.0
	_cap_top_y = channel_top - CAP_EXTEND
	_deflect_dir = Vector2(-1.0, -1.0).normalized()

	# Compute deflector band geometry — starts flush at right wall top
	_outer_start = Vector2(half_w + WALL_THICKNESS, _cap_top_y)
	_inner_start = Vector2(half_w, _cap_top_y)
	_outer_end = _outer_start + _deflect_dir * DEFLECT_LENGTH
	_inner_end = _inner_start + _deflect_dir * DEFLECT_LENGTH
	_tip = (_outer_end + _inner_end) / 2.0 + _deflect_dir * 3.0

	var channel_height := channel_bottom - channel_top

	# Left wall — from channel_top to channel_bottom
	_create_rail_wall("rail_left",
		Vector2(-half_w - WALL_THICKNESS / 2.0, (channel_top + channel_bottom) / 2.0),
		Vector2(WALL_THICKNESS, channel_height))

	# Right wall — extends above channel_top to meet deflector
	_create_rail_wall("rail_right",
		Vector2(half_w + WALL_THICKNESS / 2.0, (_cap_top_y + channel_bottom) / 2.0),
		Vector2(WALL_THICKNESS, channel_bottom - _cap_top_y))

	# Deflector collision body — centered on the deflector band midline
	var band_mid_start := (_outer_start + _inner_start) / 2.0
	var band_mid_end := (_outer_end + _inner_end) / 2.0
	var deflector_center := (band_mid_start + band_mid_end) / 2.0
	_create_deflector(deflector_center)


func _create_rail_wall(wall_name: String, pos: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = pos
	wall.collision_layer = 4
	wall.collision_mask = 1

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.3
	mat.friction = 0.1
	wall.physics_material_override = mat

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)


func _create_deflector(center: Vector2) -> void:
	var deflector := StaticBody2D.new()
	deflector.name = "deflector"
	deflector.position = center
	deflector.rotation = DEFLECTOR_ANGLE
	deflector.collision_layer = 4
	deflector.collision_mask = 1

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.3
	mat.friction = 0.1
	deflector.physics_material_override = mat

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(DEFLECT_LENGTH, WALL_THICKNESS)
	shape.shape = rect
	deflector.add_child(shape)
	add_child(deflector)


func get_spawn_position() -> Vector2:
	return global_position + Vector2(0.0, channel_bottom - 20.0)


func _draw() -> void:
	var half_w := CHANNEL_WIDTH / 2.0
	var h := channel_bottom - channel_top

	# Channel background (dark interior)
	draw_rect(Rect2(-half_w, channel_top, CHANNEL_WIDTH, h), CHANNEL_BG)

	# Left wall — metallic shading
	var lx := -half_w - WALL_THICKNESS
	draw_rect(Rect2(lx, channel_top, WALL_THICKNESS, h), WALL_COLOR)
	draw_rect(Rect2(lx, channel_top, 1.0, h), WALL_HIGHLIGHT)
	draw_rect(Rect2(lx + WALL_THICKNESS - 1.0, channel_top, 1.0, h), WALL_SHADOW)

	# Right wall body (channel_top to channel_bottom)
	var rx := half_w
	draw_rect(Rect2(rx, channel_top, WALL_THICKNESS, h), WALL_COLOR)
	draw_rect(Rect2(rx, channel_top, 1.0, h), WALL_SHADOW)
	draw_rect(Rect2(rx + WALL_THICKNESS - 1.0, channel_top, 1.0, h), WALL_HIGHLIGHT)

	# Integrated right wall cap + deflector — one continuous polygon
	_draw_integrated_cap()


func _draw_integrated_cap() -> void:
	var half_w := CHANNEL_WIDTH / 2.0

	# Single polygon: right wall extension + deflector band + pointed tip
	var cap := PackedVector2Array([
		Vector2(half_w + WALL_THICKNESS, channel_top),  # right wall outer at channel_top
		_outer_start,                                     # right wall outer top
		_outer_end,                                       # deflector outer end
		_tip,                                             # pointed tip
		_inner_end,                                       # deflector inner end
		_inner_start,                                     # right wall inner top
		Vector2(half_w, channel_top),                     # right wall inner at channel_top
	])
	draw_colored_polygon(cap, WALL_COLOR)

	# Highlight on outer edge (right side of cap + upper edge of deflector)
	draw_line(Vector2(half_w + WALL_THICKNESS, channel_top), _outer_start, WALL_HIGHLIGHT, 1.0)
	draw_line(_outer_start, _outer_end, WALL_HIGHLIGHT, 1.0)
	draw_line(_outer_end, _tip, WALL_HIGHLIGHT, 1.0)

	# Shadow on inner edge (left side of cap + lower edge of deflector)
	draw_line(Vector2(half_w, channel_top), _inner_start, WALL_SHADOW, 1.0)
	draw_line(_inner_start, _inner_end, WALL_SHADOW, 1.0)
	draw_line(_inner_end, _tip, WALL_SHADOW, 1.0)
