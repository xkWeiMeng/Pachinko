class_name PinGrid
extends Node2D

const PinScript = preload("res://scripts/pin.gd")

@export var rows: int = 12
@export var cols: int = 9
@export var h_spacing: float = 45.0

var v_spacing: float


func _ready() -> void:
	v_spacing = h_spacing * sqrt(3.0) / 2.0
	_generate_grid()


func _generate_grid() -> void:
	for row in range(rows):
		var row_cols := cols if row % 2 == 0 else cols - 1
		var x_offset := 0.0 if row % 2 == 0 else h_spacing / 2.0

		for col in range(row_cols):
			var pin = PinScript.new()
			var x := x_offset + col * h_spacing
			var y := row * v_spacing
			pin.position = Vector2(x, y)
			add_child(pin)
