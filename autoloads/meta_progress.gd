extends Node

## Persistent meta-progression across runs, saved to user://meta.cfg

var total_runs: int = 0
var total_wins: int = 0
var best_floor: int = 0
var best_score: int = 0
var unlocked_relics: Array[String] = []
var achievements: Dictionary = {}

const ACHIEVEMENT_DEFS: Array[Dictionary] = [
	{"id": "first_run", "name": "初次涉足", "desc": "Complete first run"},
	{"id": "perfect_floor", "name": "完美层", "desc": "0 balls lost in one floor"},
	{"id": "first_jackpot", "name": "Jackpot!", "desc": "Hit first jackpot"},
	{"id": "ball_tycoon", "name": "弹珠大亨", "desc": "Hold 200+ balls in one run"},
	{"id": "speedrunner", "name": "速通达人", "desc": "Clear a floor in 30 seconds"},
	{"id": "last_stand", "name": "背水一战", "desc": "Clear a floor with ≤3 balls"},
	{"id": "collector", "name": "收藏家", "desc": "Hold 10+ relics in one run"},
	{"id": "god_slayer", "name": "弹珠之神", "desc": "Defeat the final boss"},
]


func _ready() -> void:
	_load()


func record_run_end(won: bool, stats: Dictionary) -> void:
	total_runs += 1
	if won:
		total_wins += 1
	best_floor = maxi(best_floor, stats.get("floors_cleared", 0))
	best_score = maxi(best_score, stats.get("final_score", 0))
	_check_achievements(stats, won)
	_save()


func check_floor_achievement(floor_stats: Dictionary) -> void:
	if floor_stats.get("balls_lost", 0) == 0:
		achievements["perfect_floor"] = true
	if floor_stats.get("clear_time", 999.0) <= 30.0:
		achievements["speedrunner"] = true
	if floor_stats.get("balls_remaining", 999) <= 3:
		achievements["last_stand"] = true
	_save()


func unlock_relic(relic_id: String) -> void:
	if relic_id not in unlocked_relics:
		unlocked_relics.append(relic_id)
		_save()


func _check_achievements(stats: Dictionary, won: bool) -> void:
	if total_runs >= 1:
		achievements["first_run"] = true
	if won and stats.get("floors_cleared", 0) >= 16:
		achievements["god_slayer"] = true
	if stats.get("total_jackpots", 0) > 0:
		achievements["first_jackpot"] = true
	if stats.get("relics_collected", 0) >= 10:
		achievements["collector"] = true
	if stats.get("max_balls", 0) >= 200:
		achievements["ball_tycoon"] = true


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "total_runs", total_runs)
	cfg.set_value("meta", "total_wins", total_wins)
	cfg.set_value("meta", "best_floor", best_floor)
	cfg.set_value("meta", "best_score", best_score)
	cfg.set_value("meta", "unlocked_relics", unlocked_relics)
	cfg.set_value("meta", "achievements", achievements)
	cfg.save("user://meta.cfg")


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://meta.cfg") == OK:
		total_runs = cfg.get_value("meta", "total_runs", 0)
		total_wins = cfg.get_value("meta", "total_wins", 0)
		best_floor = cfg.get_value("meta", "best_floor", 0)
		best_score = cfg.get_value("meta", "best_score", 0)
		unlocked_relics = cfg.get_value("meta", "unlocked_relics", [])
		achievements = cfg.get_value("meta", "achievements", {})
