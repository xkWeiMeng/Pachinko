class_name PachinkoBall
extends RigidBody2D

const RADIUS: float = 8.0
const BALL_COLOR := Color(0.85, 0.85, 0.92)
const HIGHLIGHT_COLOR := Color(1.0, 1.0, 1.0, 0.65)
const COLLISION_THRESHOLD: float = 200.0
const TRAIL_LENGTH: int = 6

var _trail_positions: Array[Vector2] = []


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	can_sleep = false
	z_index = 3
	add_to_group("ball")

	collision_layer = 1
	collision_mask = 0b1111

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.8
	mat.friction = 0.1
	physics_material_override = mat

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	_trail_positions.push_front(global_position)
	if _trail_positions.size() > TRAIL_LENGTH:
		_trail_positions.resize(TRAIL_LENGTH)
	queue_redraw()


func _draw() -> void:
	# Trail
	for i in range(_trail_positions.size()):
		var alpha := 0.3 * (1.0 - float(i) / TRAIL_LENGTH)
		var trail_pos := _trail_positions[i] - global_position
		draw_circle(trail_pos, RADIUS * 0.7, Color(0.85, 0.85, 0.92, alpha))
	# Ball
	draw_circle(Vector2(1.5, 2.0), RADIUS, Color(0.0, 0.0, 0.0, 0.3))
	draw_circle(Vector2.ZERO, RADIUS, BALL_COLOR, true, -1.0, true)
	draw_circle(
		Vector2(-RADIUS * 0.28, -RADIUS * 0.3), RADIUS * 0.38,
		HIGHLIGHT_COLOR, true, -1.0, true
	)
	draw_circle(
		Vector2(-RADIUS * 0.42, -RADIUS * 0.44), RADIUS * 0.12,
		Color(1.0, 1.0, 1.0, 0.9), true, -1.0, true
	)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("peg"):
		EventBus.peg_hit.emit(body, self)
		AudioManager.play_pin_hit(randf_range(0.8, 1.2))


func captured(is_crit: bool, reward: int = 15) -> void:
	EventBus.ball_captured.emit(reward, is_crit, self)
	queue_free()


func lost() -> void:
	EventBus.ball_lost.emit(self)
	queue_free()
