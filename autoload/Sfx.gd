extends Node
# Efeitos sonoros e musiquinha gerados por código (sem arquivos de áudio).

const RATE := 22050

var sounds: Dictionary = {}
var players: Array = []
var music: AudioStreamPlayer
var _next := 0


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	sounds["pop"] = _build([[620.0, 900.0, 0.07, "sine", 0.7]])
	sounds["bun"] = _build([[380.0, 560.0, 0.09, "tri", 0.8]])
	sounds["click"] = _build([[900.0, 700.0, 0.035, "square", 0.25]])
	sounds["trash"] = _build([[700.0, 120.0, 0.22, "noise", 0.45]])
	sounds["bell"] = _build([[1568.0, 1568.0, 0.12, "tri", 0.5], [2093.0, 2093.0, 0.3, "tri", 0.45]])
	sounds["coin"] = _build([[988.0, 988.0, 0.06, "square", 0.3], [1319.0, 1319.0, 0.16, "square", 0.3]])
	sounds["good"] = _build([[659.0, 659.0, 0.08, "square", 0.3], [784.0, 784.0, 0.14, "square", 0.3]])
	sounds["perfect"] = _build([[523.0, 523.0, 0.07, "square", 0.3], [659.0, 659.0, 0.07, "square", 0.3],
		[784.0, 784.0, 0.07, "square", 0.3], [1047.0, 1047.0, 0.22, "square", 0.32]])
	sounds["bad"] = _build([[330.0, 180.0, 0.32, "saw", 0.35]])
	sounds["angry"] = _build([[220.0, 140.0, 0.18, "square", 0.3], [180.0, 110.0, 0.25, "square", 0.3]])
	sounds["buy"] = _build([[784.0, 784.0, 0.06, "square", 0.3], [988.0, 988.0, 0.06, "square", 0.3],
		[1175.0, 1175.0, 0.06, "square", 0.3], [1568.0, 1568.0, 0.25, "tri", 0.4]])
	sounds["fanfare"] = _build([[523.0, 523.0, 0.12, "square", 0.3], [523.0, 523.0, 0.06, "square", 0.3],
		[659.0, 659.0, 0.12, "square", 0.3], [784.0, 784.0, 0.12, "square", 0.3], [1047.0, 1047.0, 0.4, "tri", 0.45]])
	sounds["nope"] = _build([[200.0, 200.0, 0.08, "square", 0.25], [160.0, 160.0, 0.12, "square", 0.25]])

	music = AudioStreamPlayer.new()
	music.stream = _build_music()
	music.volume_db = -14.0
	add_child(music)


func play(snd: String, pitch: float = 1.0) -> void:
	if not Game.sound or not sounds.has(snd):
		return
	var p: AudioStreamPlayer = players[_next]
	_next = (_next + 1) % players.size()
	p.stream = sounds[snd]
	p.pitch_scale = pitch
	p.play()


func set_music(on: bool) -> void:
	if on and Game.sound:
		if not music.playing:
			music.play()
	else:
		music.stop()


func _sample(wave: String, phase: float) -> float:
	match wave:
		"sine": return sin(phase * TAU)
		"square": return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		"saw": return fmod(phase, 1.0) * 2.0 - 1.0
		"tri": return abs(fmod(phase, 1.0) * 4.0 - 2.0) - 1.0
		"noise": return randf() * 2.0 - 1.0
	return 0.0


func _to_wav(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


# notes: [freq_inicial, freq_final, duração, forma de onda, volume]
func _build(notes: Array) -> AudioStreamWAV:
	var buf := PackedFloat32Array()
	for n in notes:
		var count := int(RATE * float(n[2]))
		var phase := 0.0
		for i in count:
			var t := float(i) / count
			var f: float = lerpf(n[0], n[1], t)
			phase += f / RATE
			var env := minf(1.0, i / (RATE * 0.004)) * pow(1.0 - t, 1.6)
			buf.append(_sample(n[3], phase) * env * float(n[4]))
	return _to_wav(buf)


func _build_music() -> AudioStreamWAV:
	# Loop alegre de 16 tempos (C - Am - F - G).
	var beat := 60.0 / 132.0 / 2.0
	var melody := [72, 76, 79, 76, 77, 76, 74, 72, 69, 72, 76, 72, 74, 72, 71, 67,
		65, 69, 72, 69, 70, 69, 67, 65, 67, 71, 74, 71, 72, 74, 76, 79]
	var bass := [48, 48, 55, 55, 45, 45, 52, 52, 41, 41, 48, 48, 43, 43, 50, 50]
	var total := int(RATE * beat * melody.size())
	var buf := PackedFloat32Array()
	buf.resize(total)
	var step_len := int(RATE * beat)
	for s in melody.size():
		var f := 440.0 * pow(2.0, (melody[s] - 69) / 12.0)
		var fb := 440.0 * pow(2.0, (bass[s / 2] - 69) / 12.0)
		for i in step_len:
			var idx := s * step_len + i
			if idx >= total:
				break
			var t := float(i) / step_len
			var env := pow(1.0 - t, 1.2) * minf(1.0, i / 60.0)
			var mel := _sample("square", f * idx / RATE) * 0.16 * env
			var bs := _sample("tri", fb * idx / RATE) * 0.3 * (1.0 - t * 0.5)
			buf[idx] = mel + bs
	return _to_wav(buf, true)
