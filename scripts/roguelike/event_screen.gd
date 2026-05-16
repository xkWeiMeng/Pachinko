class_name EventScreen
extends CanvasLayer

## Random narrative event screen with choices.

signal event_closed

const BOARD_W := 540.0
const BOARD_H := 960.0

var _event: Dictionary = {}
var _options: Array[Dictionary] = []
var _selected: int = 0
var _option_labels: Array[Label] = []
var _input_ready: bool = false
var _result_shown: bool = false

static var EVENT_TEMPLATES: Array[Dictionary] = [
	{
		"title": "神秘商人",
		"text": "A cloaked figure appears, offering rare artifacts...",
		"options": [
			{"label": "Pay 20 balls → Random Epic Relic", "cost_type": "balls", "cost": 20, "reward_type": "relic", "rarity": 2},
			{"label": "Pay 10 balls → Random Rare Relic", "cost_type": "balls", "cost": 10, "reward_type": "relic", "rarity": 1},
			{"label": "Refuse", "cost_type": "none", "cost": 0, "reward_type": "none"},
		],
	},
	{
		"title": "古老弹珠机",
		"text": "An ancient pachinko machine gleams with mysterious energy...",
		"options": [
			{"label": "Gamble 30 balls (50%: +80 / 50%: +0)", "cost_type": "balls", "cost": 30, "reward_type": "gamble", "win": 80, "chance": 0.5},
			{"label": "Observe (+50 score bonus)", "cost_type": "none", "cost": 0, "reward_type": "score", "value": 50},
		],
	},
	{
		"title": "遗物熔炉",
		"text": "A blazing forge demands sacrifice in exchange for power...",
		"options": [
			{"label": "Sacrifice 2 common relics → 1 Rare Relic", "cost_type": "relics", "cost": 2, "rarity_cost": 0, "reward_type": "relic", "rarity": 1},
			{"label": "Sacrifice 1 relic → +15 balls", "cost_type": "relics", "cost": 1, "rarity_cost": -1, "reward_type": "balls", "value": 15},
			{"label": "Leave", "cost_type": "none", "cost": 0, "reward_type": "none"},
		],
	},
	{
		"title": "弹珠工匠",
		"text": "A master craftsman offers to enhance your equipment...",
		"options": [
			{"label": "Spend 500 score → Upgrade (+5 balls)", "cost_type": "score", "cost": 500, "reward_type": "balls", "value": 5},
			{"label": "Spend 1000 score → Duplicate (+5 balls)", "cost_type": "score", "cost": 1000, "reward_type": "balls", "value": 5},
			{"label": "Decline", "cost_type": "none", "cost": 0, "reward_type": "none"},
		],
	},
	{
		"title": "命运轮盘",
		"text": "A glowing wheel of fortune spins before you...",
		"options": [
			{"label": "Spin the wheel!", "cost_type": "none", "cost": 0, "reward_type": "wheel"},
			{"label": "Walk away", "cost_type": "none", "cost": 0, "reward_type": "none"},
		],
	},
	{
		"title": "挑战之间",
		"text": "A gate inscribed with ancient runes blocks the path...",
		"options": [
			{"label": "Accept challenge (+20 balls after)", "cost_type": "none", "cost": 0, "reward_type": "balls", "value": 20},
			{"label": "Refuse", "cost_type": "none", "cost": 0, "reward_type": "none"},
		],
	},
]


func _ready() -> void:
	layer = 20
	_pick_event()
	_build()
	AudioManager.play_event_chime()
	call_deferred("_enable_input")


func _enable_input() -> void:
	_input_ready = true


func _pick_event() -> void:
	_event = EVENT_TEMPLATES[randi() % EVENT_TEMPLATES.size()]
	_options = []
	for opt in _event["options"]:
		_options.append(opt.duplicate())


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.0, 0.04, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "✦ %s ✦" % _event["title"]
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.6, 0.5, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(BOARD_W, 40)
	title.position = Vector2(0, 120)
	add_child(title)

	# Narrative text
	var narr := Label.new()
	narr.text = _event["text"]
	narr.add_theme_font_size_override("font_size", 14)
	narr.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	narr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narr.size = Vector2(BOARD_W - 80, 60)
	narr.position = Vector2(40, 180)
	add_child(narr)

	# Options
	var y_start := 300.0
	var opt_height := 80.0
	for i in _options.size():
		var opt: Dictionary = _options[i]
		var lbl := Label.new()
		lbl.text = opt["label"]
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size = Vector2(BOARD_W - 80, 50)
		lbl.position = Vector2(40, y_start + i * opt_height)
		add_child(lbl)
		_option_labels.append(lbl)

	# Controls hint
	var hint := Label.new()
	hint.text = "↑ ↓  Select    SPACE  Choose"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(BOARD_W, 20)
	hint.position = Vector2(0, BOARD_H - 30)
	add_child(hint)

	_refresh_selection()


func _refresh_selection() -> void:
	for i in _option_labels.size():
		if i == _selected:
			_option_labels[i].add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			_option_labels[i].text = "▸ " + _options[i]["label"]
		else:
			_option_labels[i].text = _options[i]["label"]
			_option_labels[i].add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))


func _process(_delta: float) -> void:
	if not _input_ready or _result_shown:
		return

	if Input.is_action_just_pressed("ui_up"):
		_selected = (_selected - 1 + _options.size()) % _options.size()
		_refresh_selection()
	elif Input.is_action_just_pressed("ui_down"):
		_selected = (_selected + 1) % _options.size()
		_refresh_selection()
	elif Input.is_action_just_pressed("launch") or Input.is_action_just_pressed("ui_accept"):
		_choose()


func _choose() -> void:
	var opt: Dictionary = _options[_selected]
	var result_text := ""

	# Pay cost
	match opt.get("cost_type", "none"):
		"balls":
			if RunManager.ball_pool < opt["cost"]:
				_show_result("Not enough balls!")
				return
			RunManager.ball_pool -= opt["cost"]
		"score":
			if RunManager.run_score < opt["cost"]:
				_show_result("Not enough score!")
				return
			RunManager.run_score -= opt["cost"]
		"relics":
			var cost_count: int = opt["cost"]
			var rarity_filter: int = opt.get("rarity_cost", -1)
			var available: Array[Dictionary] = []
			for relic in RelicManager.active_relics:
				if rarity_filter < 0 or relic.get("rarity", 0) == rarity_filter:
					available.append(relic)
			if available.size() < cost_count:
				_show_result("Not enough relics!")
				return
			for i in cost_count:
				var r: Dictionary = available[i]
				RelicManager.remove_relic(r["id"])
				RunManager.collected_relics.erase(r["id"])

	# Grant reward
	match opt.get("reward_type", "none"):
		"none":
			result_text = "You walk away..."
		"balls":
			var val: int = opt.get("value", 0)
			RunManager.ball_pool = mini(RunManager.ball_pool + val, RunManager.ball_cap)
			result_text = "+%d balls!" % val
		"score":
			var val: int = opt.get("value", 0)
			RunManager.run_score += val
			result_text = "+%d score!" % val
		"relic":
			var rarity: int = opt.get("rarity", 0)
			var relics := RelicManager.get_relics_by_rarity(rarity)
			if relics.is_empty():
				relics = RelicManager.get_random_relics(1)
			if not relics.is_empty():
				var r: Dictionary = relics[randi() % relics.size()]
				RelicManager.add_relic(r["id"])
				RunManager.collected_relics.append(r["id"])
				result_text = "Got: %s %s!" % [r["icon_char"], r["name"]]
			else:
				result_text = "No relics available..."
		"gamble":
			var chance: float = opt.get("chance", 0.5)
			var win_val: int = opt.get("win", 0)
			if randf() < chance:
				RunManager.ball_pool = mini(RunManager.ball_pool + win_val, RunManager.ball_cap)
				result_text = "WIN! +%d balls!" % win_val
			else:
				result_text = "Nothing happened..."
		"wheel":
			var roll := randf()
			if roll < 0.25:
				RunManager.ball_pool = mini(RunManager.ball_pool + 30, RunManager.ball_cap)
				result_text = "🎉 +30 balls!"
			elif roll < 0.50:
				RunManager.ball_pool = maxi(RunManager.ball_pool - 15, 0)
				result_text = "💀 -15 balls..."
			elif roll < 0.75:
				var relics := RelicManager.get_random_relics(1)
				if not relics.is_empty():
					RelicManager.add_relic(relics[0]["id"])
					RunManager.collected_relics.append(relics[0]["id"])
					result_text = "🎁 Got: %s!" % relics[0]["name"]
				else:
					result_text = "🎁 No relics available"
			else:
				if not RelicManager.active_relics.is_empty():
					var lost: Dictionary = RelicManager.active_relics[randi() % RelicManager.active_relics.size()]
					RelicManager.remove_relic(lost["id"])
					RunManager.collected_relics.erase(lost["id"])
					result_text = "😱 Lost: %s!" % lost["name"]
				else:
					result_text = "Nothing happened..."

	_show_result(result_text)


func _show_result(text: String) -> void:
	_result_shown = true
	# Hide options
	for lbl in _option_labels:
		lbl.visible = false

	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", 22)
	result.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.size = Vector2(BOARD_W, 40)
	result.position = Vector2(0, 450)
	add_child(result)

	# Auto close after 2s
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(_on_result_timeout)


func _on_result_timeout() -> void:
	event_closed.emit()
	queue_free()
