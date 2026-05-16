class_name BoardGenerator
extends RefCounted

const PLAY_LEFT: float = 10.0
const PLAY_RIGHT: float = 487.0
const PLAY_W: float = 477.0
const PLAY_CX: float = 248.5

const FloorModifiersScript = preload("res://scripts/roguelike/floor_modifiers.gd")

const BOARD_NAMES: Array[String] = [
	"NEBULA", "CRYSTAL", "VOID", "PULSE", "FLUX",
	"ABYSS", "PRISM", "NOVA", "DRIFT", "CHAOS",
]


static func generate(floor_num: int, act: int, is_elite: bool, rng: RandomNumberGenerator) -> Dictionary:
	var base_difficulty := 1.0 + (floor_num - 1) * 0.15

	# Pin grid parameters
	var pin_rows := clampi(8 + floori(base_difficulty * 1.2), 8, 16)
	var pin_cols := clampi(6 + floori(base_difficulty * 0.5), 6, 12)
	var h_spacing := clampf(lerpf(55.0, 35.0, base_difficulty / 3.0), 35.0, 55.0)

	# Center pin grid in playable area
	var grid_span := float(pin_cols - 1) * h_spacing
	var pin_origin_x := PLAY_CX - grid_span / 2.0
	var pin_origin_y := 200.0 + rng.randf_range(-10.0, 10.0)

	# Cup parameters
	var cup_count := clampi(4 + floori(base_difficulty * 0.8), 4, 9)
	var base_cup_width := clampf(55.0 * (1.0 - base_difficulty * 0.03), 25.0, 65.0)

	# Generate cups
	var cups: Array[Dictionary] = []
	var crit_idx := rng.randi_range(0, cup_count - 1)
	for i in cup_count:
		var is_crit := (i == crit_idx)
		var reward := 5
		if is_crit:
			reward = clampi(floori(15.0 * (1.0 + base_difficulty * 0.08)), 15, 60)
		else:
			reward = clampi(floori(5.0 * (1.0 + base_difficulty * 0.08)), 3, 25)

		var width := base_cup_width + rng.randf_range(-5.0, 5.0)
		width = clampf(width, 25.0, 60.0)

		cups.append({
			"reward": reward,
			"width": width,
			"crit": is_crit,
		})

	# Tulip position
	var v_spacing := h_spacing * sqrt(3.0) / 2.0
	var grid_bottom := pin_origin_y + (pin_rows - 1) * v_spacing
	var tulip_y := clampf(grid_bottom + 40.0 + rng.randf_range(-10.0, 10.0), 500.0, 700.0)
	var tulip_pos := Vector2(PLAY_CX, tulip_y)

	# Chacker position below tulip
	var chacker_pos := Vector2(PLAY_CX, tulip_y + 60.0)

	# Trigger offsets: 3-5 pins around tulip
	var trigger_count := rng.randi_range(3, 5)
	var trigger_offsets: Array[Vector2] = []
	for i in trigger_count:
		var angle := (float(i) / trigger_count) * TAU - PI / 2.0
		var dist := rng.randf_range(30.0, 55.0)
		trigger_offsets.append(Vector2(cos(angle) * dist, sin(angle) * dist - 15.0))

	# Elite boards: tighter spacing, slightly better rewards
	if is_elite:
		h_spacing = maxf(h_spacing - 3.0, 35.0)
		grid_span = float(pin_cols - 1) * h_spacing
		pin_origin_x = PLAY_CX - grid_span / 2.0
		for cup in cups:
			cup["reward"] = ceili(cup["reward"] * 1.3)
			cup["width"] = maxf(cup["width"] - 3.0, 25.0)

	var board_name: String = BOARD_NAMES[rng.randi_range(0, BOARD_NAMES.size() - 1)]

	var result: Dictionary = {
		"name": board_name,
		"pin_rows": pin_rows,
		"pin_cols": pin_cols,
		"pin_spacing": h_spacing,
		"pin_origin": Vector2(pin_origin_x, pin_origin_y),
		"cups": cups,
		"tulip_pos": tulip_pos,
		"chacker_pos": chacker_pos,
		"trigger_offsets": trigger_offsets,
		"modifiers": [] as Array[Dictionary],
	}

	# Elite/boss boards get random floor modifiers
	if is_elite:
		var mod_count := rng.randi_range(1, 2)
		var modifiers := FloorModifiersScript.get_random_modifiers(mod_count, rng)
		result["modifiers"] = modifiers
		# Apply config-time modifiers (narrow_path, mirror)
		FloorModifiersScript.apply_config_modifiers(modifiers, result, rng)

	return result
