class_name BoardFrame
extends Node2D

## Decorative neon frame around the pachinko board.
## Draws metallic border + pulsing neon glow effect.

var board_width: float = 540.0
var board_height: float = 960.0

var _glow_phase: float = 0.0

const FRAME_WIDTH: float = 6.0
const METAL_COLOR := Color(0.35, 0.32, 0.25)
const NEON_COLOR := Color(0.1, 0.6, 1.0)
const NEON_COLOR_2 := Color(1.0, 0.3, 0.6)


func _process(delta: float) -> void:
	_glow_phase += delta * 2.0
	if _glow_phase > TAU:
		_glow_phase -= TAU
	queue_redraw()


func _draw() -> void:
	var w := board_width
	var h := board_height
	var fw := FRAME_WIDTH

	# Outer metallic border
	# Top
	draw_rect(Rect2(0, 0, w, fw), METAL_COLOR)
	# Bottom
	draw_rect(Rect2(0, h - fw, w, fw), METAL_COLOR)
	# Left
	draw_rect(Rect2(0, 0, fw, h), METAL_COLOR)
	# Right
	draw_rect(Rect2(w - fw, 0, fw, h), METAL_COLOR)

	# Inner highlight line
	var highlight := Color(0.5, 0.45, 0.3, 0.6)
	draw_rect(Rect2(fw, fw, w - fw * 2, 1), highlight)
	draw_rect(Rect2(fw, h - fw - 1, w - fw * 2, 1), highlight)
	draw_rect(Rect2(fw, fw, 1, h - fw * 2), highlight)
	draw_rect(Rect2(w - fw - 1, fw, 1, h - fw * 2), highlight)

	# Neon glow strips (pulsing)
	var glow_alpha := 0.15 + 0.1 * sin(_glow_phase)
	var glow2_alpha := 0.15 + 0.1 * sin(_glow_phase + PI)

	# Top neon
	draw_rect(Rect2(fw + 2, fw + 2, w - fw * 2 - 4, 2),
		Color(NEON_COLOR.r, NEON_COLOR.g, NEON_COLOR.b, glow_alpha))
	# Bottom neon
	draw_rect(Rect2(fw + 2, h - fw - 4, w - fw * 2 - 4, 2),
		Color(NEON_COLOR_2.r, NEON_COLOR_2.g, NEON_COLOR_2.b, glow2_alpha))
	# Left neon
	draw_rect(Rect2(fw + 2, fw + 4, 2, h - fw * 2 - 8),
		Color(NEON_COLOR.r, NEON_COLOR.g, NEON_COLOR.b, glow_alpha))
	# Right neon
	draw_rect(Rect2(w - fw - 4, fw + 4, 2, h - fw * 2 - 8),
		Color(NEON_COLOR.r, NEON_COLOR.g, NEON_COLOR.b, glow_alpha))

	# Corner accents
	_draw_corner_accent(Vector2(fw, fw), glow_alpha)
	_draw_corner_accent(Vector2(w - fw, fw), glow_alpha)
	_draw_corner_accent(Vector2(fw, h - fw), glow2_alpha)
	_draw_corner_accent(Vector2(w - fw, h - fw), glow2_alpha)


func _draw_corner_accent(pos: Vector2, alpha: float) -> void:
	draw_circle(pos, 4.0, Color(NEON_COLOR.r, NEON_COLOR.g, NEON_COLOR.b, alpha * 2.0), true, -1.0, true)
	draw_circle(pos, 2.0, Color(1.0, 1.0, 1.0, alpha * 1.5), true, -1.0, true)
