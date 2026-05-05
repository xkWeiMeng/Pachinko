class_name TitleScreen
extends CanvasLayer

## Title screen shown before gameplay starts.
## Press space or click to start the game.

signal start_requested

var _title_label: Label
var _prompt_label: Label
var _high_score_label: Label
var _bg: ColorRect
var _prompt_alpha: float = 1.0
var _prompt_dir: float = -1.0


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Full-screen dark background
	_bg = ColorRect.new()
	_bg.color = Color(0.005, 0.0, 0.03)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	# Title
	_title_label = Label.new()
	_title_label.text = "パチンコ"
	_title_label.add_theme_font_size_override("font_size", 56)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.size = Vector2(540, 70)
	_title_label.position = Vector2(0, 280)
	add_child(_title_label)

	# Subtitle
	var sub := Label.new()
	sub.text = "P A C H I N K O"
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.6, 0.55, 0.2))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(540, 30)
	sub.position = Vector2(0, 360)
	add_child(sub)

	# Decorative line
	var line := ColorRect.new()
	line.color = Color(0.5, 0.4, 0.1, 0.6)
	line.size = Vector2(200, 2)
	line.position = Vector2(170, 400)
	add_child(line)

	# High score
	_high_score_label = Label.new()
	_high_score_label.text = "BEST  %d" % GameState.high_score
	_high_score_label.add_theme_font_size_override("font_size", 14)
	_high_score_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_high_score_label.size = Vector2(540, 20)
	_high_score_label.position = Vector2(0, 420)
	add_child(_high_score_label)

	# Start prompt (pulsing)
	_prompt_label = Label.new()
	_prompt_label.text = "PRESS  SPACE  TO  START"
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_prompt_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.size = Vector2(540, 30)
	_prompt_label.position = Vector2(0, 550)
	add_child(_prompt_label)

	# Controls hint
	var controls := Label.new()
	controls.text = "Hold SPACE or LMB to charge • Release to launch"
	controls.add_theme_font_size_override("font_size", 10)
	controls.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.size = Vector2(540, 20)
	controls.position = Vector2(0, 620)
	add_child(controls)


func _process(delta: float) -> void:
	# Pulse the prompt text
	_prompt_alpha += _prompt_dir * delta * 1.5
	if _prompt_alpha <= 0.3:
		_prompt_dir = 1.0
	elif _prompt_alpha >= 1.0:
		_prompt_dir = -1.0
	_prompt_label.modulate.a = _prompt_alpha

	# Check for start input
	if Input.is_action_just_pressed("launch"):
		start_requested.emit()
