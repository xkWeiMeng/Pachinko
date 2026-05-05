class_name BottomBar
extends CanvasLayer

## Bottom button bar with Back, Left, Right, Launch buttons.
## Manages touch-based launcher charging and board switching indicators.

signal back_pressed
signal switch_board(direction: int)
signal launch_hold_started
signal launch_hold_ended

const BarPanelScript = preload("res://scripts/bar_panel.gd")

var _panel: Control
var board_count: int = 3


func _ready() -> void:
	layer = 10
	_panel = BarPanelScript.new()
	_panel.board_count = board_count
	_panel.button_pressed.connect(_on_button)
	_panel.launch_hold_started.connect(func(): launch_hold_started.emit())
	_panel.launch_hold_ended.connect(func(): launch_hold_ended.emit())
	add_child(_panel)


func set_current_board(idx: int) -> void:
	_panel.current_board = idx
	_panel.queue_redraw()


func set_board_info(idx: int, board_name: String) -> void:
	_panel.current_board = idx
	_panel.board_name = board_name
	_panel.queue_redraw()


func _on_button(index: int) -> void:
	match index:
		0: back_pressed.emit()
		1: switch_board.emit(-1)
		2: switch_board.emit(1)
