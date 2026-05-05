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
const BoardFrameScript = preload("res://scripts/board_frame.gd")

const BOARD_W: float = 540.0
const BOARD_H: float = 960.0

const PIN_AREA_TOP: float = 200.0
const PIN_AREA_LEFT: float = 60.0
const CUP_Y: float = 780.0
const DRAIN_Y: float = 870.0
const LAUNCHER_POS := Vector2(505.0, 850.0)

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


func _ready() -> void:
	_build_background()
	_build_physics_world()
	_build_ui()

	# Decorative frame (drawn on top of background, below physics)
	var frame = BoardFrameScript.new()
	frame.board_width = BOARD_W
	frame.board_height = BOARD_H
	frame.z_index = 5
	add_child(frame)

	# Connect peg hit to trigger pin flash
	EventBus.peg_hit.connect(_on_peg_hit)

	# Connect tulip trigger
	EventBus.tulip_triggered.connect(_tulip.open)

	# Effects
	_particles = ParticleSystemScript.new()
	_particles.z_index = 10
	add_child(_particles)

	_camera = ScreenShakeScript.new()
	add_child(_camera)

	EventBus.peg_hit.connect(_on_peg_hit_effects)
	EventBus.ball_captured.connect(_on_ball_captured_effects)
	EventBus.jackpot_hit.connect(_on_jackpot_effects)

	# Show title screen instead of starting immediately
	_title_screen = TitleScreenScript.new()
	_title_screen.start_requested.connect(_on_title_start)
	add_child(_title_screen)


func _on_title_start() -> void:
	_title_screen.queue_free()
	_title_screen = null
	GameState.start_game()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.004, 0.0, 0.027)
	bg.size = Vector2(BOARD_W, BOARD_H)
	bg.z_index = -10
	add_child(bg)


func _build_physics_world() -> void:
	var physics_world := Node2D.new()
	physics_world.name = "PhysicsWorld"
	add_child(physics_world)

	# Walls
	_walls = BoardWallsScript.new()
	_walls.board_width = BOARD_W
	_walls.board_height = BOARD_H
	physics_world.add_child(_walls)

	# Pin grid
	_pin_grid = PinGridScript.new()
	_pin_grid.rows = 12
	_pin_grid.cols = 9
	_pin_grid.h_spacing = 45.0
	_pin_grid.position = Vector2(PIN_AREA_LEFT, PIN_AREA_TOP)
	physics_world.add_child(_pin_grid)

	# Tulip (チューリップ) — center of board, below pin grid
	_tulip = TulipScript.new()
	_tulip.position = Vector2(BOARD_W * 0.5, 600)
	physics_world.add_child(_tulip)

	# Trigger pins above the tulip
	var trigger_offsets := [Vector2(-30, -40), Vector2(0, -55), Vector2(30, -40)]
	for offset in trigger_offsets:
		var pin = PinScript.new()
		pin.position = _tulip.position + offset
		pin.modulate = Color(0.0, 0.9, 0.9)
		pin.add_to_group("tulip_trigger")
		physics_world.add_child(pin)

	# START チャッカー — center of pin grid area
	_start_chacker = StartChackerScript.new()
	_start_chacker.position = Vector2(BOARD_W * 0.5, 660)
	physics_world.add_child(_start_chacker)

	# Cups — 7 at the bottom: [5, 10, 15, ★30, 15, 10, 5]
	var cup_configs := [
		{"reward": 5,  "width": 40.0, "crit": false},
		{"reward": 10, "width": 45.0, "crit": false},
		{"reward": 15, "width": 50.0, "crit": false},
		{"reward": 30, "width": 55.0, "crit": true},
		{"reward": 15, "width": 50.0, "crit": false},
		{"reward": 10, "width": 45.0, "crit": false},
		{"reward": 5,  "width": 40.0, "crit": false},
	]
	var total_cup_width := 0.0
	for cfg in cup_configs:
		total_cup_width += cfg["width"]
	var cup_gap := 6.0
	var total_span := total_cup_width + cup_gap * (cup_configs.size() - 1)
	var cup_start_x := (BOARD_W - total_span) / 2.0
	var cx := cup_start_x
	for cfg in cup_configs:
		var cup = CupScript.new()
		cup.is_crit = cfg["crit"]
		cup.cup_width = cfg["width"]
		cup.reward_balls = cfg["reward"]
		cup.cup_depth = 30.0
		cup.position = Vector2(cx + cfg["width"] / 2.0, CUP_Y)
		physics_world.add_child(cup)
		_cups.append(cup)
		cx += cfg["width"] + cup_gap

	# Drain
	_drain = DrainScript.new()
	_drain.board_width = BOARD_W
	_drain.position = Vector2(BOARD_W / 2.0, DRAIN_Y)
	physics_world.add_child(_drain)

	# Balls container
	_balls_container = Node2D.new()
	_balls_container.name = "Balls"
	physics_world.add_child(_balls_container)

	# Launch rail (right-side channel)
	_rail = RailScript.new()
	_rail.position = Vector2(LAUNCHER_POS.x, 0.0)
	_rail.channel_top = 100.0
	_rail.channel_bottom = LAUNCHER_POS.y
	physics_world.add_child(_rail)

	# Launcher (at bottom of rail channel)
	_launcher = LauncherScript.new()
	_launcher.position = LAUNCHER_POS
	_launcher.setup(_balls_container)
	physics_world.add_child(_launcher)

	# Bottom wall (below cups, above drain) — divider pegs to guide into cups
	_add_cup_dividers(physics_world)


func _add_cup_dividers(parent: Node2D) -> void:
	# Guide pins above the cup row
	var guide_y := CUP_Y - 35.0
	for i in range(10):
		var pin = PinScript.new()
		pin.position = Vector2(40.0 + i * 50.0, guide_y)
		parent.add_child(pin)

	# Second guide row slightly higher
	var guide_y2 := CUP_Y - 65.0
	for i in range(9):
		var pin = PinScript.new()
		pin.position = Vector2(65.0 + i * 50.0, guide_y2)
		parent.add_child(pin)


func _build_ui() -> void:
	# Slots display — centered at top
	_slots = SlotsScript.new()
	_slots.position = Vector2(
		(BOARD_W - (SlotsScript.SLOT_WIDTH * 3 + SlotsScript.GAP * 4)) / 2.0,
		80
	)
	add_child(_slots)

	# HUD
	_hud = HUDScript.new()
	add_child(_hud)


func _on_peg_hit(peg: StaticBody2D, _ball: RigidBody2D) -> void:
	if peg.has_method("on_hit"):
		peg.on_hit()
	if peg.is_in_group("tulip_trigger"):
		EventBus.tulip_triggered.emit()


func _on_peg_hit_effects(peg: StaticBody2D, _ball: RigidBody2D) -> void:
	_particles.emit_burst(peg.global_position, 4, ParticleSystemScript.pin_spark())


func _on_ball_captured_effects(reward: int, is_crit: bool, ball: RigidBody2D) -> void:
	var config: Dictionary = ParticleSystemScript.capture_stars()
	if is_crit:
		config["color"] = Color(1.0, 0.5, 0.0)
	_particles.emit_burst(ball.global_position, 10, config)


func _on_jackpot_effects() -> void:
	_particles.emit_burst(Vector2(BOARD_W / 2.0, 400), 40, ParticleSystemScript.jackpot_firework())
	_camera.shake(4.0, 0.5)
