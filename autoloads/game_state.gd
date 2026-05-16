extends Node

signal score_changed(new_score: int)
signal balls_changed(remaining: int)
signal game_over

enum Phase { TITLE, PLAYING, GAME_OVER }

var current_phase: Phase = Phase.TITLE
var score: int = 0
var balls_remaining: int = 0
var high_score: int = 0

# Roguelike state
var combo_count: int = 0
var total_captures: int = 0
var total_jackpots: int = 0
var balls_cap: int = 150
var free_ball_counter: int = 0
var roguelike_mode: bool = false
var _floor_score: int = 0
var floor_balls_lost: int = 0

# Elite modifier state
var wind_force: float = 0.0
var hot_pins: Array[Node2D] = []
var active_modifiers: Array[Dictionary] = []

const STARTING_BALLS: int = 100
const NORMAL_CAPTURE_REWARD: int = 15
const CRIT_CAPTURE_REWARD: int = 30
const JACKPOT_REWARD: int = 100


func _ready() -> void:
	EventBus.ball_captured.connect(_on_ball_captured)
	EventBus.ball_lost.connect(_on_ball_lost)
	EventBus.jackpot_hit.connect(_on_jackpot)
	_load_high_score()


func start_game(starting_balls: int = STARTING_BALLS, cap: int = 9999) -> void:
	score = 0
	balls_remaining = starting_balls
	balls_cap = cap
	current_phase = Phase.PLAYING
	combo_count = 0
	total_captures = 0
	total_jackpots = 0
	free_ball_counter = 0
	_floor_score = 0
	score_changed.emit(score)
	balls_changed.emit(balls_remaining)


func start_floor(starting_balls: int, cap: int) -> void:
	roguelike_mode = true
	score = 0
	_floor_score = 0
	floor_balls_lost = 0
	balls_remaining = starting_balls
	balls_cap = cap
	current_phase = Phase.PLAYING
	combo_count = 0
	total_captures = 0
	free_ball_counter = 0
	wind_force = 0.0
	hot_pins.clear()
	active_modifiers.clear()
	score_changed.emit(score)
	balls_changed.emit(balls_remaining)


func get_floor_stats() -> Dictionary:
	return {
		"captures": total_captures,
		"jackpots": total_jackpots,
		"score": score,
	}


func add_score(points: int) -> void:
	score += points
	_floor_score += points
	score_changed.emit(score)
	if roguelike_mode:
		EventBus.floor_objective_updated.emit(score, 0, "score")


func use_ball() -> void:
	# Check free ball relic
	if roguelike_mode:
		var free_every: int = RelicManager.get_modifier("free_ball_every", 0)
		if free_every > 0:
			free_ball_counter += 1
			if free_ball_counter >= free_every:
				free_ball_counter = 0
				return  # Free ball — don't consume

	balls_remaining -= 1
	balls_changed.emit(balls_remaining)
	if balls_remaining <= 0:
		_check_game_over()


func add_balls(count: int) -> void:
	balls_remaining = mini(balls_remaining + count, balls_cap) if roguelike_mode else balls_remaining + count
	balls_changed.emit(balls_remaining)


func _on_ball_captured(reward: int, is_crit: bool, _ball: RigidBody2D) -> void:
	combo_count += 1
	total_captures += 1
	add_balls(reward)

	var bonus_score: int = 0
	if roguelike_mode:
		bonus_score = RelicManager.get_modifier("capture_bonus_score", 0)
		if RelicManager.get_modifier("combo_enabled", false):
			EventBus.combo_updated.emit(combo_count)
	add_score(reward * 10 + bonus_score)


func _on_ball_lost(_ball: RigidBody2D) -> void:
	combo_count = 0
	floor_balls_lost += 1
	_check_game_over()


func _on_jackpot() -> void:
	total_jackpots += 1
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
