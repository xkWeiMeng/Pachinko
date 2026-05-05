extends Node2D

const BoardWallsScript = preload("res://scripts/walls.gd")
const PinGridScript = preload("res://scripts/pin_grid.gd")
const PinScript = preload("res://scripts/pin.gd")
const LauncherScript = preload("res://scripts/launcher.gd")
const DrainScript = preload("res://scripts/drain.gd")
const CupScript = preload("res://scripts/cup.gd")
const SlotsScript = preload("res://scripts/slots.gd")
const HUDScript = preload("res://scripts/hud.gd")

const BOARD_W: float = 540.0
const BOARD_H: float = 960.0

const PIN_AREA_TOP: float = 200.0
const PIN_AREA_LEFT: float = 60.0
const CUP_Y: float = 780.0
const DRAIN_Y: float = 870.0
const LAUNCHER_POS := Vector2(500.0, 850.0)

var _walls: Node2D
var _pin_grid: Node2D
var _launcher: Node2D
var _drain: Area2D
var _balls_container: Node2D
var _slots: Control
var _hud: CanvasLayer
var _cups: Array = []


func _ready() -> void:
	_build_background()
	_build_physics_world()
	_build_ui()

	# Connect peg hit to trigger pin flash
	EventBus.peg_hit.connect(_on_peg_hit)

	# Start the game
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

	# Cups — 3 at the bottom (normal, crit, normal)
	var cup_positions := [
		{ "x": BOARD_W * 0.25, "crit": false },
		{ "x": BOARD_W * 0.5, "crit": true },
		{ "x": BOARD_W * 0.75, "crit": false },
	]
	for cup_data in cup_positions:
		var cup = CupScript.new()
		cup.is_crit = cup_data["crit"]
		cup.cup_width = 55.0 if cup_data["crit"] else 50.0
		cup.position = Vector2(cup_data["x"], CUP_Y)
		physics_world.add_child(cup)
		_cups.append(cup)

	# Drain
	_drain = DrainScript.new()
	_drain.board_width = BOARD_W
	_drain.position = Vector2(BOARD_W / 2.0, DRAIN_Y)
	physics_world.add_child(_drain)

	# Balls container
	_balls_container = Node2D.new()
	_balls_container.name = "Balls"
	physics_world.add_child(_balls_container)

	# Launcher
	_launcher = LauncherScript.new()
	_launcher.position = LAUNCHER_POS
	_launcher.setup(_balls_container)
	physics_world.add_child(_launcher)

	# Bottom wall (below cups, above drain) — divider pegs to guide into cups
	_add_cup_dividers(physics_world)


func _add_cup_dividers(parent: Node2D) -> void:
	# Small pins between cups to guide balls
	var divider_positions := [
		Vector2(BOARD_W * 0.125, CUP_Y + 5),
		Vector2(BOARD_W * 0.375, CUP_Y + 5),
		Vector2(BOARD_W * 0.625, CUP_Y + 5),
		Vector2(BOARD_W * 0.875, CUP_Y + 5),
	]
	for pos in divider_positions:
		var pin = PinScript.new()
		pin.position = pos
		parent.add_child(pin)

	# Additional row of guide pins above cups
	var guide_y := CUP_Y - 40.0
	for i in range(7):
		var pin = PinScript.new()
		pin.position = Vector2(60.0 + i * 70.0, guide_y)
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
