extends Node

## Run Lifecycle Manager — core roguelike run state machine.

signal run_started
signal floor_started(floor_num: int, config: Dictionary)
signal floor_cleared(floor_num: int)
signal run_ended(won: bool, stats: Dictionary)
signal phase_changed(new_phase: int)

enum RunPhase {
	NONE, STARTING, MAP_SELECT, PLAYING_FLOOR, FLOOR_CLEARED,
	RELIC_SELECT, SHOP, EVENT, REST, BOSS, RUN_WON, RUN_LOST,
}

const BoardGeneratorScript = preload("res://scripts/roguelike/board_generator.gd")
const MapGeneratorScript = preload("res://scripts/roguelike/map_generator.gd")
const FloorObjectiveScript = preload("res://scripts/roguelike/floor_objective.gd")

var current_phase: RunPhase = RunPhase.NONE
var current_act: int = 1
var current_floor: int = 1
var total_floors_cleared: int = 0
var ball_pool: int = 60
var ball_cap: int = 150
var run_score: int = 0
var collected_relics: Array[String] = []
var run_map: Array[Array] = []
var current_layer_idx: int = 0
var current_node_idx: int = 0
var rng: RandomNumberGenerator
var run_stats: Dictionary = {}

var _current_objective: RefCounted = null  # FloorObjective


func _ready() -> void:
	EventBus.floor_cleared.connect(_on_floor_cleared)


func start_run() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

	current_phase = RunPhase.STARTING
	current_act = 1
	current_floor = 1
	total_floors_cleared = 0
	ball_pool = 60
	ball_cap = 150
	run_score = 0
	collected_relics.clear()
	run_stats = {
		"total_captures": 0,
		"total_jackpots": 0,
		"floors_cleared": 0,
		"relics_collected": 0,
	}

	RelicManager.reset()

	# Generate the run map
	run_map = MapGeneratorScript.generate_map(rng)
	current_layer_idx = 0
	current_node_idx = -1

	_set_phase(RunPhase.MAP_SELECT)
	run_started.emit()
	EventBus.run_started.emit()


func select_map_node(layer_idx: int, node_idx: int) -> void:
	if layer_idx != current_layer_idx:
		return
	if node_idx < 0 or node_idx >= run_map[layer_idx].size():
		return

	current_node_idx = node_idx
	var node: Dictionary = run_map[layer_idx][node_idx]
	current_floor = node["floor_num"]
	current_act = node["act"]

	var node_type: int = node["type"]
	match node_type:
		MapGeneratorScript.NodeType.NORMAL, MapGeneratorScript.NodeType.ELITE, MapGeneratorScript.NodeType.BOSS:
			_start_floor(node)
		MapGeneratorScript.NodeType.SHOP:
			_set_phase(RunPhase.SHOP)
		MapGeneratorScript.NodeType.EVENT:
			_set_phase(RunPhase.EVENT)
		MapGeneratorScript.NodeType.REST:
			_set_phase(RunPhase.REST)
			# Rest: heal 10 balls
			ball_pool = mini(ball_pool + 10, ball_cap)


func _start_floor(node: Dictionary) -> void:
	var is_elite: bool = node.get("is_elite", false)
	var is_boss: bool = node["type"] == MapGeneratorScript.NodeType.BOSS
	var config := BoardGeneratorScript.generate(current_floor, current_act, is_elite or is_boss, rng)

	# Generate objective
	_current_objective = FloorObjectiveScript.generate(current_floor, current_act, rng)
	_current_objective.start()

	if is_boss:
		_set_phase(RunPhase.BOSS)
	else:
		_set_phase(RunPhase.PLAYING_FLOOR)

	floor_started.emit(current_floor, config)
	EventBus.floor_started.emit(current_floor, config)


func get_current_objective() -> RefCounted:
	return _current_objective


func complete_floor() -> void:
	if current_layer_idx < run_map.size():
		var node: Dictionary = run_map[current_layer_idx][current_node_idx]
		node["cleared"] = true

	total_floors_cleared += 1
	run_stats["floors_cleared"] = total_floors_cleared

	# Collect remaining balls back to pool
	var floor_stats: Dictionary = GameState.get_floor_stats()
	run_score += floor_stats.get("score", 0)
	run_stats["total_captures"] += floor_stats.get("captures", 0)
	run_stats["total_jackpots"] += floor_stats.get("jackpots", 0)
	ball_pool = mini(GameState.balls_remaining, ball_cap)

	_set_phase(RunPhase.FLOOR_CLEARED)
	floor_cleared.emit(current_floor)
	EventBus.floor_cleared.emit(current_floor)

	# Check if run is won
	if current_layer_idx >= run_map.size() - 1:
		end_run(true)
		return

	# Move to relic selection
	_set_phase(RunPhase.RELIC_SELECT)


func advance_to_next_floor() -> void:
	current_layer_idx += 1
	if current_layer_idx >= run_map.size():
		end_run(true)
		return
	_set_phase(RunPhase.MAP_SELECT)


func end_run(won: bool) -> void:
	run_stats["final_score"] = run_score
	run_stats["balls_remaining"] = ball_pool
	run_stats["relics_collected"] = collected_relics.size()
	run_stats["relics"] = collected_relics.duplicate()

	if won:
		_set_phase(RunPhase.RUN_WON)
	else:
		_set_phase(RunPhase.RUN_LOST)

	run_ended.emit(won, run_stats)
	EventBus.run_ended.emit(won, run_stats)


func on_relic_selected(relic_id: String) -> void:
	RelicManager.add_relic(relic_id)
	collected_relics.append(relic_id)
	run_stats["relics_collected"] = collected_relics.size()
	advance_to_next_floor()


func on_relic_skipped() -> void:
	advance_to_next_floor()


func skip_non_combat_node() -> void:
	# For shop/event/rest: mark as cleared and move on
	if current_layer_idx < run_map.size() and current_node_idx >= 0:
		var node: Dictionary = run_map[current_layer_idx][current_node_idx]
		node["cleared"] = true
		total_floors_cleared += 1
		run_stats["floors_cleared"] = total_floors_cleared
	advance_to_next_floor()


func _set_phase(new_phase: RunPhase) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)


func is_active() -> bool:
	return current_phase != RunPhase.NONE
