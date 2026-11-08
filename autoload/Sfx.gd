extends Node
# Toca os sons pré-renderizados (audio/*.wav, gerados por tools/gen_audio.py).
# Nada é sintetizado no celular: só carrega e toca.

const NAMES := ["pop", "bun", "click", "sizzle", "ready", "burnt", "trash", "bell", "coin",
	"good", "perfect", "bad", "angry", "nope", "buy", "fanfare", "levelup", "rush", "combo",
	"fries_ready", "fry", "pour"]

var sounds: Dictionary = {}
var players: Array = []
var music: AudioStreamPlayer
var grill: AudioStreamPlayer
var _next := 0


func _ready() -> void:
	for n in NAMES:
		sounds[n] = load("res://audio/%s.wav" % n)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	# o loop é definido na importação (audio/*.wav.import: edit/loop_mode=2).
	# Mudar loop_end em tempo de execução lia além do fim do áudio no Godot 4.7 e travava o app.
	music.stream = load("res://audio/music.wav")
	music.volume_db = -9.0
	add_child(music)
	grill = AudioStreamPlayer.new()
	grill.stream = load("res://audio/grill_loop.wav")
	grill.volume_db = -14.0
	add_child(grill)


func play(snd: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not Game.sfx_on or not sounds.has(snd):
		return
	var p: AudioStreamPlayer = players[_next]
	_next = (_next + 1) % players.size()
	p.stream = sounds[snd]
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()


func set_music(on: bool, fast: bool = false) -> void:
	music.pitch_scale = 1.12 if fast else 1.0
	if on and Game.music_on:
		if not music.playing:
			music.play()
	else:
		music.stop()


func set_grill(on: bool) -> void:
	if on and Game.sfx_on:
		if not grill.playing:
			grill.play()
	elif grill.playing:
		grill.stop()
