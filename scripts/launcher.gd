class_name PachinkoLauncher
extends Node2D

const BallScript = preload("res://scripts/ball.gd")

@export var max_strength: float = 2000.0
@export var fire_rate: float = 0.4

var _power: float = 0.0
var _can_fire: bool = true
var _fire_timer: float = 0.0
var _balls_container: Node2D

const LAUNCH_DIR := Vector2(-0.15, -1.0)
const LAUNCHER_COLOR := Color(0.4, 0.4, 0.5)


func setup(balls_container: Node2D) -> void:
	_balls_container = balls_container


func _process(delta: float) -> void:
	if GameState.current_phase != GameState.Phase.PLAYING:
		return

	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_can_fire = true

	if Input.is_action_pressed("launch"):
		_power = minf(_power + delta * 2.0, 1.0)
	elif _power > 0.1:
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
	ball.global_position = global_position + Vector2(-20, -30)
	_balls_container.add_child(ball)

	var force := LAUNCH_DIR.normalized() * max_strength * _power
	ball.apply_central_impulse(force)

	EventBus.ball_launched.emit(ball)
	GameState.use_ball()

	_can_fire = false
	_fire_timer = fire_rate


func _draw() -> void:
	# Launcher base
	draw_rect(Rect2(-8, -25, 16, 50), LAUNCHER_COLOR)

	# Power bar background
	draw_rect(Rect2(-4, -55, 8, 28), Color(0.2, 0.2, 0.2))

	# Power bar fill
	if _power > 0.0:
		var bar_height := 26.0 * _power
		var bar_color := Color(1.0, 0.3, 0.1).lerp(Color(0.1, 1.0, 0.3), _power)
		draw_rect(Rect2(-3, -28 - bar_height + 1, 6, bar_height), bar_color)
