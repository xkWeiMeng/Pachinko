class_name PachinkoPin
extends StaticBody2D

const PIN_RADIUS: float = 6.0
const IDLE_COLOR := Color(0.78, 0.66, 0.20)
const HIT_COLOR := Color(1.0, 1.0, 1.0)

var _flash_intensity: float = 0.0:
	set(value):
		_flash_intensity = value
		queue_redraw()


func _ready() -> void:
	add_to_group("peg")
	collision_layer = 2
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PIN_RADIUS
	shape.shape = circle
	add_child(shape)


func _draw() -> void:
	if _flash_intensity > 0.0:
		draw_circle(
			Vector2.ZERO, PIN_RADIUS * 2.5,
			Color(0.3, 0.6, 1.0, 0.25 * _flash_intensity), true, -1.0, true
		)
		draw_circle(
			Vector2.ZERO, PIN_RADIUS * 1.8,
			Color(0.5, 0.8, 1.0, 0.4 * _flash_intensity), true, -1.0, true
		)

	var current_color := IDLE_COLOR.lerp(HIT_COLOR, _flash_intensity)
	draw_circle(Vector2.ZERO, PIN_RADIUS, current_color, true, -1.0, true)

	draw_circle(
		Vector2(-PIN_RADIUS * 0.3, -PIN_RADIUS * 0.35),
		PIN_RADIUS * 0.25, Color(1.0, 1.0, 1.0, 0.4), true, -1.0, true
	)


func on_hit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_flash_intensity", 1.0, 0.02)
	tween.tween_property(self, "_flash_intensity", 0.0, 0.25)
