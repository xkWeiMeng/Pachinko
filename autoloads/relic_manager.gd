extends Node

## Relic System — manages relics for the current roguelike run.

signal relic_added(relic: Dictionary)
signal relic_removed(relic: Dictionary)
signal relics_cleared

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum Category { PHYSICS, SCORING, BOARD, CONDITIONAL }

var active_relics: Array[Dictionary] = []
var _relic_database: Dictionary = {}
var _modifier_cache: Dictionary = {}


func _ready() -> void:
	_init_relic_database()


func _init_relic_database() -> void:
	_relic_database = {
		"bouncy_gel": {
			"id": "bouncy_gel",
			"name": "弹力胶",
			"description": "Balls bounce 20% harder off pins",
			"rarity": Rarity.COMMON,
			"icon_char": "🟢",
			"category": Category.PHYSICS,
			"effects": {"bounce_bonus": 0.2},
		},
		"saver": {
			"id": "saver",
			"name": "节约者",
			"description": "Every 4th ball launch is free",
			"rarity": Rarity.COMMON,
			"icon_char": "💰",
			"category": Category.SCORING,
			"effects": {"free_ball_every": 4},
		},
		"combo_counter": {
			"id": "combo_counter",
			"name": "连击计数器",
			"description": "Track consecutive captures for bonus score",
			"rarity": Rarity.RARE,
			"icon_char": "🔥",
			"category": Category.SCORING,
			"effects": {"combo_enabled": true},
		},
		"wide_cups": {
			"id": "wide_cups",
			"name": "宽容之杯",
			"description": "Cup openings are 15% wider",
			"rarity": Rarity.COMMON,
			"icon_char": "🏆",
			"category": Category.BOARD,
			"effects": {"cup_width_mult": 1.15},
		},
		"insurance": {
			"id": "insurance",
			"name": "保险机制",
			"description": "20% chance to save a drained ball",
			"rarity": Rarity.RARE,
			"icon_char": "🛡",
			"category": Category.SCORING,
			"effects": {"drain_save_chance": 0.2},
		},
		"copper_bag": {
			"id": "copper_bag",
			"name": "铜币袋",
			"description": "+2 bonus score per capture",
			"rarity": Rarity.COMMON,
			"icon_char": "👛",
			"category": Category.SCORING,
			"effects": {"capture_bonus_score": 2},
		},
		"tulip_rage": {
			"id": "tulip_rage",
			"name": "郁金香之怒",
			"description": "Tulip stays open 40% longer (5s→7s)",
			"rarity": Rarity.COMMON,
			"icon_char": "🌷",
			"category": Category.BOARD,
			"effects": {"tulip_duration_mult": 1.4},
		},
		"sticky_shell": {
			"id": "sticky_shell",
			"name": "粘性外壳",
			"description": "Balls slow down 30% near cups",
			"rarity": Rarity.RARE,
			"icon_char": "🐌",
			"category": Category.PHYSICS,
			"effects": {"near_cup_slowdown": 0.3},
		},
		# --- Phase 2 Physics relics ---
		"gravity_core": {
			"id": "gravity_core",
			"name": "重力核心",
			"description": "Ball mass +50% (heavier = faster fall)",
			"rarity": Rarity.COMMON,
			"icon_char": "⬛",
			"category": Category.PHYSICS,
			"effects": {"ball_mass_mult": 1.5},
		},
		"ghost_core": {
			"id": "ghost_core",
			"name": "幽灵核",
			"description": "15% chance to phase through pins",
			"rarity": Rarity.RARE,
			"icon_char": "👻",
			"category": Category.PHYSICS,
			"effects": {"pin_phase_chance": 0.15},
		},
		"split_shot": {
			"id": "split_shot",
			"name": "分裂弹",
			"description": "First collision splits ball into 2",
			"rarity": Rarity.EPIC,
			"icon_char": "💥",
			"category": Category.PHYSICS,
			"effects": {"split_on_first_hit": true},
		},
		"magnet_field": {
			"id": "magnet_field",
			"name": "磁力场",
			"description": "Balls slightly pulled toward nearest cup",
			"rarity": Rarity.EPIC,
			"icon_char": "🧲",
			"category": Category.PHYSICS,
			"effects": {"cup_magnet_strength": 0.15},
		},
		"quantum_link": {
			"id": "quantum_link",
			"name": "量子纠缠",
			"description": "Creates shadow ball on same trajectory 0.3s delayed",
			"rarity": Rarity.LEGENDARY,
			"icon_char": "⚛",
			"category": Category.PHYSICS,
			"effects": {"shadow_ball": true},
		},
		# --- Phase 2 Scoring relics ---
		"interest": {
			"id": "interest",
			"name": "利息",
			"description": "Gain 5% of current balls at floor start",
			"rarity": Rarity.RARE,
			"icon_char": "📈",
			"category": Category.SCORING,
			"effects": {"floor_start_interest": 0.05},
		},
		"greedy_heart": {
			"id": "greedy_heart",
			"name": "贪婪之心",
			"description": "Cup rewards ×2 but ball cap -30%",
			"rarity": Rarity.EPIC,
			"icon_char": "💜",
			"category": Category.SCORING,
			"effects": {"reward_mult": 2.0, "ball_cap_penalty": 0.3},
		},
		"lucky_seven": {
			"id": "lucky_seven",
			"name": "幸运七",
			"description": "Jackpot probability +50%",
			"rarity": Rarity.EPIC,
			"icon_char": "🎰",
			"category": Category.SCORING,
			"effects": {"jackpot_bonus": 0.5},
		},
		"midas_touch": {
			"id": "midas_touch",
			"name": "点金术",
			"description": "Each pin collision gives 1 score",
			"rarity": Rarity.LEGENDARY,
			"icon_char": "✨",
			"category": Category.SCORING,
			"effects": {"pin_hit_score": 1},
		},
		# --- Phase 2 Board relics ---
		"slot_machine_plus": {
			"id": "slot_machine_plus",
			"name": "永动老虎机",
			"description": "Any cup capture triggers slot (not just crit)",
			"rarity": Rarity.RARE,
			"icon_char": "🎲",
			"category": Category.BOARD,
			"effects": {"any_cup_triggers_slot": true},
		},
		"trap_immunity": {
			"id": "trap_immunity",
			"name": "陷阱免疫",
			"description": "Hazard effects reduced by 50%",
			"rarity": Rarity.RARE,
			"icon_char": "🛡️",
			"category": Category.BOARD,
			"effects": {"hazard_resist": 0.5},
		},
		"cup_magnet_big": {
			"id": "cup_magnet_big",
			"name": "杯子磁铁",
			"description": "One random cup width ×3 at floor start",
			"rarity": Rarity.EPIC,
			"icon_char": "🏟",
			"category": Category.BOARD,
			"effects": {"random_big_cup": true},
		},
		"golden_drain": {
			"id": "golden_drain",
			"name": "黄金排水口",
			"description": "Drain becomes a low-reward cup (1 ball + 10 score)",
			"rarity": Rarity.LEGENDARY,
			"icon_char": "🌟",
			"category": Category.BOARD,
			"effects": {"golden_drain": true},
		},
		# --- Phase 2 Conditional relics ---
		"first_shot": {
			"id": "first_shot",
			"name": "首弹强化",
			"description": "First ball each floor scores ×3",
			"rarity": Rarity.COMMON,
			"icon_char": "1️⃣",
			"category": Category.CONDITIONAL,
			"effects": {"first_ball_score_mult": 3},
		},
		"desperation": {
			"id": "desperation",
			"name": "背水一战",
			"description": "When balls ≤10, cup rewards ×2",
			"rarity": Rarity.RARE,
			"icon_char": "🔥",
			"category": Category.CONDITIONAL,
			"effects": {"low_ball_reward_mult": 2.0, "low_ball_threshold": 10},
		},
		"perfectionist": {
			"id": "perfectionist",
			"name": "完美主义",
			"description": "0 balls lost in a floor → +15 balls",
			"rarity": Rarity.EPIC,
			"icon_char": "💎",
			"category": Category.CONDITIONAL,
			"effects": {"perfect_floor_bonus": 15},
		},
		"collector": {
			"id": "collector",
			"name": "收藏家",
			"description": "Every 5 relics owned → all cup rewards +1",
			"rarity": Rarity.EPIC,
			"icon_char": "📦",
			"category": Category.CONDITIONAL,
			"effects": {"relic_count_bonus": true},
		},
	}


func add_relic(relic_id: String) -> void:
	if not _relic_database.has(relic_id):
		return
	if has_relic(relic_id):
		return
	var relic: Dictionary = _relic_database[relic_id].duplicate(true)
	active_relics.append(relic)
	_rebuild_modifier_cache()
	relic_added.emit(relic)
	EventBus.relic_acquired.emit(relic)


func remove_relic(relic_id: String) -> void:
	for i in active_relics.size():
		if active_relics[i]["id"] == relic_id:
			var relic: Dictionary = active_relics[i]
			active_relics.remove_at(i)
			_rebuild_modifier_cache()
			relic_removed.emit(relic)
			EventBus.relic_removed.emit(relic)
			return


func has_relic(relic_id: String) -> bool:
	for relic in active_relics:
		if relic["id"] == relic_id:
			return true
	return false


func get_random_relics(count: int, max_rarity: int = Rarity.LEGENDARY) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for id in _relic_database:
		var relic: Dictionary = _relic_database[id]
		if relic["rarity"] <= max_rarity and not has_relic(id):
			pool.append(relic.duplicate(true))

	# Shuffle pool
	for i in range(pool.size() - 1, 0, -1):
		var j := randi_range(0, i)
		var tmp: Dictionary = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp

	var result: Array[Dictionary] = []
	for i in mini(count, pool.size()):
		result.append(pool[i])
	return result


func get_modifier(key: String, default: Variant = null) -> Variant:
	if _modifier_cache.has(key):
		return _modifier_cache[key]
	return default


func reset() -> void:
	active_relics.clear()
	_modifier_cache.clear()
	relics_cleared.emit()


func _rebuild_modifier_cache() -> void:
	_modifier_cache.clear()
	for relic in active_relics:
		var effects: Dictionary = relic.get("effects", {})
		for key in effects:
			var value: Variant = effects[key]
			if value is float or value is int:
				# Accumulate numeric modifiers
				_modifier_cache[key] = _modifier_cache.get(key, 0) + value
			elif value is bool:
				# Any true wins
				_modifier_cache[key] = _modifier_cache.get(key, false) or value
			else:
				_modifier_cache[key] = value


func get_relics_by_rarity(rarity: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in _relic_database:
		var relic: Dictionary = _relic_database[id]
		if relic["rarity"] == rarity and not has_relic(id):
			result.append(relic.duplicate(true))
	return result


func get_relic_data(relic_id: String) -> Dictionary:
	if _relic_database.has(relic_id):
		return _relic_database[relic_id].duplicate(true)
	return {}
