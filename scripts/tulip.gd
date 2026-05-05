class_name PachinkoTulip
extends Node2D

enum State { CLOSED, OPEN }

const FLAP_WIDTH: float = 4.0
const FLAP_HEIGHT: float = 25.0
const CLOSED_ANGLE: float = 30.0   # degrees — flaps form ∧
const OPEN_ANGLE: float = 45.0     # degrees — flaps form V
const OPEN_DURATION: float = 5.0
const TWEEN_DURATION: float = 0.2

const CLOSED_COLOR := Color(0.0, 0.75, 0.75)
const OPEN_COLOR := Color(0.2, 1.0, 0.3)
const CATCH_POINT_COLOR := Color(0.0, 0.9, 0.9)

var _state: int = State.CLOSED
var _left_flap: StaticBody2D
var _right_flap: StaticBody2D
var _catch_area: Area2D
var _glow_pulse: float = 0.0
var _open_timer: SceneTreeTimer
var _flap_tween: Tween

var _left_angle: float = deg_to_rad(CLOSED_ANGLE):
	set(value):
		_left_angle = value
		if _left_flap:
			_left_flap.rotation = value
		queue_redraw()

var _right_angle: float = deg_to_rad(-CLOSED_ANGLE):
	set(value):
		_right_angle = value
		if _right_flap:
			_right_flap.rotation = value
		queue_redraw()


func _ready() -> void:
	_create_flaps()
	_create_catch_area()
	_set_closed_angles()


func _create_flaps() -> void:
	var phys_mat := PhysicsMaterial.new()
	phys_mat.bounce = 0.2

	# Left flap — pivot at top-left
	_left_flap = StaticBody2D.new()
	_left_flap.collision_layer = 4
	_left_flap.collision_mask = 1
	_left_flap.physics_material_override = phys_mat
	_left_flap.position = Vector2(-2, 0)

	var left_shape := CollisionShape2D.new()
	var left_rect := RectangleShape2D.new()
	left_rect.size = Vector2(FLAP_WIDTH, FLAP_HEIGHT)
	left_shape.shape = left_rect
	left_shape.position = Vector2(0, FLAP_HEIGHT / 2.0)
	_left_flap.add_child(left_shape)
	add_child(_left_flap)

	# Right flap — pivot at top-right
	_right_flap = StaticBody2D.new()
	_right_flap.collision_layer = 4
	_right_flap.collision_mask = 1
	_right_flap.physics_material_override = phys_mat
	_right_flap.position = Vector2(2, 0)

	var right_shape := CollisionShape2D.new()
	var right_rect := RectangleShape2D.new()
	right_rect.size = Vector2(FLAP_WIDTH, FLAP_HEIGHT)
	right_shape.shape = right_rect
	right_shape.position = Vector2(0, FLAP_HEIGHT / 2.0)
	_right_flap.add_child(right_shape)
	add_child(_right_flap)


func _create_catch_area() -> void:
	_catch_area = Area2D.new()
	_catch_area.collision_layer = 0
	_catch_area.collision_mask = 1
	_catch_area.monitoring = true

	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(20, 12)
	area_shape.shape = area_rect
	area_shape.position = Vector2(0, FLAP_HEIGHT + 4)
	_catch_area.add_child(area_shape)
	_catch_area.body_entered.connect(_on_ball_entered)
	add_child(_catch_area)


func _set_closed_angles() -> void:
	_left_angle = deg_to_rad(CLOSED_ANGLE)
	_right_angle = deg_to_rad(-CLOSED_ANGLE)


func _set_open_angles() -> void:
	_left_angle = deg_to_rad(-OPEN_ANGLE)
	_right_angle = deg_to_rad(OPEN_ANGLE)


func open() -> void:
	if _state == State.OPEN:
		# Reset timer if already open
		if _open_timer and _open_timer.time_left > 0:
			_open_timer.timeout.disconnect(_close)
		_open_timer = get_tree().create_timer(OPEN_DURATION)
		_open_timer.timeout.connect(_close)
		return

	_state = State.OPEN
	_animate_to_open()

	_open_timer = get_tree().create_timer(OPEN_DURATION)
	_open_timer.timeout.connect(_close)


func _close() -> void:
	_state = State.CLOSED
	_animate_to_closed()
	_glow_pulse = 0.0
	queue_redraw()


func _animate_to_open() -> void:
	if _flap_tween and _flap_tween.is_valid():
		_flap_tween.kill()
	_flap_tween = create_tween().set_parallel(true)
	_flap_tween.tween_property(self, "_left_angle", deg_to_rad(-OPEN_ANGLE), TWEEN_DURATION)
	_flap_tween.tween_property(self, "_right_angle", deg_to_rad(OPEN_ANGLE), TWEEN_DURATION)


func _animate_to_closed() -> void:
	if _flap_tween and _flap_tween.is_valid():
		_flap_tween.kill()
	_flap_tween = create_tween().set_parallel(true)
	_flap_tween.tween_property(self, "_left_angle", deg_to_rad(CLOSED_ANGLE), TWEEN_DURATION)
	_flap_tween.tween_property(self, "_right_angle", deg_to_rad(-CLOSED_ANGLE), TWEEN_DURATION)


func _on_ball_entered(body: Node2D) -> void:
	if _state != State.OPEN:
		return
	if body.is_in_group("ball") and body.has_method("captured"):
		body.captured(true)
		_play_capture_effect()


func _play_capture_effect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_glow_pulse", 1.0, 0.05)
	tween.tween_property(self, "_glow_pulse", 0.0, 0.5)


func _process(_delta: float) -> void:
	if _state == State.OPEN:
		_glow_pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		queue_redraw()


func _draw() -> void:
	var is_open := _state == State.OPEN

	# Flap lines
	var left_end := Vector2(-2, 0) + Vector2(0, FLAP_HEIGHT).rotated(_left_angle)
	var right_end := Vector2(2, 0) + Vector2(0, FLAP_HEIGHT).rotated(_right_angle)
	var flap_color := OPEN_COLOR if is_open else CLOSED_COLOR
	draw_line(Vector2(-2, 0), left_end, flap_color, 3.0, true)
	draw_line(Vector2(2, 0), right_end, flap_color, 3.0, true)

	# Catch point circle
	var catch_y := FLAP_HEIGHT + 4
	draw_circle(Vector2(0, catch_y), 4.0, CATCH_POINT_COLOR)

	# Glow effects when open
	if is_open and _glow_pulse > 0.0:
		draw_circle(
			Vector2(0, catch_y), 12.0,
			Color(OPEN_COLOR.r, OPEN_COLOR.g, OPEN_COLOR.b, 0.25 * _glow_pulse), true, -1.0, true
		)
		draw_circle(
			Vector2(0, catch_y), 20.0,
			Color(OPEN_COLOR.r, OPEN_COLOR.g, OPEN_COLOR.b, 0.1 * _glow_pulse), true, -1.0, true
		)
		# Glow on flap tips
		draw_circle(left_end, 3.0, Color(OPEN_COLOR.r, OPEN_COLOR.g, OPEN_COLOR.b, 0.4 * _glow_pulse), true, -1.0, true)
		draw_circle(right_end, 3.0, Color(OPEN_COLOR.r, OPEN_COLOR.g, OPEN_COLOR.b, 0.4 * _glow_pulse), true, -1.0, true)
