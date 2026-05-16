class_name MapScreen
extends CanvasLayer

## Slay-the-Spire-style branching map for run path selection.

signal node_selected(layer_idx: int, node_idx: int)

const BOARD_W := 540.0
const BOARD_H := 960.0
const NODE_RADIUS := 18.0
const LAYER_HEIGHT := 55.0
const NODE_ICONS := {
	0: "⚪",  # NORMAL
	1: "🔴",  # ELITE
	2: "💀",  # BOSS
	3: "💰",  # SHOP
	4: "❓",  # EVENT
	5: "🏕",  # REST
}
const NODE_TYPE_NAMES := {
	0: "BATTLE",
	1: "ELITE",
	2: "BOSS",
	3: "SHOP",
	4: "EVENT",
	5: "REST",
}

var _map_data: Array[Array] = []
var _current_layer: int = 0
var _selected_node: int = 0
var _scroll_offset: float = 0.0
var _input_ready: bool = false
var _ball_count: int = 0
var _score: int = 0
var _act: int = 1
var _last_cleared_node_idx: int = -1
var _accessible_nodes: Array[int] = []
var _draw_panel: Control


func setup(map_data: Array[Array], current_layer: int, ball_count: int, score: int, act: int, last_cleared_idx: int = -1) -> void:
	_map_data = map_data
	_current_layer = current_layer
	_ball_count = ball_count
	_score = score
	_act = act
	_last_cleared_node_idx = last_cleared_idx
	_compute_accessible_nodes()
	# Auto-select first accessible node
	if _accessible_nodes.is_empty():
		_selected_node = 0
	else:
		_selected_node = _accessible_nodes[0]


func _ready() -> void:
	layer = 20
	_build()
	call_deferred("_enable_input")


func _enable_input() -> void:
	_input_ready = true


func _build() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.005, 0.0, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Grid pattern overlay
	_draw_panel = Control.new()
	_draw_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_panel.draw.connect(_draw_map)
	add_child(_draw_panel)

	# Top info bar
	var info_bar := Control.new()
	info_bar.size = Vector2(BOARD_W, 60)
	add_child(info_bar)

	var act_label := Label.new()
	act_label.text = "ACT %d" % _act
	act_label.add_theme_font_size_override("font_size", 22)
	act_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	act_label.position = Vector2(20, 15)
	info_bar.add_child(act_label)

	var balls_label := Label.new()
	balls_label.text = "BALLS: %d" % _ball_count
	balls_label.add_theme_font_size_override("font_size", 14)
	balls_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
	balls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	balls_label.size = Vector2(200, 20)
	balls_label.position = Vector2(BOARD_W - 220, 15)
	info_bar.add_child(balls_label)

	var score_label := Label.new()
	score_label.text = "SCORE: %d" % _score
	score_label.add_theme_font_size_override("font_size", 14)
	score_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.size = Vector2(200, 20)
	score_label.position = Vector2(BOARD_W - 220, 35)
	info_bar.add_child(score_label)

	# Relic count
	var relic_count: int = 0
	if is_instance_valid(RelicManager):
		relic_count = RelicManager.active_relics.size()
	var relic_label := Label.new()
	relic_label.text = "RELICS: %d" % relic_count
	relic_label.add_theme_font_size_override("font_size", 12)
	relic_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))
	relic_label.position = Vector2(20, 40)
	info_bar.add_child(relic_label)

	# Controls hint
	var hint := Label.new()
	hint.text = "↑ ↓  Select Node    SPACE  Confirm"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(BOARD_W, 20)
	hint.position = Vector2(0, BOARD_H - 30)
	add_child(hint)


func _draw_map() -> void:
	if _map_data.is_empty():
		return

	var total_layers := _map_data.size()
	# Draw from bottom (layer 0 = start) to top (last layer = final boss)
	# Map is vertically laid out: bottom = start, top = boss
	var map_height := total_layers * LAYER_HEIGHT
	var base_y := BOARD_H - 100.0  # Bottom of map area

	# Auto-scroll to keep current layer visible
	var current_y := base_y - _current_layer * LAYER_HEIGHT
	if current_y < 200:
		_scroll_offset = 200 - current_y

	# Draw subtle grid lines
	for i in range(0, int(BOARD_H), 40):
		_draw_panel.draw_line(
			Vector2(0, float(i)),
			Vector2(BOARD_W, float(i)),
			Color(0.1, 0.1, 0.15, 0.2), 1.0
		)

	# Draw connections first (behind nodes)
	for layer_idx in total_layers:
		var layer_nodes: Array = _map_data[layer_idx]
		var y := base_y - layer_idx * LAYER_HEIGHT + _scroll_offset

		for node_idx in layer_nodes.size():
			var node: Dictionary = layer_nodes[node_idx]
			var x := _get_node_x(layer_nodes.size(), node_idx)
			var connections: Array = node.get("connections", [])

			if layer_idx < total_layers - 1:
				var next_layer: Array = _map_data[layer_idx + 1]
				for conn_idx in connections:
					if conn_idx < next_layer.size():
						var next_x := _get_node_x(next_layer.size(), conn_idx)
						var next_y := base_y - (layer_idx + 1) * LAYER_HEIGHT + _scroll_offset
						var line_color := Color(0.3, 0.3, 0.4, 0.5)
						if node.get("cleared", false):
							line_color = Color(0.2, 0.5, 0.2, 0.4)
						_draw_panel.draw_line(Vector2(x, y), Vector2(next_x, next_y), line_color, 1.5)

	# Draw nodes
	for layer_idx in total_layers:
		var layer_nodes: Array = _map_data[layer_idx]
		var y := base_y - layer_idx * LAYER_HEIGHT + _scroll_offset

		for node_idx in layer_nodes.size():
			var node: Dictionary = layer_nodes[node_idx]
			var x := _get_node_x(layer_nodes.size(), node_idx)
			var node_type: int = node.get("type", 0)
			var is_cleared: bool = node.get("cleared", false)
			var is_current_layer := (layer_idx == _current_layer)
			var is_selected := (is_current_layer and node_idx == _selected_node)

			# Node circle
			var node_color := _get_node_color(node_type)
			var is_accessible := is_current_layer and (node_idx in _accessible_nodes)
			if is_cleared:
				node_color = Color(node_color.r, node_color.g, node_color.b, 0.3)
			elif is_current_layer and not is_accessible:
				node_color = Color(node_color.r * 0.3, node_color.g * 0.3, node_color.b * 0.3, 0.4)
			elif not is_current_layer and layer_idx > _current_layer:
				node_color = Color(node_color.r * 0.5, node_color.g * 0.5, node_color.b * 0.5, 0.5)
			if is_selected and is_accessible:
				# Selection glow
				_draw_panel.draw_circle(Vector2(x, y), NODE_RADIUS + 6, Color(1.0, 0.85, 0.2, 0.4))

			_draw_panel.draw_circle(Vector2(x, y), NODE_RADIUS, node_color)

			# Node icon/type text
			var font := ThemeDB.fallback_font
			var type_text: String = NODE_ICONS.get(node_type, "?")
			var text_size := font.get_string_size(type_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
			_draw_panel.draw_string(
				font,
				Vector2(x - text_size.x / 2.0, y + 5),
				type_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE
			)

			# Node type label below node
			var type_name: String = NODE_TYPE_NAMES.get(node_type, "?")
			var tn_size := font.get_string_size(type_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 9)
			var type_label_color := Color(0.5, 0.5, 0.6)
			if is_current_layer and not is_accessible:
				type_label_color = Color(0.3, 0.3, 0.35)
			_draw_panel.draw_string(
				font,
				Vector2(x - tn_size.x / 2.0, y + NODE_RADIUS + 14),
				type_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 9,
				type_label_color
			)

			# Floor number further below
			if is_current_layer or is_cleared:
				var floor_text := "F%d" % node.get("floor_num", 0)
				var ft_size := font.get_string_size(floor_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
				_draw_panel.draw_string(
					font,
					Vector2(x - ft_size.x / 2.0, y + NODE_RADIUS + 25),
					floor_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8,
					Color(0.4, 0.4, 0.5)
				)


func _get_node_x(count: int, idx: int) -> float:
	if count == 1:
		return BOARD_W / 2.0
	var total_span := float(count - 1) * 100.0
	var start_x := (BOARD_W - total_span) / 2.0
	return start_x + idx * 100.0


func _get_node_color(node_type: int) -> Color:
	match node_type:
		0: return Color(0.4, 0.4, 0.5)       # NORMAL
		1: return Color(0.8, 0.2, 0.2)        # ELITE
		2: return Color(0.6, 0.1, 0.1)        # BOSS
		3: return Color(0.2, 0.7, 0.3)        # SHOP
		4: return Color(0.5, 0.4, 0.8)        # EVENT
		5: return Color(0.2, 0.5, 0.7)        # REST
	return Color.WHITE


func _process(_delta: float) -> void:
	if not _input_ready:
		return
	if _map_data.is_empty() or _current_layer >= _map_data.size():
		return

	if _accessible_nodes.is_empty():
		return

	if Input.is_action_just_pressed("ui_up"):
		_cycle_selection(-1)
		_draw_panel.queue_redraw()
	elif Input.is_action_just_pressed("ui_down"):
		_cycle_selection(1)
		_draw_panel.queue_redraw()
	elif Input.is_action_just_pressed("launch") or Input.is_action_just_pressed("ui_accept"):
		_confirm()


func _cycle_selection(direction: int) -> void:
	if _accessible_nodes.is_empty():
		return
	var current_pos := _accessible_nodes.find(_selected_node)
	if current_pos < 0:
		current_pos = 0
	current_pos = (current_pos + direction + _accessible_nodes.size()) % _accessible_nodes.size()
	_selected_node = _accessible_nodes[current_pos]


func _confirm() -> void:
	if _current_layer < _map_data.size():
		if _selected_node in _accessible_nodes:
			node_selected.emit(_current_layer, _selected_node)
			queue_free()


func _compute_accessible_nodes() -> void:
	_accessible_nodes.clear()
	if _map_data.is_empty() or _current_layer >= _map_data.size():
		return

	var current_nodes: Array = _map_data[_current_layer]

	if _current_layer == 0:
		# Layer 0: all nodes are accessible
		for i in current_nodes.size():
			_accessible_nodes.append(i)
		return

	# For layer N > 0, only nodes connected from the cleared node in layer N-1
	if _last_cleared_node_idx < 0:
		# Fallback: all accessible
		for i in current_nodes.size():
			_accessible_nodes.append(i)
		return

	var prev_layer: Array = _map_data[_current_layer - 1]
	if _last_cleared_node_idx < prev_layer.size():
		var prev_node: Dictionary = prev_layer[_last_cleared_node_idx]
		var connections: Array = prev_node.get("connections", [])
		for conn_idx in connections:
			if conn_idx < current_nodes.size() and conn_idx not in _accessible_nodes:
				_accessible_nodes.append(conn_idx)
	_accessible_nodes.sort()

	# Fallback if no connections found
	if _accessible_nodes.is_empty():
		for i in current_nodes.size():
			_accessible_nodes.append(i)
