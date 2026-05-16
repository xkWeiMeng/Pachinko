class_name MapGenerator
extends RefCounted

enum NodeType { NORMAL, ELITE, BOSS, SHOP, EVENT, REST }


static func generate_map(rng: RandomNumberGenerator) -> Array[Array]:
	var map: Array[Array] = []

	# 3 acts × 5 floors each = 15 layers + 1 final boss = 16
	var floor_num := 1
	for act in range(1, 4):
		for floor_in_act in range(1, 6):
			var layer: Array[Dictionary] = []
			var is_boss_floor := (floor_in_act == 5)

			if is_boss_floor:
				layer.append({
					"type": NodeType.BOSS,
					"connections": [] as Array[int],
					"floor_num": floor_num,
					"act": act,
					"is_elite": false,
					"cleared": false,
				})
			else:
				var node_count := rng.randi_range(2, 4)
				for i in node_count:
					var node_type := _roll_node_type(rng, floor_in_act)
					layer.append({
						"type": node_type,
						"connections": [] as Array[int],
						"floor_num": floor_num,
						"act": act,
						"is_elite": node_type == NodeType.ELITE,
						"cleared": false,
					})

			map.append(layer)
			floor_num += 1

	# Floor 16: final boss
	var final_layer: Array[Dictionary] = []
	final_layer.append({
		"type": NodeType.BOSS,
		"connections": [] as Array[int],
		"floor_num": 16,
		"act": 3,
		"is_elite": false,
		"cleared": false,
	})
	map.append(final_layer)

	# Generate connections between layers
	_generate_connections(map, rng)

	return map


static func _roll_node_type(rng: RandomNumberGenerator, floor_in_act: int) -> NodeType:
	var roll := rng.randf()
	# NORMAL: 50%, ELITE: 15%, SHOP: 15%, EVENT: 10%, REST: 10%
	if roll < 0.50:
		return NodeType.NORMAL
	elif roll < 0.65:
		return NodeType.ELITE
	elif roll < 0.80:
		return NodeType.SHOP
	elif roll < 0.90:
		return NodeType.EVENT
	else:
		return NodeType.REST


static func _generate_connections(map: Array[Array], rng: RandomNumberGenerator) -> void:
	for layer_idx in range(map.size() - 1):
		var current_layer: Array = map[layer_idx]
		var next_layer: Array = map[layer_idx + 1]

		# Ensure every node in current layer connects to at least 1 in next
		for node_idx in current_layer.size():
			var node: Dictionary = current_layer[node_idx]
			var conn_count := rng.randi_range(1, mini(2, next_layer.size()))
			var available: Array[int] = []
			for i in next_layer.size():
				available.append(i)

			# Shuffle and pick
			for i in range(available.size() - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var tmp := available[i]
				available[i] = available[j]
				available[j] = tmp

			var connections: Array[int] = []
			for i in mini(conn_count, available.size()):
				connections.append(available[i])
			connections.sort()
			node["connections"] = connections

		# Ensure every node in next layer is reachable from at least one in current
		for next_idx in next_layer.size():
			var reachable := false
			for node in current_layer:
				var conns: Array = node["connections"]
				if next_idx in conns:
					reachable = true
					break
			if not reachable:
				# Connect a random node from current layer to this unreachable node
				var src_idx := rng.randi_range(0, current_layer.size() - 1)
				var conns: Array = current_layer[src_idx]["connections"]
				conns.append(next_idx)
				conns.sort()
