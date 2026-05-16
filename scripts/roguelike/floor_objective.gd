class_name FloorObjective
extends RefCounted

signal objective_completed

enum Type { TARGET_SCORE, CAPTURES, COMBO, SURVIVAL, ALL_CUPS }

var type: Type = Type.TARGET_SCORE
var target_value: int = 0
var current_value: int = 0
var completed: bool = false
var _start_time: float = 0.0


static func generate(floor_num: int, act: int, rng: RandomNumberGenerator) -> FloorObjective:
	var obj := FloorObjective.new()
	var roll := rng.randf()
	# Weighted distribution based on floor/act
	if roll < 0.35:
		obj.type = Type.TARGET_SCORE
	elif roll < 0.55:
		obj.type = Type.CAPTURES
	elif roll < 0.70:
		obj.type = Type.COMBO
	elif roll < 0.85:
		obj.type = Type.SURVIVAL
	else:
		obj.type = Type.ALL_CUPS

	match obj.type:
		Type.TARGET_SCORE:
			obj.target_value = 300 + floor_num * 200
		Type.CAPTURES:
			obj.target_value = 3 + floor_num * 1
		Type.COMBO:
			obj.target_value = 3 + floori(floor_num / 3.0)
		Type.SURVIVAL:
			obj.target_value = 20 + floor_num * 3
		Type.ALL_CUPS:
			# Will be set by RunManager once cups are known
			obj.target_value = 5

	return obj


func start() -> void:
	_start_time = Time.get_ticks_msec() / 1000.0
	current_value = 0
	completed = false


func update(event_type: String, value: int = 1) -> void:
	if completed:
		return

	match type:
		Type.TARGET_SCORE:
			if event_type == "score":
				current_value += value
		Type.CAPTURES:
			if event_type == "capture":
				current_value += value
		Type.COMBO:
			if event_type == "combo":
				current_value = maxi(current_value, value)
		Type.SURVIVAL:
			if event_type == "time":
				current_value = value
		Type.ALL_CUPS:
			if event_type == "unique_cup":
				current_value = value

	if check_completed():
		completed = true
		objective_completed.emit()


func check_completed() -> bool:
	return current_value >= target_value


func get_description() -> String:
	match type:
		Type.TARGET_SCORE:
			return "Score %d points" % target_value
		Type.CAPTURES:
			return "Capture %d balls" % target_value
		Type.COMBO:
			return "Reach %d combo" % target_value
		Type.SURVIVAL:
			return "Survive %d seconds" % target_value
		Type.ALL_CUPS:
			return "Hit %d different cups" % target_value
	return ""


func get_progress_text() -> String:
	return "%d/%d" % [mini(current_value, target_value), target_value]
