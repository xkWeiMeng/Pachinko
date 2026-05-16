class_name BossBoards
extends RefCounted

## Boss board configurations for roguelike floors 5, 10, 15, 16.

const PLAY_LEFT: float = 10.0
const PLAY_RIGHT: float = 487.0
const PLAY_W: float = 477.0
const PLAY_CX: float = 248.5


static func get_boss_config(floor_num: int, act: int, rng: RandomNumberGenerator) -> Dictionary:
	match floor_num:
		5:
			return _gatekeeper_config(rng)
		10:
			return _storm_core_config(rng)
		15:
			return _infinite_machine_config(rng)
		16:
			return _pachinko_god_config(rng)
		_:
			# Fallback for any unexpected boss floor
			return _gatekeeper_config(rng)


static func _gatekeeper_config(rng: RandomNumberGenerator) -> Dictionary:
	var pin_rows := 10
	var pin_cols := 8
	var h_spacing := 45.0
	var grid_span := float(pin_cols - 1) * h_spacing
	var pin_origin_x := PLAY_CX - grid_span / 2.0

	# Left cups: low reward. Right cups: high reward with crit.
	var cups: Array[Dictionary] = [
		{"reward": 3,  "width": 38.0, "crit": false},
		{"reward": 4,  "width": 38.0, "crit": false},
		{"reward": 5,  "width": 38.0, "crit": false},
		{"reward": 15, "width": 42.0, "crit": false},
		{"reward": 20, "width": 42.0, "crit": false},
		{"reward": 30, "width": 45.0, "crit": true},
	]

	var v_spacing := h_spacing * sqrt(3.0) / 2.0
	var grid_bottom := 200.0 + (pin_rows - 1) * v_spacing
	var tulip_y := clampf(grid_bottom + 40.0, 500.0, 700.0)

	return {
		"name": "GATEKEEPER",
		"boss_type": "gatekeeper",
		"pin_rows": pin_rows,
		"pin_cols": pin_cols,
		"pin_spacing": h_spacing,
		"pin_origin": Vector2(pin_origin_x, 200.0),
		"cups": cups,
		"tulip_pos": Vector2(PLAY_CX, tulip_y),
		"chacker_pos": Vector2(PLAY_CX, tulip_y + 60.0),
		"trigger_offsets": [Vector2(-30, -40), Vector2(0, -55), Vector2(30, -40)] as Array[Vector2],
		"modifiers": [] as Array[Dictionary],
		"objective_type": "TARGET_SCORE",
		"objective_target": 2000,
	}


static func _storm_core_config(rng: RandomNumberGenerator) -> Dictionary:
	var pin_rows := 12
	var pin_cols := 10
	var h_spacing := 42.0
	var grid_span := float(pin_cols - 1) * h_spacing
	var pin_origin_x := PLAY_CX - grid_span / 2.0

	# Cups in ring pattern with super-cup in center
	var cups: Array[Dictionary] = [
		{"reward": 5,  "width": 35.0, "crit": false},
		{"reward": 8,  "width": 38.0, "crit": false},
		{"reward": 12, "width": 40.0, "crit": false},
		{"reward": 50, "width": 50.0, "crit": true},
		{"reward": 12, "width": 40.0, "crit": false},
		{"reward": 8,  "width": 38.0, "crit": false},
		{"reward": 5,  "width": 35.0, "crit": false},
	]

	var v_spacing := h_spacing * sqrt(3.0) / 2.0
	var grid_bottom := 200.0 + (pin_rows - 1) * v_spacing
	var tulip_y := clampf(grid_bottom + 40.0, 500.0, 700.0)

	return {
		"name": "STORM CORE",
		"boss_type": "storm_core",
		"pin_rows": pin_rows,
		"pin_cols": pin_cols,
		"pin_spacing": h_spacing,
		"pin_origin": Vector2(pin_origin_x, 200.0),
		"cups": cups,
		"tulip_pos": Vector2(PLAY_CX, tulip_y),
		"chacker_pos": Vector2(PLAY_CX, tulip_y + 60.0),
		"trigger_offsets": [
			Vector2(-40, -35), Vector2(-15, -55),
			Vector2(15, -55), Vector2(40, -35),
		] as Array[Vector2],
		"modifiers": [] as Array[Dictionary],
		"objective_type": "CAPTURES",
		"objective_target": 15,
	}


static func _infinite_machine_config(rng: RandomNumberGenerator) -> Dictionary:
	var pin_rows := 10
	var pin_cols := 9
	var h_spacing := 45.0
	var grid_span := float(pin_cols - 1) * h_spacing
	var pin_origin_x := PLAY_CX - grid_span / 2.0

	var cups: Array[Dictionary] = [
		{"reward": 5,  "width": 38.0, "crit": false},
		{"reward": 8,  "width": 40.0, "crit": false},
		{"reward": 15, "width": 45.0, "crit": false},
		{"reward": 25, "width": 48.0, "crit": true},
		{"reward": 15, "width": 45.0, "crit": false},
		{"reward": 8,  "width": 40.0, "crit": false},
		{"reward": 5,  "width": 38.0, "crit": false},
	]

	var v_spacing := h_spacing * sqrt(3.0) / 2.0
	var grid_bottom := 200.0 + (pin_rows - 1) * v_spacing
	var tulip_y := clampf(grid_bottom + 40.0, 500.0, 700.0)

	return {
		"name": "∞ MACHINE",
		"boss_type": "infinite_machine",
		"pin_rows": pin_rows,
		"pin_cols": pin_cols,
		"pin_spacing": h_spacing,
		"pin_origin": Vector2(pin_origin_x, 200.0),
		"cups": cups,
		"tulip_pos": Vector2(PLAY_CX, tulip_y),
		"chacker_pos": Vector2(PLAY_CX, tulip_y + 60.0),
		"trigger_offsets": [
			Vector2(-35, -40), Vector2(0, -55), Vector2(35, -40),
			Vector2(-20, -30), Vector2(20, -30),
		] as Array[Vector2],
		"modifiers": [] as Array[Dictionary],
		"objective_type": "CAPTURES",
		"objective_target": 15,
		# Evolution thresholds for pin grid rebuild
		"evolution_stages": [
			{"captures": 5, "pin_rows": 12, "pin_cols": 10, "spacing_delta": -3.0},
			{"captures": 10, "pin_rows": 14, "pin_cols": 11, "spacing_delta": -5.0, "hot_pins": true},
		],
	}


static func _pachinko_god_config(rng: RandomNumberGenerator) -> Dictionary:
	var pin_rows := 14
	var pin_cols := 11
	var h_spacing := 36.0
	var grid_span := float(pin_cols - 1) * h_spacing
	var pin_origin_x := PLAY_CX - grid_span / 2.0

	# Multiple crit cups
	var cups: Array[Dictionary] = [
		{"reward": 5,  "width": 32.0, "crit": false},
		{"reward": 10, "width": 35.0, "crit": false},
		{"reward": 20, "width": 38.0, "crit": true},
		{"reward": 8,  "width": 35.0, "crit": false},
		{"reward": 30, "width": 42.0, "crit": true},
		{"reward": 8,  "width": 35.0, "crit": false},
		{"reward": 20, "width": 38.0, "crit": true},
		{"reward": 10, "width": 35.0, "crit": false},
		{"reward": 5,  "width": 32.0, "crit": false},
	]

	var v_spacing := h_spacing * sqrt(3.0) / 2.0
	var grid_bottom := 200.0 + (pin_rows - 1) * v_spacing
	var tulip_y := clampf(grid_bottom + 40.0, 500.0, 700.0)

	return {
		"name": "パチンコの神",
		"boss_type": "pachinko_god",
		"pin_rows": pin_rows,
		"pin_cols": pin_cols,
		"pin_spacing": h_spacing,
		"pin_origin": Vector2(pin_origin_x, 200.0),
		"cups": cups,
		"tulip_pos": Vector2(PLAY_CX, tulip_y),
		"chacker_pos": Vector2(PLAY_CX, tulip_y + 60.0),
		"trigger_offsets": [
			Vector2(-40, -30), Vector2(-15, -50),
			Vector2(15, -50), Vector2(40, -30), Vector2(0, -60),
		] as Array[Vector2],
		"modifiers": [] as Array[Dictionary],
		"objective_type": "TARGET_SCORE",
		"objective_target": 5000,
	}
