class_name BoardWalls
extends Node2D

const WALL_COLOR := Color(0.25, 0.25, 0.35)
const WALL_THICKNESS: float = 10.0

var board_width: float = 540.0
var board_height: float = 960.0


func _ready() -> void:
	_create_wall("left", Vector2(WALL_THICKNESS / 2.0, board_height / 2.0),
		Vector2(WALL_THICKNESS, board_height))
	_create_wall("right", Vector2(board_width - WALL_THICKNESS / 2.0, board_height / 2.0),
		Vector2(WALL_THICKNESS, board_height))
	_create_wall("top", Vector2(board_width / 2.0, WALL_THICKNESS / 2.0),
		Vector2(board_width, WALL_THICKNESS))


func _create_wall(wall_name: String, pos: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = pos
	wall.collision_layer = 4  # walls on layer 3 mask bit
	wall.collision_mask = 1   # detect balls on layer 1

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.0
	mat.friction = 0.1
	wall.physics_material_override = mat

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)


func _draw() -> void:
	draw_rect(Rect2(0, 0, WALL_THICKNESS, board_height), WALL_COLOR)
	draw_rect(Rect2(board_width - WALL_THICKNESS, 0, WALL_THICKNESS, board_height), WALL_COLOR)
	draw_rect(Rect2(0, 0, board_width, WALL_THICKNESS), WALL_COLOR)
