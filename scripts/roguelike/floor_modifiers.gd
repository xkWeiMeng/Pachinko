class_name FloorModifiers
extends RefCounted

## Elite floor modifier definitions and application.

const MODIFIER_DEFS: Array[Dictionary] = [
	{
		"id": "strong_wind",
		"name": "Strong Wind",
		"icon": "💨",
		"description": "Constant horizontal force on all balls",
		"runtime": true,
	},
	{
		"id": "narrow_path",
		"name": "Narrow Path",
		"icon": "📏",
		"description": "Board width shrinks 30%",
		"runtime": false,
	},
	{
		"id": "hot_pins",
		"name": "Hot Pins",
		"icon": "🔥",
		"description": "20% of pins are hot — hit one, lose 1 ball",
		"runtime": true,
	},
	{
		"id": "mirror",
		"name": "Mirror",
		"icon": "🪞",
		"description": "Launcher on left side instead of right",
		"runtime": false,
	},
	{
		"id": "moving_cups",
		"name": "Moving Cups",
		"icon": "↔️",
		"description": "Cups oscillate left-right",
		"runtime": true,
	},
	{
		"id": "black_hole",
		"name": "Black Hole",
		"icon": "🕳",
		"description": "Gravity areas that pull balls toward center",
		"runtime": true,
	},
]


static func get_random_modifiers(count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var pool := MODIFIER_DEFS.duplicate()
	# Shuffle
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Dictionary = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var result: Array[Dictionary] = []
	for i in mini(count, pool.size()):
		result.append(pool[i].duplicate())
	return result


static func apply_config_modifiers(modifiers: Array[Dictionary], config: Dictionary, rng: RandomNumberGenerator) -> void:
	for mod in modifiers:
		match mod["id"]:
			"narrow_path":
				# Shrink cup widths and pin spacing by 30%
				var cups: Array = config.get("cups", [])
				for cup in cups:
					cup["width"] = cup["width"] * 0.7
				config["pin_spacing"] = config.get("pin_spacing", 45.0) * 0.7
				# Recenter pin grid
				var grid_span: float = float(config.get("pin_cols", 9) - 1) * config["pin_spacing"]
				var origin: Vector2 = config.get("pin_origin", Vector2(68.5, 200))
				origin.x = 248.5 - grid_span / 2.0
				config["pin_origin"] = origin
			"mirror":
				config["mirror_launcher"] = true


static func apply_runtime_modifiers(modifiers: Array[Dictionary], physics_world: Node2D, rng: RandomNumberGenerator) -> void:
	for mod in modifiers:
		match mod["id"]:
			"strong_wind":
				var direction: float = 1.0 if rng.randf() > 0.5 else -1.0
				GameState.wind_force = direction * rng.randf_range(100.0, 250.0)
			"hot_pins":
				_apply_hot_pins(physics_world, rng)
			"moving_cups":
				_apply_moving_cups(physics_world)
			"black_hole":
				_apply_black_holes(physics_world, rng)
	GameState.active_modifiers = modifiers


static func _apply_hot_pins(physics_world: Node2D, rng: RandomNumberGenerator) -> void:
	var all_pegs: Array[Node] = []
	for child in physics_world.get_children():
		_collect_pegs(child, all_pegs)
	var hot_count := maxi(1, floori(all_pegs.size() * 0.2))
	# Shuffle pegs
	for i in range(all_pegs.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Node = all_pegs[i]
		all_pegs[i] = all_pegs[j]
		all_pegs[j] = tmp
	for i in mini(hot_count, all_pegs.size()):
		var peg: Node = all_pegs[i]
		peg.add_to_group("hot_pin")
		peg.modulate = Color(1.0, 0.3, 0.1)
		GameState.hot_pins.append(peg)


static func _collect_pegs(node: Node, result: Array[Node]) -> void:
	if node.is_in_group("peg") and not node.is_in_group("tulip_trigger"):
		result.append(node)
	for child in node.get_children():
		_collect_pegs(child, result)


static func _apply_moving_cups(physics_world: Node2D) -> void:
	for child in physics_world.get_children():
		if child is Node2D and child.has_method("_on_ball_entered"):
			child.add_to_group("moving_cup")


static func _apply_black_holes(physics_world: Node2D, rng: RandomNumberGenerator) -> void:
	var count := rng.randi_range(1, 2)
	for i in count:
		var bh := Area2D.new()
		bh.name = "BlackHole_%d" % i
		bh.collision_layer = 0
		bh.collision_mask = 1
		bh.monitoring = true
		bh.position = Vector2(
			rng.randf_range(80.0, 400.0),
			rng.randf_range(300.0, 600.0),
		)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 80.0
		shape.shape = circle
		bh.add_child(shape)
		bh.add_to_group("black_hole")
		bh.set_meta("pull_strength", 150.0)
		physics_world.add_child(bh)
