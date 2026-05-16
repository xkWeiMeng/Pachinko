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
var _floor_cleared_overlay: CanvasLayer = null
var _objective_timer: float = 0.0


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


func _process(_delta: float) -> void:
	if GameState.current_phase != GameState.Phase.PLAYING:
		return
	# Roguelike: update survival objective timer
	if roguelike_mode and floor_objective and not floor_objective.completed:
		if floor_objective.type == FloorObjectiveScript.Type.SURVIVAL:
			_objective_timer += _delta
			floor_objective.update("time", floori(_objective_timer))
			EventBus.floor_objective_updated.emit(
				floor_objective.current_value,
				floor_objective.target_value,
				floor_objective.get_description(),
			)
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
		RunManager.RunPhase.REST, RunManager.RunPhase.SHOP, RunManager.RunPhase.EVENT:
			# For non-combat nodes, show briefly and advance
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
	setup_roguelike_floor(config, objective)


func setup_roguelike_floor(config: Dictionary, objective: RefCounted) -> void:
	roguelike_config = config
	floor_objective = objective

	# Tear down existing physics and rebuild with roguelike config
	_tear_down_physics()
	_build_physics_world()
	_reconnect_bar_launcher()

	# Start floor in GameState
	GameState.start_floor(RunManager.ball_pool, RunManager.ball_cap)

	# Setup HUD for roguelike
	if _hud:
		_hud.setup_roguelike(
			RunManager.current_floor,
			RunManager.current_act,
			floor_objective.get_description(),
		)

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

	# Auto-advance after delay
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(_on_floor_cleared_timer)


func _on_floor_cleared_timer() -> void:
	if _floor_cleared_overlay:
		_floor_cleared_overlay.queue_free()
		_floor_cleared_overlay = null

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
	_rail = RailScript.new()
	_rail.position = Vector2(LAUNCHER_POS.x, 0.0)
	_rail.channel_top = 100.0
	_rail.channel_bottom = LAUNCHER_POS.y
	_physics_world.add_child(_rail)
	_launcher = LauncherScript.new()
	_launcher.position = LAUNCHER_POS
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
