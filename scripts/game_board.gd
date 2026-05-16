extends Node2D

const BoardWallsScript = preload("res://scripts/walls.gd")
const PinGridScript = preload("res://scripts/pin_grid.gd")
const PinScript = preload("res://scripts/pin.gd")
const LauncherScript = preload("res://scripts/launcher.gd")
const RailScript = preload("res://scripts/rail.gd")
const DrainScript = preload("res://scripts/drain.gd")
const CupScript = preload("res://scripts/cup.gd")
const SlotsScript = preload("res://scripts/slots.gd")
const HUDScript = preload("res://scripts/hud.gd")
const TulipScript = preload("res://scripts/tulip.gd")
const StartChackerScript = preload("res://scripts/start_chacker.gd")
const ParticleSystemScript = preload("res://scripts/effects/particle_system.gd")
const ScreenShakeScript = preload("res://scripts/effects/screen_shake.gd")
const TitleScreenScript = preload("res://scripts/title_screen.gd")
const MainMenuScript = preload("res://scripts/main_menu.gd")
const AboutScreenScript = preload("res://scripts/about_screen.gd")
const BottomBarScript = preload("res://scripts/bottom_bar.gd")
const BoardFrameScript = preload("res://scripts/board_frame.gd")
const MapScreenScript = preload("res://scripts/roguelike/map_screen.gd")
const RelicSelectionScript = preload("res://scripts/roguelike/relic_selection_screen.gd")
const RunSummaryScript = preload("res://scripts/roguelike/run_summary_screen.gd")
const FloorObjectiveScript = preload("res://scripts/roguelike/floor_objective.gd")
const ShopScreenScript = preload("res://scripts/roguelike/shop_screen.gd")
const EventScreenScript = preload("res://scripts/roguelike/event_screen.gd")
const FloorModifiersScript = preload("res://scripts/roguelike/floor_modifiers.gd")
const BossBoardsScript = preload("res://scripts/roguelike/boss_boards.gd")
const MetaScreenScript = preload("res://scripts/roguelike/meta_screen.gd")

const BOARD_W: float = 540.0
const BOARD_H: float = 960.0
const CUP_Y: float = 780.0
const DRAIN_Y: float = 870.0
const LAUNCHER_POS := Vector2(505.0, 850.0)
const BOARD_COUNT := 3

# Playable area boundaries (left wall inner edge to rail left wall outer edge)
const PLAY_LEFT: float = 10.0
const PLAY_RIGHT: float = 487.0
const PLAY_W: float = 477.0
const PLAY_CX: float = 248.5

var _physics_world: Node2D
var _walls: Node2D
var _pin_grid: Node2D
var _rail: Node2D
var _launcher: Node2D
var _drain: Area2D
var _balls_container: Node2D
var _slots: Control
var _hud: CanvasLayer
var _cups: Array = []
var _start_chacker: Node2D
var _particles: Node2D
var _camera: Camera2D
var _tulip: Node2D
var _title_screen: CanvasLayer
var _main_menu: CanvasLayer
var _about_screen: CanvasLayer
var _bottom_bar: CanvasLayer

var _current_board_idx: int = 0
var _board_states: Array = []
var _board_configs: Array = []

# Roguelike mode state
var roguelike_mode: bool = false
var roguelike_config: Dictionary = {}
var floor_objective: RefCounted = null
var _map_screen: CanvasLayer = null
var _relic_screen: CanvasLayer = null
var _summary_screen: CanvasLayer = null
var _shop_screen: CanvasLayer = null
var _event_screen: CanvasLayer = null
var _floor_cleared_overlay: CanvasLayer = null
var _objective_timer: float = 0.0
var _moving_cup_time: float = 0.0
var _meta_screen: CanvasLayer = null

# Boss state
var _boss_type: String = ""
var _boss_timer: float = 0.0
var _gate_pins: Array = []
var _gate_open: bool = false
var _boss_captures: int = 0
var _boss_evolution_stage: int = 0


func _ready() -> void:
	_init_board_configs()
	for i in BOARD_COUNT:
		_board_states.append({
			"score": 0,
			"balls_remaining": GameState.STARTING_BALLS,
			"initialized": false,
		})
	_build_background()
	_build_physics_world()
	_build_ui()
	var frame = BoardFrameScript.new()
	frame.board_width = BOARD_W
	frame.board_height = BOARD_H
	frame.play_right = PLAY_RIGHT
	frame.z_index = 5
	add_child(frame)
	EventBus.peg_hit.connect(_on_peg_hit)
	_particles = ParticleSystemScript.new()
	_particles.z_index = 10
	add_child(_particles)
	_camera = ScreenShakeScript.new()
	add_child(_camera)
	EventBus.peg_hit.connect(_on_peg_hit_effects)
	EventBus.ball_captured.connect(_on_ball_captured_effects)
	EventBus.jackpot_hit.connect(_on_jackpot_effects)
	_title_screen = TitleScreenScript.new()
	_title_screen.start_requested.connect(_on_title_start)
	add_child(_title_screen)


func _init_board_configs() -> void:
	# Pin grids centered in playable area (PLAY_CX = 248.5)
	# CLASSIC: 9cols × 45px = 360 span → origin.x = 248.5 - 180 = 68.5
	# FORTUNE: 7cols × 55px = 330 span → origin.x = 248.5 - 165 = 83.5
	# STORM:  11cols × 38px = 380 span → origin.x = 248.5 - 190 = 58.5
	_board_configs = [
		{
			"name": "CLASSIC",
			"pin_rows": 12, "pin_cols": 9, "pin_spacing": 45.0,
			"pin_origin": Vector2(68.5, 200),
			"cups": [
				{"reward": 5,  "width": 40.0, "crit": false},
				{"reward": 10, "width": 45.0, "crit": false},
				{"reward": 15, "width": 50.0, "crit": false},
				{"reward": 30, "width": 55.0, "crit": true},
				{"reward": 15, "width": 50.0, "crit": false},
				{"reward": 10, "width": 45.0, "crit": false},
				{"reward": 5,  "width": 40.0, "crit": false},
			],
			"tulip_pos": Vector2(PLAY_CX, 600),
			"chacker_pos": Vector2(PLAY_CX, 660),
			"trigger_offsets": [Vector2(-30, -40), Vector2(0, -55), Vector2(30, -40)],
		},
		{
			"name": "FORTUNE",
			"pin_rows": 10, "pin_cols": 7, "pin_spacing": 55.0,
			"pin_origin": Vector2(83.5, 230),
			"cups": [
				{"reward": 10, "width": 55.0, "crit": false},
				{"reward": 20, "width": 60.0, "crit": false},
				{"reward": 50, "width": 65.0, "crit": true},
				{"reward": 20, "width": 60.0, "crit": false},
				{"reward": 10, "width": 55.0, "crit": false},
			],
			"tulip_pos": Vector2(PLAY_CX, 550),
			"chacker_pos": Vector2(PLAY_CX, 620),
			"trigger_offsets": [
				Vector2(-50, -35), Vector2(-15, -55),
				Vector2(15, -55), Vector2(50, -35),
			],
		},
		{
			"name": "STORM",
			"pin_rows": 14, "pin_cols": 11, "pin_spacing": 38.0,
			"pin_origin": Vector2(58.5, 190),
			"cups": [
				{"reward": 3,  "width": 30.0, "crit": false},
				{"reward": 5,  "width": 35.0, "crit": false},
				{"reward": 8,  "width": 38.0, "crit": false},
				{"reward": 15, "width": 42.0, "crit": false},
				{"reward": 40, "width": 48.0, "crit": true},
				{"reward": 15, "width": 42.0, "crit": false},
				{"reward": 8,  "width": 38.0, "crit": false},
				{"reward": 5,  "width": 35.0, "crit": false},
				{"reward": 3,  "width": 30.0, "crit": false},
			],
			"tulip_pos": Vector2(PLAY_CX, 570),
			"chacker_pos": Vector2(PLAY_CX, 640),
			"trigger_offsets": [
				Vector2(-40, -30), Vector2(-15, -50),
				Vector2(15, -50), Vector2(40, -30), Vector2(0, -60),
			],
		},
	]


func _process(delta: float) -> void:
	if GameState.current_phase != GameState.Phase.PLAYING:
		return
	# Roguelike: update survival objective timer
	if roguelike_mode and floor_objective and not floor_objective.completed:
		if floor_objective.type == FloorObjectiveScript.Type.SURVIVAL:
			_objective_timer += delta
			floor_objective.update("time", floori(_objective_timer))
			EventBus.floor_objective_updated.emit(
				floor_objective.current_value,
				floor_objective.target_value,
				floor_objective.get_description(),
			)
		# Moving cups runtime modifier
		_update_moving_cups(delta)
		# Black hole pull on balls
		_update_black_holes(delta)
		# Boss-specific updates
		if _boss_type != "":
			_update_boss(delta)
		return  # No board switching in roguelike mode
	if Input.is_action_just_pressed("ui_left"):
		_switch_board(-1)
	elif Input.is_action_just_pressed("ui_right"):
		_switch_board(1)


func _on_title_start() -> void:
	_title_screen.queue_free()
	_title_screen = null
	_show_main_menu()


func _show_main_menu() -> void:
	_main_menu = MainMenuScript.new()
	_main_menu.start_game_requested.connect(_on_menu_start)
	_main_menu.about_requested.connect(_on_menu_about)
	_main_menu.roguelike_requested.connect(_on_menu_roguelike)
	_main_menu.stats_requested.connect(_on_menu_stats)
	add_child(_main_menu)


func _on_menu_start() -> void:
	_main_menu.queue_free()
	_main_menu = null
	_create_bottom_bar()
	GameState.start_game()
	_board_states[_current_board_idx]["initialized"] = true


func _on_menu_about() -> void:
	_main_menu.queue_free()
	_main_menu = null
	_about_screen = AboutScreenScript.new()
	_about_screen.back_requested.connect(_on_about_back)
	add_child(_about_screen)


func _on_about_back() -> void:
	_about_screen.queue_free()
	_about_screen = null
	_show_main_menu()


func _on_menu_stats() -> void:
	_main_menu.queue_free()
	_main_menu = null
	_meta_screen = MetaScreenScript.new()
	_meta_screen.back_requested.connect(_on_stats_back)
	add_child(_meta_screen)


func _on_stats_back() -> void:
	_meta_screen.queue_free()
	_meta_screen = null
	_show_main_menu()


func _on_menu_roguelike() -> void:
	_main_menu.queue_free()
	_main_menu = null
	roguelike_mode = true
	GameState.roguelike_mode = true
	RunManager.start_run()
	RunManager.phase_changed.connect(_on_run_phase_changed)
	RunManager.run_ended.connect(_on_run_ended)
	RunManager.floor_started.connect(_on_run_floor_started)
	_show_map_screen()


func _show_map_screen() -> void:
	_map_screen = MapScreenScript.new()
	_map_screen.setup(
		RunManager.run_map,
		RunManager.current_layer_idx,
		RunManager.ball_pool,
		RunManager.run_score,
		RunManager.current_act,
		RunManager.last_cleared_node_idx,
	)
	_map_screen.node_selected.connect(_on_map_node_selected)
	add_child(_map_screen)


func _on_map_node_selected(layer_idx: int, node_idx: int) -> void:
	EventBus.map_node_selected.emit(layer_idx, node_idx)
	RunManager.select_map_node(layer_idx, node_idx)


func _on_run_phase_changed(new_phase: int) -> void:
	match new_phase:
		RunManager.RunPhase.MAP_SELECT:
			_show_map_screen()
		RunManager.RunPhase.RELIC_SELECT:
			_show_relic_selection()
		RunManager.RunPhase.SHOP:
			_show_shop_screen()
		RunManager.RunPhase.EVENT:
			_show_event_screen()
		RunManager.RunPhase.REST:
			# For rest nodes, skip immediately (healing already applied in RunManager)
			RunManager.skip_non_combat_node()


func _on_run_ended(won: bool, stats: Dictionary) -> void:
	_summary_screen = RunSummaryScript.new()
	_summary_screen.setup(won, stats)
	_summary_screen.continue_pressed.connect(_on_summary_continue)
	add_child(_summary_screen)


func _on_summary_continue() -> void:
	roguelike_mode = false
	GameState.roguelike_mode = false
	if RunManager.phase_changed.is_connected(_on_run_phase_changed):
		RunManager.phase_changed.disconnect(_on_run_phase_changed)
	if RunManager.run_ended.is_connected(_on_run_ended):
		RunManager.run_ended.disconnect(_on_run_ended)
	if RunManager.floor_started.is_connected(_on_run_floor_started):
		RunManager.floor_started.disconnect(_on_run_floor_started)
	get_tree().reload_current_scene()


func _on_run_floor_started(floor_num: int, config: Dictionary) -> void:
	var objective: RefCounted = RunManager.get_current_objective()
	_objective_timer = 0.0
	_play_floor_transition(floor_num, func():
		setup_roguelike_floor(config, objective)
	)


func _play_floor_transition(floor_num: int, on_complete: Callable) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.size = Vector2(BOARD_W, BOARD_H)
	overlay.z_index = 100
	add_child(overlay)
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.15)
	tween.tween_callback(on_complete)
	tween.tween_property(overlay, "color:a", 0.0, 0.15)
	tween.tween_callback(overlay.queue_free)


func setup_roguelike_floor(config: Dictionary, objective: RefCounted) -> void:
	roguelike_config = config
	floor_objective = objective
	_moving_cup_time = 0.0

	# Initialize boss state
	_boss_type = config.get("boss_type", "")
	_boss_timer = 0.0
	_gate_pins.clear()
	_gate_open = false
	_boss_captures = 0
	_boss_evolution_stage = 0

	# Tear down existing physics and rebuild with roguelike config
	_tear_down_physics()
	_build_physics_world()
	_reconnect_bar_launcher()

	# Boss-specific setup after physics world is built
	if _boss_type != "" and _physics_world:
		_setup_boss_mechanics()

	# Apply runtime modifiers (hot pins, moving cups, black holes, wind)
	var modifiers: Array = config.get("modifiers", [])
	if not modifiers.is_empty() and _physics_world:
		var mod_array: Array[Dictionary] = []
		for m in modifiers:
			mod_array.append(m)
		FloorModifiersScript.apply_runtime_modifiers(mod_array, _physics_world, RunManager.rng)

	# Start floor in GameState
	GameState.start_floor(RunManager.ball_pool, RunManager.ball_cap)
	GameState.active_modifiers = modifiers

	# Setup HUD for roguelike
	if _hud:
		_hud.setup_roguelike(
			RunManager.current_floor,
			RunManager.current_act,
			floor_objective.get_description(),
		)
		_hud.show_modifiers(modifiers)

	# Create bottom bar if needed (roguelike mode: no board switching)
	if not _bottom_bar:
		_create_bottom_bar()

	# Connect objective signals
	if floor_objective:
		floor_objective.objective_completed.connect(_on_floor_objective_completed)

	# Connect game events to objective tracking
	if not EventBus.ball_captured.is_connected(_on_roguelike_capture):
		EventBus.ball_captured.connect(_on_roguelike_capture)
	if not EventBus.ball_lost.is_connected(_on_roguelike_ball_lost):
		EventBus.ball_lost.connect(_on_roguelike_ball_lost)
	if not GameState.game_over.is_connected(_on_roguelike_game_over):
		GameState.game_over.connect(_on_roguelike_game_over)


func _on_roguelike_capture(reward: int, is_crit: bool, ball: RigidBody2D) -> void:
	if not roguelike_mode or floor_objective == null:
		return
	floor_objective.update("capture", 1)
	floor_objective.update("score", reward * 10)
	if floor_objective.type == FloorObjectiveScript.Type.TARGET_SCORE:
		EventBus.floor_objective_updated.emit(
			floor_objective.current_value,
			floor_objective.target_value,
			floor_objective.get_description(),
		)
	elif floor_objective.type == FloorObjectiveScript.Type.CAPTURES:
		EventBus.floor_objective_updated.emit(
			floor_objective.current_value,
			floor_objective.target_value,
			floor_objective.get_description(),
		)
	# Boss capture tracking
	if _boss_type != "":
		_on_boss_capture()


func _on_roguelike_ball_lost(_ball: RigidBody2D) -> void:
	pass


func _on_roguelike_game_over() -> void:
	if roguelike_mode:
		RunManager.end_run(false)


func _on_floor_objective_completed() -> void:
	_show_floor_cleared_overlay()


func _show_floor_cleared_overlay() -> void:
	_floor_cleared_overlay = CanvasLayer.new()
	_floor_cleared_overlay.layer = 15

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_floor_cleared_overlay.add_child(bg)

	var label := Label.new()
	label.text = "★ FLOOR CLEARED ★"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(540, 50)
	label.position = Vector2(0, 400)
	_floor_cleared_overlay.add_child(label)

	add_child(_floor_cleared_overlay)
	AudioManager.play_floor_clear()
	# Auto-advance after delay
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(_on_floor_cleared_timer)


func _on_floor_cleared_timer() -> void:
	if _floor_cleared_overlay:
		_floor_cleared_overlay.queue_free()
		_floor_cleared_overlay = null

	# Record floor achievement stats
	var floor_stats := {
		"balls_lost": GameState.floor_balls_lost,
		"clear_time": _objective_timer,
		"balls_remaining": GameState.balls_remaining,
	}
	MetaProgress.check_floor_achievement(floor_stats)

	# Reset boss state
	_boss_type = ""
	_boss_timer = 0.0
	_gate_pins.clear()
	_gate_open = false
	_boss_captures = 0
	_boss_evolution_stage = 0

	# Disconnect roguelike event handlers
	if EventBus.ball_captured.is_connected(_on_roguelike_capture):
		EventBus.ball_captured.disconnect(_on_roguelike_capture)
	if EventBus.ball_lost.is_connected(_on_roguelike_ball_lost):
		EventBus.ball_lost.disconnect(_on_roguelike_ball_lost)
	if GameState.game_over.is_connected(_on_roguelike_game_over):
		GameState.game_over.disconnect(_on_roguelike_game_over)

	RunManager.complete_floor()


func _show_relic_selection() -> void:
	var relics := RelicManager.get_random_relics(3)
	if relics.is_empty():
		RunManager.on_relic_skipped()
		return

	_relic_screen = RelicSelectionScript.new()
	_relic_screen.setup(relics)
	_relic_screen.relic_selected.connect(_on_relic_picked)
	_relic_screen.selection_skipped.connect(_on_relic_skip)
	add_child(_relic_screen)


func _on_relic_picked(relic_id: String) -> void:
	RunManager.on_relic_selected(relic_id)


func _on_relic_skip() -> void:
	RunManager.on_relic_skipped()


func _show_shop_screen() -> void:
	_shop_screen = ShopScreenScript.new()
	_shop_screen.shop_closed.connect(_on_shop_closed)
	add_child(_shop_screen)


func _on_shop_closed() -> void:
	_shop_screen = null
	RunManager.skip_non_combat_node()


func _show_event_screen() -> void:
	_event_screen = EventScreenScript.new()
	_event_screen.event_closed.connect(_on_event_closed)
	add_child(_event_screen)


func _on_event_closed() -> void:
	_event_screen = null
	RunManager.skip_non_combat_node()


func _update_moving_cups(delta: float) -> void:
	_moving_cup_time += delta
	if not _physics_world:
		return
	for child in _physics_world.get_children():
		if child.is_in_group("moving_cup"):
			var base_x: float = child.get_meta("base_x", child.position.x)
			if not child.has_meta("base_x"):
				child.set_meta("base_x", child.position.x)
			child.position.x = base_x + sin(_moving_cup_time * 1.5) * 25.0


func _update_black_holes(delta: float) -> void:
	if not _physics_world:
		return
	var black_holes := get_tree().get_nodes_in_group("black_hole")
	if black_holes.is_empty():
		return
	var balls := get_tree().get_nodes_in_group("ball")
	for ball in balls:
		if not is_instance_valid(ball) or not ball is RigidBody2D:
			continue
		for bh in black_holes:
			if not is_instance_valid(bh):
				continue
			var dist := ball.global_position.distance_to(bh.global_position)
			if dist < 80.0 and dist > 5.0:
				var pull_strength: float = bh.get_meta("pull_strength", 150.0)
				var direction := (bh.global_position - ball.global_position).normalized()
				ball.linear_velocity += direction * pull_strength * delta * (1.0 - dist / 80.0)


func _create_bottom_bar() -> void:
	_bottom_bar = BottomBarScript.new()
	_bottom_bar.board_count = BOARD_COUNT
	_bottom_bar.back_pressed.connect(_on_bar_back)
	_bottom_bar.switch_board.connect(_switch_board)
	_bottom_bar.launch_hold_started.connect(_launcher.start_touch_charge)
	_bottom_bar.launch_hold_ended.connect(_launcher.stop_touch_charge)
	add_child(_bottom_bar)
	if roguelike_mode and not roguelike_config.is_empty():
		_bottom_bar.set_board_info(0, roguelike_config.get("name", "ROGUELIKE"))
	else:
		_bottom_bar.set_board_info(_current_board_idx, _board_configs[_current_board_idx]["name"])


func _on_bar_back() -> void:
	get_tree().reload_current_scene()


func _switch_board(direction: int) -> void:
	if GameState.current_phase != GameState.Phase.PLAYING:
		return
	var target := (_current_board_idx + direction + BOARD_COUNT) % BOARD_COUNT
	if target == _current_board_idx:
		return
	_board_states[_current_board_idx] = {
		"score": GameState.score,
		"balls_remaining": GameState.balls_remaining,
		"initialized": true,
	}
	_current_board_idx = target
	_tear_down_physics()
	_build_physics_world()
	_reconnect_bar_launcher()
	var state: Dictionary = _board_states[_current_board_idx]
	if state["initialized"]:
		GameState.score = state["score"]
		GameState.balls_remaining = state["balls_remaining"]
	else:
		GameState.score = 0
		GameState.balls_remaining = GameState.STARTING_BALLS
		_board_states[_current_board_idx]["initialized"] = true
	GameState.score_changed.emit(GameState.score)
	GameState.balls_changed.emit(GameState.balls_remaining)
	if _bottom_bar:
		_bottom_bar.set_board_info(_current_board_idx, _board_configs[_current_board_idx]["name"])


func _tear_down_physics() -> void:
	if _tulip and EventBus.tulip_triggered.is_connected(_tulip.open):
		EventBus.tulip_triggered.disconnect(_tulip.open)
	if _bottom_bar and _launcher:
		if _bottom_bar.launch_hold_started.is_connected(_launcher.start_touch_charge):
			_bottom_bar.launch_hold_started.disconnect(_launcher.start_touch_charge)
		if _bottom_bar.launch_hold_ended.is_connected(_launcher.stop_touch_charge):
			_bottom_bar.launch_hold_ended.disconnect(_launcher.stop_touch_charge)
	if _physics_world:
		remove_child(_physics_world)
		_physics_world.queue_free()
		_physics_world = null
		_cups.clear()


func _reconnect_bar_launcher() -> void:
	if _bottom_bar and _launcher:
		_bottom_bar.launch_hold_started.connect(_launcher.start_touch_charge)
		_bottom_bar.launch_hold_ended.connect(_launcher.stop_touch_charge)


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.004, 0.0, 0.027)
	bg.size = Vector2(BOARD_W, BOARD_H)
	bg.z_index = -10
	add_child(bg)


func _build_physics_world() -> void:
	var cfg: Dictionary
	if roguelike_mode and not roguelike_config.is_empty():
		cfg = roguelike_config
	else:
		cfg = _board_configs[_current_board_idx]
	_physics_world = Node2D.new()
	_physics_world.name = "PhysicsWorld"
	add_child(_physics_world)
	_walls = BoardWallsScript.new()
	_walls.board_width = BOARD_W
	_walls.board_height = BOARD_H
	_walls.play_right = PLAY_RIGHT
	_physics_world.add_child(_walls)
	_pin_grid = PinGridScript.new()
	_pin_grid.rows = cfg["pin_rows"]
	_pin_grid.cols = cfg["pin_cols"]
	_pin_grid.h_spacing = cfg["pin_spacing"]
	_pin_grid.position = cfg["pin_origin"]
	_physics_world.add_child(_pin_grid)
	_tulip = TulipScript.new()
	_tulip.position = cfg["tulip_pos"]
	_physics_world.add_child(_tulip)
	EventBus.tulip_triggered.connect(_tulip.open)
	for offset in cfg["trigger_offsets"]:
		var pin = PinScript.new()
		pin.position = cfg["tulip_pos"] + offset
		pin.modulate = Color(0.0, 0.9, 0.9)
		pin.add_to_group("tulip_trigger")
		_physics_world.add_child(pin)
	_start_chacker = StartChackerScript.new()
	_start_chacker.position = cfg["chacker_pos"]
	_physics_world.add_child(_start_chacker)
	var cup_defs: Array = cfg["cups"]
	var total_cup_w := 0.0
	for cd in cup_defs:
		total_cup_w += cd["width"]
	var cup_gap := 6.0
	var total_span := total_cup_w + cup_gap * (cup_defs.size() - 1)
	var cup_x := PLAY_LEFT + (PLAY_W - total_span) / 2.0
	for cd in cup_defs:
		var cup = CupScript.new()
		cup.is_crit = cd["crit"]
		cup.cup_width = cd["width"]
		cup.reward_balls = cd["reward"]
		cup.cup_depth = 30.0
		cup.position = Vector2(cup_x + cd["width"] / 2.0, CUP_Y)
		_physics_world.add_child(cup)
		_cups.append(cup)
		cup_x += cd["width"] + cup_gap
	_drain = DrainScript.new()
	_drain.board_width = PLAY_W
	_drain.position = Vector2(PLAY_CX, DRAIN_Y)
	_physics_world.add_child(_drain)
	_balls_container = Node2D.new()
	_balls_container.name = "Balls"
	_physics_world.add_child(_balls_container)

	# Determine launcher position (mirror modifier flips to left side)
	var launcher_pos := LAUNCHER_POS
	var rail_x := LAUNCHER_POS.x
	if cfg.get("mirror_launcher", false):
		launcher_pos = Vector2(35.0, 850.0)
		rail_x = 35.0

	_rail = RailScript.new()
	_rail.position = Vector2(rail_x, 0.0)
	_rail.channel_top = 100.0
	_rail.channel_bottom = launcher_pos.y
	_physics_world.add_child(_rail)
	_launcher = LauncherScript.new()
	_launcher.position = launcher_pos
	_launcher.setup(_balls_container)
	_physics_world.add_child(_launcher)
	_add_cup_dividers(_physics_world, cup_defs.size())


func _add_cup_dividers(parent: Node2D, num_cups: int) -> void:
	# Center divider pins symmetrically within the playable area
	var row1_count := num_cups + 3
	var row1_y := CUP_Y - 35.0
	var row1_span := PLAY_W - 60.0
	var row1_step := row1_span / float(row1_count - 1)
	var row1_start := PLAY_CX - row1_span / 2.0
	for i in row1_count:
		var pin = PinScript.new()
		pin.position = Vector2(row1_start + i * row1_step, row1_y)
		parent.add_child(pin)
	var row2_count := num_cups + 2
	var row2_y := CUP_Y - 65.0
	var row2_span := PLAY_W - 100.0
	var row2_step := row2_span / float(row2_count - 1)
	var row2_start := PLAY_CX - row2_span / 2.0
	for i in row2_count:
		var pin = PinScript.new()
		pin.position = Vector2(row2_start + i * row2_step, row2_y)
		parent.add_child(pin)


func _build_ui() -> void:
	_slots = SlotsScript.new()
	_slots.z_index = 2
	_slots.position = Vector2(
		(BOARD_W - (SlotsScript.SLOT_WIDTH * 3 + SlotsScript.GAP * 4)) / 2.0,
		80
	)
	add_child(_slots)
	_hud = HUDScript.new()
	add_child(_hud)


func _on_peg_hit(peg: StaticBody2D, _ball: RigidBody2D) -> void:
	if peg.has_method("on_hit"):
		peg.on_hit()
	if peg.is_in_group("tulip_trigger"):
		EventBus.tulip_triggered.emit()
	# Hot pin modifier: lose 1 ball when hitting a hot pin
	if roguelike_mode and peg.is_in_group("hot_pin"):
		var hazard_resist: float = 0.0
		if is_instance_valid(RelicManager):
			hazard_resist = RelicManager.get_modifier("hazard_resist", 0.0)
		if hazard_resist <= 0.0 or randf() >= hazard_resist:
			GameState.balls_remaining = maxi(GameState.balls_remaining - 1, 0)
			GameState.balls_changed.emit(GameState.balls_remaining)


func _on_peg_hit_effects(peg: StaticBody2D, _ball: RigidBody2D) -> void:
	_particles.emit_burst(peg.global_position, 4, ParticleSystemScript.pin_spark())


func _on_ball_captured_effects(_reward: int, is_crit: bool, ball: RigidBody2D) -> void:
	var fx: Dictionary = ParticleSystemScript.capture_stars()
	if is_crit:
		fx["color"] = Color(1.0, 0.5, 0.0)
	_particles.emit_burst(ball.global_position, 10, fx)


func _on_jackpot_effects() -> void:
	_particles.emit_burst(Vector2(BOARD_W / 2.0, 400), 40, ParticleSystemScript.jackpot_firework())
	_camera.shake(4.0, 0.5)


# ─── Boss Mechanics ───

func _setup_boss_mechanics() -> void:
	AudioManager.play_boss_appear()
	match _boss_type:
		"gatekeeper":
			_setup_gatekeeper()
		"storm_core":
			pass  # Wind handled in _update_boss
		"infinite_machine":
			pass  # Evolution handled on capture
		"pachinko_god":
			pass  # Mutations handled in _update_boss


func _setup_gatekeeper() -> void:
	# Add 2 gate pins at center of the board that open/close
	var cfg: Dictionary = roguelike_config
	var origin: Vector2 = cfg.get("pin_origin", Vector2(68.5, 200.0))
	var h_spacing: float = cfg.get("pin_spacing", 45.0)
	var v_spacing: float = h_spacing * sqrt(3.0) / 2.0
	var pin_cols: int = cfg.get("pin_cols", 8)
	var center_x: float = origin.x + float(pin_cols - 1) * h_spacing / 2.0
	var gate_y: float = origin.y + 4.0 * v_spacing  # Middle rows

	var gate_pin_left := PinScript.new()
	gate_pin_left.position = Vector2(center_x - 5.0, gate_y)
	gate_pin_left.modulate = Color(1.0, 0.2, 0.2)
	gate_pin_left.add_to_group("gate_pin")
	_physics_world.add_child(gate_pin_left)
	_gate_pins.append(gate_pin_left)

	var gate_pin_right := PinScript.new()
	gate_pin_right.position = Vector2(center_x + 5.0, gate_y)
	gate_pin_right.modulate = Color(1.0, 0.2, 0.2)
	gate_pin_right.add_to_group("gate_pin")
	_physics_world.add_child(gate_pin_right)
	_gate_pins.append(gate_pin_right)


func _update_boss(delta: float) -> void:
	_boss_timer += delta
	match _boss_type:
		"gatekeeper":
			_update_gatekeeper()
		"storm_core":
			_update_storm_core()
		"pachinko_god":
			_update_pachinko_god()


func _update_gatekeeper() -> void:
	# Toggle gate every 8 seconds
	var should_be_open: bool = fmod(_boss_timer, 16.0) >= 8.0
	if should_be_open != _gate_open:
		_gate_open = should_be_open
		if _gate_pins.size() >= 2:
			var cfg: Dictionary = roguelike_config
			var origin: Vector2 = cfg.get("pin_origin", Vector2(68.5, 200.0))
			var h_spacing: float = cfg.get("pin_spacing", 45.0)
			var pin_cols: int = cfg.get("pin_cols", 8)
			var center_x: float = origin.x + float(pin_cols - 1) * h_spacing / 2.0
			if _gate_open:
				# Move apart
				_gate_pins[0].position.x = center_x - 30.0
				_gate_pins[1].position.x = center_x + 30.0
				_gate_pins[0].modulate = Color(0.2, 1.0, 0.2)
				_gate_pins[1].modulate = Color(0.2, 1.0, 0.2)
			else:
				# Move close together
				_gate_pins[0].position.x = center_x - 5.0
				_gate_pins[1].position.x = center_x + 5.0
				_gate_pins[0].modulate = Color(1.0, 0.2, 0.2)
				_gate_pins[1].modulate = Color(1.0, 0.2, 0.2)


func _update_storm_core() -> void:
	# Oscillating wind force
	GameState.wind_force = sin(_boss_timer * 0.4) * 200.0


func _update_pachinko_god() -> void:
	# Every 15s, apply a random physics mutation
	var interval := 15.0
	var prev_count := floori((_boss_timer - get_process_delta_time()) / interval)
	var curr_count := floori(_boss_timer / interval)
	if curr_count > prev_count and curr_count > 0:
		_apply_random_mutation()


func _apply_random_mutation() -> void:
	var mutation := randi() % 4
	match mutation:
		0:
			# Gravity flip: invert gravity on active balls
			var balls := get_tree().get_nodes_in_group("ball")
			for ball in balls:
				if is_instance_valid(ball) and ball is RigidBody2D:
					ball.gravity_scale = -ball.gravity_scale
		1:
			# Bounce ×2: increase bounce on active balls
			var balls := get_tree().get_nodes_in_group("ball")
			for ball in balls:
				if is_instance_valid(ball) and ball is RigidBody2D:
					var mat := ball.physics_material_override
					if mat:
						mat.bounce = clampf(mat.bounce * 2.0, 0.0, 1.0)
		2:
			# Friction ×3 on active balls
			var balls := get_tree().get_nodes_in_group("ball")
			for ball in balls:
				if is_instance_valid(ball) and ball is RigidBody2D:
					var mat := ball.physics_material_override
					if mat:
						mat.friction = clampf(mat.friction * 3.0, 0.0, 1.0)
		3:
			# Wind reversal
			GameState.wind_force = -GameState.wind_force if GameState.wind_force != 0.0 else 150.0


func _on_boss_capture() -> void:
	_boss_captures += 1
	if _boss_type == "infinite_machine":
		_check_infinite_machine_evolution()


func _check_infinite_machine_evolution() -> void:
	var stages: Array = roguelike_config.get("evolution_stages", [])
	if _boss_evolution_stage >= stages.size():
		return

	var next_stage: Dictionary = stages[_boss_evolution_stage]
	if _boss_captures >= next_stage.get("captures", 999):
		_boss_evolution_stage += 1
		_evolve_pin_grid(next_stage)


func _evolve_pin_grid(stage: Dictionary) -> void:
	# Only rebuild the pin grid, keep cups/drain/launcher intact
	if not _physics_world:
		return

	# Remove existing pin_grid
	if _pin_grid and is_instance_valid(_pin_grid):
		_physics_world.remove_child(_pin_grid)
		_pin_grid.queue_free()
		_pin_grid = null

	var new_rows: int = stage.get("pin_rows", 12)
	var new_cols: int = stage.get("pin_cols", 10)
	var spacing_delta: float = stage.get("spacing_delta", 0.0)
	var base_spacing: float = roguelike_config.get("pin_spacing", 45.0)
	var new_spacing: float = maxf(base_spacing + spacing_delta, 30.0)

	var grid_span := float(new_cols - 1) * new_spacing
	var pin_origin_x := PLAY_CX - grid_span / 2.0

	_pin_grid = PinGridScript.new()
	_pin_grid.rows = new_rows
	_pin_grid.cols = new_cols
	_pin_grid.h_spacing = new_spacing
	_pin_grid.position = Vector2(pin_origin_x, 200.0)
	_physics_world.add_child(_pin_grid)

	# Apply hot pins if this stage requires it
	if stage.get("hot_pins", false) and RunManager.rng:
		# Wait a frame for pin_grid to generate its children
		call_deferred("_apply_hot_pins_to_grid")


func _apply_hot_pins_to_grid() -> void:
	if _physics_world and RunManager.rng:
		var mod_array: Array[Dictionary] = [{"id": "hot_pins"}]
		FloorModifiersScript.apply_runtime_modifiers(mod_array, _physics_world, RunManager.rng)
