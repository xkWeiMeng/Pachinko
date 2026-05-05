class_name ScreenShake
extends Camera2D

var _shake_intensity: float = 0.0
var _shake_remaining: float = 0.0
var _shake_duration: float = 0.0


func _ready() -> void:
	position = Vector2(270, 480)
	make_current()


func _process(delta: float) -> void:
	if _shake_remaining <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_remaining -= delta
	var t: float = _shake_remaining / _shake_duration
	var current_intensity: float = _shake_intensity * t
	offset = Vector2(
		randf_range(-current_intensity, current_intensity),
		randf_range(-current_intensity, current_intensity)
	)


func shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_remaining = duration
