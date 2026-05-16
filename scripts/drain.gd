class_name Drain
extends Area2D

var board_width: float = 540.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(board_width, 30)
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball") and body.has_method("lost"):
		# Insurance relic: chance to save the ball
		if is_instance_valid(RelicManager):
			var save_chance: float = RelicManager.get_modifier("drain_save_chance", 0.0)
			if save_chance > 0.0 and randf() < save_chance:
				if body.has_method("captured"):
					body.captured(false, 1)
					return
		AudioManager.play_drain()
		body.lost()


func _draw() -> void:
	draw_rect(
		Rect2(-board_width / 2.0, -15, board_width, 30),
		Color(0.3, 0.05, 0.05, 0.4)
	)
