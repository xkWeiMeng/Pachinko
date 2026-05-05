extends Node

const POOL_SIZE: int = 10
const SAMPLE_RATE: int = 44100

var _player_pool: Array[AudioStreamPlayer] = []
var _stream_pin_hit: AudioStreamWAV
var _stream_capture: AudioStreamWAV
var _stream_drain: AudioStreamWAV
var _stream_launch: AudioStreamWAV
var _stream_jackpot: AudioStreamWAV


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_player_pool.append(p)

	_stream_pin_hit = _create_pin_hit_stream()
	_stream_capture = _create_capture_stream()
	_stream_drain = _create_drain_stream()
	_stream_launch = _create_launch_stream()
	_stream_jackpot = _create_jackpot_stream()

	EventBus.jackpot_hit.connect(play_jackpot)


func play_pin_hit(pitch: float = 1.0) -> void:
	_play_stream(_stream_pin_hit, -6.0, pitch)


func play_capture() -> void:
	_play_stream(_stream_capture, 0.0)


func play_drain() -> void:
	_play_stream(_stream_drain, -3.0)


func play_launch() -> void:
	_play_stream(_stream_launch, -2.0)


func play_jackpot() -> void:
	_play_stream(_stream_jackpot, 3.0)


func _play_stream(stream: AudioStreamWAV, volume_db: float, pitch: float = 1.0) -> void:
	for p in _player_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


# --- Stream generators ---

func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav


func _encode_sample(value: float) -> PackedByteArray:
	var s := clampi(int(value * 32767.0), -32768, 32767)
	var buf := PackedByteArray()
	buf.resize(2)
	buf.encode_s16(0, s)
	return buf


# Pin hit: sine decay at random-ish freq, 0.05s
func _create_pin_hit_stream() -> AudioStreamWAV:
	var freq := 1000.0
	var duration := 0.05
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var envelope := 1.0 - (t / duration)
		var value := sin(TAU * freq * t) * envelope
		data.append_array(_encode_sample(value))
	return _make_wav(data)


# Capture: rising sine 400→800Hz, 0.15s
func _create_capture_stream() -> AudioStreamWAV:
	var duration := 0.15
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	var phase := 0.0
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var progress := t / duration
		var freq := lerpf(400.0, 800.0, progress)
		var envelope := (1.0 - progress) * (0.5 + 0.5 * sin(PI * progress))
		phase += TAU * freq / SAMPLE_RATE
		var value := sin(phase) * envelope
		data.append_array(_encode_sample(value))
	return _make_wav(data)


# Drain: low pulse at 150Hz, 0.1s
func _create_drain_stream() -> AudioStreamWAV:
	var freq := 150.0
	var duration := 0.1
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var envelope := 1.0 - (t / duration)
		# Square-ish pulse: clamp sine to ±0.6 for thicker sound
		var raw := sin(TAU * freq * t)
		var value := clampf(raw * 2.0, -0.6, 0.6) * envelope
		data.append_array(_encode_sample(value))
	return _make_wav(data)


# Launch: noise→sine sweep 200→400Hz, 0.2s
func _create_launch_stream() -> AudioStreamWAV:
	var duration := 0.2
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	var phase := 0.0
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var progress := t / duration
		var freq := lerpf(200.0, 400.0, progress)
		phase += TAU * freq / SAMPLE_RATE
		var noise := randf_range(-1.0, 1.0)
		var sine := sin(phase)
		# Blend from noise to sine over duration
		var blend := progress
		var value := lerpf(noise, sine, blend) * (1.0 - progress * 0.5)
		data.append_array(_encode_sample(value))
	return _make_wav(data)


# Jackpot: four-note arpeggio C5-E5-G5-C6, 1.0s total
func _create_jackpot_stream() -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99, 1046.50]  # C5, E5, G5, C6
	var total_duration := 1.0
	var note_duration := total_duration / notes.size()
	var total_samples := int(SAMPLE_RATE * total_duration)
	var data := PackedByteArray()
	var phase := 0.0
	for i in total_samples:
		var t := float(i) / SAMPLE_RATE
		var note_idx := mini(int(t / note_duration), notes.size() - 1)
		var note_t := t - note_idx * note_duration
		var freq: float = notes[note_idx]
		phase += TAU * freq / SAMPLE_RATE
		# Per-note envelope: quick attack, smooth decay
		var env := maxf(0.0, 1.0 - note_t / note_duration) * (1.0 - exp(-note_t * 40.0))
		# Add a light harmonic for richness
		var value := (sin(phase) * 0.8 + sin(phase * 2.0) * 0.2) * env
		data.append_array(_encode_sample(value))
	return _make_wav(data)
