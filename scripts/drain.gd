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
		# Golden drain relic: treat drain as a low-reward cup
		if is_instance_valid(RelicManager):
			var golden: bool = RelicManager.get_modifier("golden_drain", false)
			if golden and body.has_method("captured"):
				body.captured(false, 1)
				GameState.add_score(10)
				return
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
	# Golden drain visual when relic is active
	var is_golden: bool = is_instance_valid(RelicManager) and RelicManager.get_modifier("golden_drain", false)
	var color: Color = Color(0.8, 0.7, 0.1, 0.5) if is_golden else Color(0.3, 0.05, 0.05, 0.4)
	draw_rect(
		Rect2(-board_width / 2.0, -15, board_width, 30),
		color
	)
