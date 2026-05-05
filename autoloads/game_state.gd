extends Node

signal score_changed(new_score: int)
signal balls_changed(remaining: int)
signal game_over

enum Phase { TITLE, PLAYING, GAME_OVER }

var current_phase: Phase = Phase.TITLE
var score: int = 0
var balls_remaining: int = 0
var high_score: int = 0

const STARTING_BALLS: int = 100
const NORMAL_CAPTURE_REWARD: int = 15
const CRIT_CAPTURE_REWARD: int = 30
const JACKPOT_REWARD: int = 100


func _ready() -> void:
	EventBus.ball_captured.connect(_on_ball_captured)
	EventBus.ball_lost.connect(_on_ball_lost)
	EventBus.jackpot_hit.connect(_on_jackpot)
	_load_high_score()


func start_game() -> void:
	score = 0
	balls_remaining = STARTING_BALLS
	current_phase = Phase.PLAYING
	score_changed.emit(score)
	balls_changed.emit(balls_remaining)


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func use_ball() -> void:
	balls_remaining -= 1
	balls_changed.emit(balls_remaining)
	if balls_remaining <= 0:
		_check_game_over()


func add_balls(count: int) -> void:
	balls_remaining += count
	balls_changed.emit(balls_remaining)


func _on_ball_captured(is_crit: bool, _ball: RigidBody2D) -> void:
	var reward := CRIT_CAPTURE_REWARD if is_crit else NORMAL_CAPTURE_REWARD
	add_balls(reward)
	add_score(reward * 10)


func _on_ball_lost(_ball: RigidBody2D) -> void:
	_check_game_over()


func _on_jackpot() -> void:
	add_balls(JACKPOT_REWARD)
	add_score(JACKPOT_REWARD * 100)


func _check_game_over() -> void:
	if balls_remaining <= 0:
		# Deferred check: ball may still be in group during current frame
		call_deferred("_deferred_game_over_check")


func _deferred_game_over_check() -> void:
	if balls_remaining <= 0:
		var active_balls := get_tree().get_nodes_in_group("ball")
		if active_balls.is_empty():
			_end_game()


func _end_game() -> void:
	if score > high_score:
		high_score = score
		_save_high_score()
	current_phase = Phase.GAME_OVER
	game_over.emit()
	EventBus.game_over.emit()


func _load_high_score() -> void:
	var save := ConfigFile.new()
	if save.load("user://save.cfg") == OK:
		high_score = save.get_value("game", "high_score", 0)


func _save_high_score() -> void:
	var save := ConfigFile.new()
	save.set_value("game", "high_score", high_score)
	save.save("user://save.cfg")
