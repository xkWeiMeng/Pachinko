class_name ShopScreen
extends CanvasLayer

## Shop screen — spend score to buy items.

signal shop_closed

const BOARD_W := 540.0
const BOARD_H := 960.0

const RelicSelectionScript = preload("res://scripts/roguelike/relic_selection_screen.gd")

var _items: Array[Dictionary] = []
var _selected: int = 0
var _item_labels: Array[Label] = []
var _price_labels: Array[Label] = []
var _input_ready: bool = false
var _message_label: Label
var _balls_label: Label
var _score_label: Label
var _relic_screen: CanvasLayer = null


func _ready() -> void:
	layer = 20
	_init_items()
	_build()
	call_deferred("_enable_input")


func _enable_input() -> void:
	_input_ready = true


func _init_items() -> void:
	_items = [
		{"name": "Small Ball Pack", "price": 150, "desc": "+10 balls", "type": "balls", "value": 10},
		{"name": "Large Ball Pack", "price": 500, "desc": "+30 balls", "type": "balls", "value": 30},
		{"name": "Random Common Relic", "price": 250, "desc": "Get 1 random common relic", "type": "relic_random", "rarity": 0},
		{"name": "Random Rare Relic", "price": 800, "desc": "Get 1 random rare relic", "type": "relic_random", "rarity": 1},
		{"name": "Relic Choice", "price": 1200, "desc": "3-pick-1 from any rarity", "type": "relic_choice"},
		{"name": "Remove a Relic", "price": 400, "desc": "Remove 1 relic from inventory", "type": "relic_remove"},
		{"name": "Ball Cap Upgrade", "price": 1000, "desc": "Ball cap +20 permanent", "type": "ball_cap", "value": 20},
		{"name": "LEAVE", "price": 0, "desc": "", "type": "leave"},
	]


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.0, 0.04, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "✦ SHOP ✦"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(BOARD_W, 45)
	title.position = Vector2(0, 40)
	add_child(title)

	# Info bar
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 16)
	_score_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.size = Vector2(BOARD_W / 2.0, 25)
	_score_label.position = Vector2(0, 95)
	add_child(_score_label)

	_balls_label = Label.new()
	_balls_label.add_theme_font_size_override("font_size", 16)
	_balls_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	_balls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_balls_label.size = Vector2(BOARD_W / 2.0, 25)
	_balls_label.position = Vector2(BOARD_W / 2.0, 95)
	add_child(_balls_label)

	_update_info()

	# Separator
	var sep := ColorRect.new()
	sep.color = Color(0.3, 0.3, 0.4, 0.4)
	sep.size = Vector2(400, 1)
	sep.position = Vector2((BOARD_W - 400) / 2.0, 125)
	add_child(sep)

	# Items
	var y_start := 150.0
	var item_height := 85.0
	for i in _items.size():
		var item: Dictionary = _items[i]
		var y_pos := y_start + i * item_height

		var name_lbl := Label.new()
		name_lbl.text = item["name"]
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		name_lbl.position = Vector2(60, y_pos)
		name_lbl.size = Vector2(350, 25)
		add_child(name_lbl)
		_item_labels.append(name_lbl)

		if item["price"] > 0:
			var price_lbl := Label.new()
			price_lbl.text = "%d score" % item["price"]
			price_lbl.add_theme_font_size_override("font_size", 14)
			price_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			price_lbl.size = Vector2(120, 20)
			price_lbl.position = Vector2(380, y_pos)
			add_child(price_lbl)
			_price_labels.append(price_lbl)
		else:
			_price_labels.append(null)

		if not item["desc"].is_empty():
			var desc_lbl := Label.new()
			desc_lbl.text = item["desc"]
			desc_lbl.add_theme_font_size_override("font_size", 11)
			desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
			desc_lbl.position = Vector2(60, y_pos + 25)
			desc_lbl.size = Vector2(400, 18)
			add_child(desc_lbl)

	# Message area
	_message_label = Label.new()
	_message_label.add_theme_font_size_override("font_size", 16)
	_message_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.size = Vector2(BOARD_W, 25)
	_message_label.position = Vector2(0, BOARD_H - 80)
	add_child(_message_label)

	# Controls hint
	var hint := Label.new()
	hint.text = "↑ ↓  Select    SPACE  Buy"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(BOARD_W, 20)
	hint.position = Vector2(0, BOARD_H - 30)
	add_child(hint)

	_refresh_selection()


func _update_info() -> void:
	_score_label.text = "SCORE: %d" % RunManager.run_score
	_balls_label.text = "BALLS: %d" % RunManager.ball_pool


func _refresh_selection() -> void:
	for i in _item_labels.size():
		var item: Dictionary = _items[i]
		var can_afford: bool = RunManager.run_score >= item["price"] or item["price"] == 0
		if i == _selected:
			_item_labels[i].add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			_item_labels[i].text = "▸ " + item["name"]
		else:
			_item_labels[i].text = item["name"]
			if can_afford:
				_item_labels[i].add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
			else:
				_item_labels[i].add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))


func _process(_delta: float) -> void:
	if not _input_ready:
		return
	if _relic_screen != null:
		return  # Relic choice screen is open

	if Input.is_action_just_pressed("ui_up"):
		_selected = (_selected - 1 + _items.size()) % _items.size()
		_refresh_selection()
	elif Input.is_action_just_pressed("ui_down"):
		_selected = (_selected + 1) % _items.size()
		_refresh_selection()
	elif Input.is_action_just_pressed("launch") or Input.is_action_just_pressed("ui_accept"):
		_purchase()


func _purchase() -> void:
	var item: Dictionary = _items[_selected]
	if item["type"] == "leave":
		shop_closed.emit()
		queue_free()
		return

	if RunManager.run_score < item["price"]:
		_show_message("Not enough score!")
		return

	match item["type"]:
		"balls":
			RunManager.run_score -= item["price"]
			RunManager.ball_pool = mini(RunManager.ball_pool + item["value"], RunManager.ball_cap)
			_show_message("+%d balls!" % item["value"])
			AudioManager.play_shop_purchase()
		"relic_random":
			var rarity: int = item["rarity"]
			var relics := RelicManager.get_relics_by_rarity(rarity)
			if relics.is_empty():
				_show_message("No relics available!")
				return
			RunManager.run_score -= item["price"]
			# Pick a random one
			var relic: Dictionary = relics[randi() % relics.size()]
			RelicManager.add_relic(relic["id"])
			RunManager.collected_relics.append(relic["id"])
			_show_message("Got: %s %s" % [relic["icon_char"], relic["name"]])
			AudioManager.play_shop_purchase()
		"relic_choice":
			RunManager.run_score -= item["price"]
			AudioManager.play_shop_purchase()
			_show_relic_choice()
			return  # Don't update info yet
		"relic_remove":
			if RelicManager.active_relics.is_empty():
				_show_message("No relics to remove!")
				return
			RunManager.run_score -= item["price"]
			var removed: Dictionary = RelicManager.active_relics[0]
			RelicManager.remove_relic(removed["id"])
			RunManager.collected_relics.erase(removed["id"])
			_show_message("Removed: %s %s" % [removed["icon_char"], removed["name"]])
			AudioManager.play_shop_purchase()
		"ball_cap":
			RunManager.run_score -= item["price"]
			RunManager.ball_cap += item["value"]
			_show_message("Ball cap now %d!" % RunManager.ball_cap)
			AudioManager.play_shop_purchase()

	_update_info()
	_refresh_selection()


func _show_relic_choice() -> void:
	var relics := RelicManager.get_random_relics(3)
	if relics.is_empty():
		_show_message("No relics available!")
		_update_info()
		return
	_relic_screen = RelicSelectionScript.new()
	_relic_screen.setup(relics)
	_relic_screen.relic_selected.connect(_on_relic_choice_selected)
	_relic_screen.selection_skipped.connect(_on_relic_choice_skipped)
	add_child(_relic_screen)


func _on_relic_choice_selected(relic_id: String) -> void:
	RelicManager.add_relic(relic_id)
	RunManager.collected_relics.append(relic_id)
	_relic_screen = null
	_show_message("Got relic!")
	_update_info()
	_refresh_selection()


func _on_relic_choice_skipped() -> void:
	_relic_screen = null
	_show_message("Skipped relic choice")
	_update_info()


func _show_message(text: String) -> void:
	_message_label.text = text
	var tween := create_tween()
	_message_label.modulate.a = 1.0
	tween.tween_interval(1.5)
	tween.tween_property(_message_label, "modulate:a", 0.0, 0.5)
