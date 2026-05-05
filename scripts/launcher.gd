class_name PachinkoLauncher
extends Node2D

const BallScript = preload("res://scripts/ball.gd")

@export var max_strength: float = 3200.0
@export var fire_rate: float = 0.4

var _power: float = 0.0
var _can_fire: bool = true
var _fire_timer: float = 0.0
var _balls_container: Node2D
var _touch_charging: bool = false

const LAUNCH_DIR := Vector2(0.0, -1.0)
const LAUNCHER_COLOR := Color(0.4, 0.4, 0.5)
const POWER_BAR_OFFSET_X: float = -28.0


func setup(balls_container: Node2D) -> void:
	_balls_container = balls_container


func start_touch_charge() -> void:
	_touch_charging = true


func stop_touch_charge() -> void:
	_touch_charging = false


func _process(delta: float) -> void:
	if GameState.current_phase != GameState.Phase.PLAYING:
		return

	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_can_fire = true

	if Input.is_action_pressed("launch") or _touch_charging:
		_power = minf(_power + delta * 3.0, 1.0)
	elif _power > 0.05:
		_fire()
		_power = 0.0
	else:
		_power = 0.0

	queue_redraw()


func _fire() -> void:
	if not _can_fire or not _balls_container:
		return
	if GameState.balls_remaining <= 0:
		return

	var ball = BallScript.new()
	ball.global_position = global_position + Vector2(0, -20)
	_balls_container.add_child(ball)

	# Set velocity directly — apply_central_impulse may be lost on first frame
	# Minimum power 0.65 ensures ball clears the rail and reaches the deflector
	var effective_power := maxf(_power, 0.65)
	ball.linear_velocity = LAUNCH_DIR.normalized() * max_strength * effective_power

	AudioManager.play_launch()
	EventBus.ball_launched.emit(ball)
	GameState.use_ball()

	_can_fire = false
	_fire_timer = fire_rate


func _draw() -> void:
	# Launcher base (plunger inside the rail channel)
	draw_rect(Rect2(-8, -25, 16, 50), LAUNCHER_COLOR)

	# Power bar — beside the rail (to the left)
	draw_rect(Rect2(POWER_BAR_OFFSET_X, -25, 8, 50), Color(0.15, 0.15, 0.2))

	if _power > 0.0:
		var bar_height := 48.0 * _power
		var bar_color := Color(1.0, 0.3, 0.1).lerp(Color(0.1, 1.0, 0.3), _power)
		draw_rect(Rect2(POWER_BAR_OFFSET_X + 1, 25 - bar_height, 6, bar_height), bar_color)
