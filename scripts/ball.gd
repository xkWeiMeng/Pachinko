class_name PachinkoBall
extends RigidBody2D

const RADIUS: float = 8.0
const BALL_COLOR := Color(0.85, 0.85, 0.92)
const HIGHLIGHT_COLOR := Color(1.0, 1.0, 1.0, 0.65)
const COLLISION_THRESHOLD: float = 200.0
const TRAIL_LENGTH: int = 6

var _trail_positions: Array[Vector2] = []


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	can_sleep = false
	z_index = 3
	add_to_group("ball")

	collision_layer = 1
	collision_mask = 0b1111
	linear_damp = 0.5  # Simulates channel friction + air drag

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.8
	# Apply bounce_bonus relic modifier
	if is_instance_valid(RelicManager):
		var bounce_bonus: float = RelicManager.get_modifier("bounce_bonus", 0.0)
		mat.bounce = clampf(mat.bounce + bounce_bonus, 0.0, 1.0)
	mat.friction = 0.1
	physics_material_override = mat

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	# Apply ball_mass_mult relic modifier
	if is_instance_valid(RelicManager):
		var mass_mult: float = RelicManager.get_modifier("ball_mass_mult", 1.0)
		if mass_mult != 1.0:
			mass *= mass_mult

	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	_trail_positions.push_front(global_position)
	if _trail_positions.size() > TRAIL_LENGTH:
		_trail_positions.resize(TRAIL_LENGTH)
	if is_instance_valid(RelicManager):
		# Near-cup slowdown from sticky_shell relic
		var slowdown: float = RelicManager.get_modifier("near_cup_slowdown", 0.0)
		if slowdown > 0.0 and global_position.y > 700.0:
			linear_velocity *= (1.0 - slowdown * _delta * 2.0)
		# Wind force from elite modifier
		if is_instance_valid(GameState):
			var wind: float = GameState.wind_force
			if wind != 0.0:
				linear_velocity.x += wind * _delta
	queue_redraw()


func _draw() -> void:
	# Trail
	for i in range(_trail_positions.size()):
		var alpha := 0.3 * (1.0 - float(i) / TRAIL_LENGTH)
		var trail_pos := _trail_positions[i] - global_position
		draw_circle(trail_pos, RADIUS * 0.7, Color(0.85, 0.85, 0.92, alpha))
	# Ball
	draw_circle(Vector2(1.5, 2.0), RADIUS, Color(0.0, 0.0, 0.0, 0.3))
	draw_circle(Vector2.ZERO, RADIUS, BALL_COLOR, true, -1.0, true)
	draw_circle(
		Vector2(-RADIUS * 0.28, -RADIUS * 0.3), RADIUS * 0.38,
		HIGHLIGHT_COLOR, true, -1.0, true
	)
	draw_circle(
		Vector2(-RADIUS * 0.42, -RADIUS * 0.44), RADIUS * 0.12,
		Color(1.0, 1.0, 1.0, 0.9), true, -1.0, true
	)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("peg"):
		# Pin phase chance (ghost_core relic)
		if is_instance_valid(RelicManager):
			var phase_chance: float = RelicManager.get_modifier("pin_phase_chance", 0.0)
			if phase_chance > 0.0 and randf() < phase_chance:
				return  # Phase through pin — skip hit
		EventBus.peg_hit.emit(body, self)
		AudioManager.play_pin_hit(randf_range(0.8, 1.2))
		# Pin hit score (midas_touch relic)
		if is_instance_valid(RelicManager):
			var pin_score: int = RelicManager.get_modifier("pin_hit_score", 0)
			if pin_score > 0:
				GameState.add_score(pin_score)


func captured(is_crit: bool, reward: int = 15) -> void:
	EventBus.ball_captured.emit(reward, is_crit, self)
	queue_free()


func lost() -> void:
	EventBus.ball_lost.emit(self)
	queue_free()
