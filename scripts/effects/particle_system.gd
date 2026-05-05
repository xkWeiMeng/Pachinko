class_name ParticleSystem
extends Node2D

const MAX_PARTICLES: int = 200

var _pool: Array = []
var _alive_count: int = 0


func _ready() -> void:
	for i in MAX_PARTICLES:
		_pool.append(_make_particle())


func _process(delta: float) -> void:
	_alive_count = 0
	for p in _pool:
		if not p["alive"]:
			continue
		_alive_count += 1
		p["lifetime"] -= delta
		if p["lifetime"] <= 0.0:
			p["alive"] = false
			continue
		p["velocity"].y += p["gravity"] * delta
		p["position"] += p["velocity"] * delta
	if _alive_count > 0:
		queue_redraw()


func _draw() -> void:
	for p in _pool:
		if not p["alive"]:
			continue
		var t: float = p["lifetime"] / p["max_lifetime"]
		var c: Color = p["color"]
		c.a *= t
		var local_pos: Vector2 = p["position"] - global_position
		draw_circle(local_pos, p["size"] * t, c)


func emit_burst(pos: Vector2, count: int, config: Dictionary) -> void:
	var color: Color = config.get("color", Color.WHITE)
	var speed: float = config.get("speed", 100.0)
	var lifetime: float = config.get("lifetime", 0.5)
	var size: float = config.get("size", 2.0)
	var gravity: float = config.get("gravity", 300.0)
	var spread: float = config.get("spread", TAU)
	var direction: Vector2 = config.get("direction", Vector2.UP)
	var base_angle: float = direction.angle()

	for i in count:
		var p: Variant = _acquire()
		if p == null:
			return
		var angle: float = base_angle + randf_range(-spread * 0.5, spread * 0.5)
		var spd: float = speed * randf_range(0.5, 1.0)
		p["position"] = pos
		p["velocity"] = Vector2(cos(angle), sin(angle)) * spd
		p["color"] = color
		p["lifetime"] = lifetime * randf_range(0.7, 1.0)
		p["max_lifetime"] = p["lifetime"]
		p["size"] = size * randf_range(0.8, 1.2)
		p["gravity"] = gravity
		p["alive"] = true


func emit_trail(pos: Vector2, config: Dictionary) -> void:
	var p: Variant = _acquire()
	if p == null:
		return
	var color: Color = config.get("color", Color.WHITE)
	var speed: float = config.get("speed", 0.0)
	var lifetime: float = config.get("lifetime", 0.15)
	var size: float = config.get("size", 4.0)
	var gravity: float = config.get("gravity", 0.0)
	var spread: float = config.get("spread", TAU)
	var direction: Vector2 = config.get("direction", Vector2.UP)
	var base_angle: float = direction.angle()
	var angle: float = base_angle + randf_range(-spread * 0.5, spread * 0.5)

	p["position"] = pos
	p["velocity"] = Vector2(cos(angle), sin(angle)) * speed
	p["color"] = color
	p["lifetime"] = lifetime
	p["max_lifetime"] = lifetime
	p["size"] = size
	p["gravity"] = gravity
	p["alive"] = true


func _acquire() -> Variant:
	for p in _pool:
		if not p["alive"]:
			return p
	return null


func _make_particle() -> Dictionary:
	return {
		"alive": false,
		"position": Vector2.ZERO,
		"velocity": Vector2.ZERO,
		"color": Color.WHITE,
		"lifetime": 0.0,
		"max_lifetime": 1.0,
		"size": 2.0,
		"gravity": 300.0,
	}


static func pin_spark() -> Dictionary:
	return {"color": Color(1.0, 0.9, 0.4), "speed": 120.0, "lifetime": 0.2, "size": 2.0, "gravity": 100.0}


static func capture_stars() -> Dictionary:
	return {"color": Color(0.3, 0.7, 1.0), "speed": 200.0, "lifetime": 0.5, "size": 3.0, "gravity": 200.0, "direction": Vector2.UP, "spread": PI * 0.6}


static func jackpot_firework() -> Dictionary:
	return {"color": Color(1.0, 0.85, 0.0), "speed": 350.0, "lifetime": 2.0, "size": 3.5, "gravity": 150.0}


static func ball_trail() -> Dictionary:
	return {"color": Color(0.85, 0.85, 0.92, 0.4), "speed": 0.0, "lifetime": 0.15, "size": 4.0, "gravity": 0.0}
