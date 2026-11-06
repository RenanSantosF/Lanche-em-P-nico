extends Node

# AudioManager.gd - Procedural sound effects synthesizer and audio controller.

var players: Array[AudioStreamPlayer] = []
var max_concurrent: int = 8
var sound_enabled: bool = true
var sample_rate: int = 22050

var cached_samples: Dictionary = {}

func _ready() -> void:
	for i in range(max_concurrent):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

	_pregenerate_sounds()

func _pregenerate_sounds() -> void:
	cached_samples["ingredient_drop"] = _generate_drop_sound()
	cached_samples["sizzle"] = _generate_sizzle_sound()
	cached_samples["fryer"] = _generate_fryer_sound()
	cached_samples["pour"] = _generate_pour_sound()
	cached_samples["bell"] = _generate_bell_sound()
	cached_samples["coin"] = _generate_coin_sound()
	cached_samples["error"] = _generate_error_sound()
	cached_samples["cheer"] = _generate_cheer_sound()

func play_sfx(name: String, pitch_jitter: float = 0.05) -> void:
	if not sound_enabled:
		return
	if not cached_samples.has(name):
		return

	var stream = cached_samples[name]
	for p in players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
			p.play()
			return

	players[0].stream = stream
	players[0].pitch_scale = 1.0
	players[0].play()

func _create_stream_from_data(data: PackedByteArray) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _generate_drop_sound() -> AudioStreamWAV:
	var num_samples = int(sample_rate * 0.12)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var freq = lerp(220.0, 70.0, float(i) / float(num_samples))
		var envelope = exp(-28.0 * t)
		var sample_val = sin(t * freq * TAU) * envelope
		var byte_val = clampi(int((sample_val * 0.7 + 0.5) * 255.0), 0, 255)
		data[i] = byte_val
	return _create_stream_from_data(data)

func _generate_sizzle_sound() -> AudioStreamWAV:
	var num_samples = int(sample_rate * 0.4)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = sin(t / 0.4 * PI)
		var noise = randf_range(-1.0, 1.0)
		var sample_val = noise * env * 0.4
		var byte_val = clampi(int((sample_val + 0.5) * 255.0), 0, 255)
		data[i] = byte_val
	return _create_stream_from_data(data)

func _generate_fryer_sound() -> AudioStreamWAV:
	var num_samples = int(sample_rate * 0.5)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = sin(t / 0.5 * PI)
		var bubble = sin(t * 120.0 * TAU) * 0.3
		var noise = randf_range(-0.7, 0.7) * 0.7
		var sample_val = (bubble + noise) * env * 0.45
		var byte_val = clampi(int((sample_val + 0.5) * 255.0), 0, 255)
		data[i] = byte_val
	return _create_stream_from_data(data)

func _generate_pour_sound() -> AudioStreamWAV:
	var num_samples = int(sample_rate * 0.35)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var freq = lerp(300.0, 600.0, float(i) / float(num_samples))
		var env = exp(-8.0 * (0.35 - t))
		var sample_val = (sin(t * freq * TAU) * 0.4 + randf_range(-0.3, 0.3)) * env
		var byte_val = clampi(int((sample_val + 0.5) * 255.0), 0, 255)
		data[i] = byte_val
	return _create_stream_from_data(data)

func _generate_bell_sound() -> AudioStreamWAV:
	var num_samples = int(sample_rate * 0.3)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-12.0 * t)
		var sample_val = (sin(t * 1200.0 * TAU) + 0.5 * sin(t * 2400.0 * TAU)) * env * 0.4
		var byte_val = clampi(int((sample_val + 0.5) * 255.0), 0, 255)
		data[i] = byte_val
	return _create_stream_from_data(data)

func _generate_coin_sound() -> AudioStreamWAV:
	var num_samples = int(sample_rate * 0.22)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var freq = 987.77 if t < 0.1 else 1318.51
		var env = exp(-10.0 * t)
		var sample_val = sin(t * freq * TAU) * env * 0.4
		var byte_val = clampi(int((sample_val + 0.5) * 255.0), 0, 255)
		data[i] = byte_val
	return _create_stream_from_data(data)

func _generate_error_sound() -> AudioStreamWAV:
	var num_samples = int(sample_rate * 0.25)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-8.0 * t)
		var sample_val = (sin(t * 160.0 * TAU) + sin(t * 150.0 * TAU)) * env * 0.4
		var byte_val = clampi(int((sample_val + 0.5) * 255.0), 0, 255)
		data[i] = byte_val
	return _create_stream_from_data(data)

func _generate_cheer_sound() -> AudioStreamWAV:
	var num_samples = int(sample_rate * 0.4)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = sin(t / 0.4 * PI)
		var tone = sin(t * (523.25 + sin(t * 20.0) * 80.0) * TAU) * 0.35
		var sample_val = tone * env
		var byte_val = clampi(int((sample_val + 0.5) * 255.0), 0, 255)
		data[i] = byte_val
	return _create_stream_from_data(data)
