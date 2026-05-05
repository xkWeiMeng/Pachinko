extends Node

const POOL_SIZE: int = 10
var _player_pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_player_pool.append(p)


func play_pin_hit(pitch: float = 1.0) -> void:
	_play_with_pitch(pitch, -6.0)


func play_capture() -> void:
	_play(0.0)


func play_drain() -> void:
	_play(-3.0)


func play_launch() -> void:
	_play(-2.0)


func play_jackpot() -> void:
	_play(3.0)


func _play(volume_db: float) -> void:
	for p in _player_pool:
		if not p.playing:
			p.volume_db = volume_db
			p.play()
			return


func _play_with_pitch(pitch: float, volume_db: float) -> void:
	for p in _player_pool:
		if not p.playing:
			p.pitch_scale = pitch
			p.volume_db = volume_db
			p.play()
			return
