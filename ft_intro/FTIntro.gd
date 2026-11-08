extends Control
# Intro animada da FT (vinheta de abertura de todos os jogos).
# Uso em outro projeto: copie a pasta ft_intro/, coloque FTIntro.tscn como cena
# principal e defina `next_scene` com a cena do jogo. Toque na tela pula a intro.

const Logo = preload("res://ft_intro/FTLogo.gd")
const DURATION := 3.0

@export_file("*.tscn") var next_scene: String = "res://scenes/Main.tscn"
@export var play_sound: bool = true
@export var auto_continue: bool = true

var t: float = 0.0
var _done: bool = false
var _sparks: Array = []
var _player: AudioStreamPlayer


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 10:
		var a := rng.randf() * TAU
		_sparks.append({"a": a, "d": rng.randf_range(0.62, 0.95), "t": 1.0 + rng.randf() * 0.7, "s": rng.randf_range(0.6, 1.2)})
	if play_sound:
		_player = AudioStreamPlayer.new()
		_player.stream = load("res://ft_intro/ft_jingle.wav")
		add_child(_player)
		_player.play()
	# pré-carrega a próxima cena em segundo plano enquanto a intro roda
	if next_scene != "" and ResourceLoader.exists(next_scene):
		ResourceLoader.load_threaded_request(next_scene)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and t > 0.8:
		t = maxf(t, DURATION - 0.35)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t >= DURATION and not _done and auto_continue:
		_done = true
		_go_next()


func _go_next() -> void:
	if next_scene == "":
		return
	var packed = ResourceLoader.load_threaded_get(next_scene)
	if packed is PackedScene:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(next_scene)


static func ease_back(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Logo.BG)
	var center := Vector2(w / 2, h / 2)
	var logo_size := minf(w, h) * 0.5
	# grade de circuito sutil no fundo
	var grid_a := clampf(t / 0.6, 0.0, 1.0) * 0.06
	var step := logo_size / 4.0
	var gx := fmod(center.x, step)
	while gx < w:
		draw_line(Vector2(gx, 0), Vector2(gx, h), Color(Logo.TRACE, grid_a), 1.0)
		gx += step
	var gy := fmod(center.y, step)
	while gy < h:
		draw_line(Vector2(0, gy), Vector2(w, gy), Color(Logo.TRACE, grid_a), 1.0)
		gy += step
	var badge := ease_back((t - 0.1) / 0.45)
	var drawp := clampf((t - 0.35) / 0.75, 0.0, 1.0)
	var node := ease_back((t - 1.0) / 0.3) if t > 1.0 else 0.0
	var glow := clampf((t - 1.0) / 0.3, 0.0, 1.0) * (0.7 + 0.3 * sin(t * 4.0))
	# onda de choque quando o nó acende
	if t > 1.0 and t < 1.7:
		var k := (t - 1.0) / 0.7
		draw_arc(center, logo_size * (0.5 + k * 0.7), 0, TAU, 64, Color(Logo.EDGE, 0.6 * (1.0 - k)), 3.0 + 6.0 * (1.0 - k), true)
	# luz colorida atrás do logo
	var halo := clampf((t - 0.3) / 0.8, 0.0, 1.0)
	if halo > 0.0:
		for k in 4:
			var col: Color = Logo.PALETTE[(k + int(t * 2.0)) % Logo.PALETTE.size()]
			draw_circle(center, logo_size * (0.95 - k * 0.12), Color(col, 0.05 * halo))
	# explosão de pontinhos coloridos quando o nó acende
	if t > 1.0 and t < 2.2:
		var k2 := (t - 1.0) / 1.2
		for i in 18:
			var a := TAU * i / 18.0 + 0.3
			var p := center + Vector2(cos(a), sin(a)) * logo_size * (0.55 + k2 * 0.6)
			draw_circle(p, logo_size * 0.018 * (1.0 - k2), Color(Logo.PALETTE[i % Logo.PALETTE.size()], 1.0 - k2))
	Logo.draw_logo(self, center, logo_size, drawp, badge, node, glow)
	# brilhinhos
	for s in _sparks:
		var k: float = (t - s["t"]) / 0.6
		if k > 0.0 and k < 1.0:
			var p: Vector2 = center + Vector2(cos(s["a"]), sin(s["a"])) * logo_size * s["d"]
			var r: float = logo_size * 0.05 * s["s"] * sin(k * PI)
			Logo.draw_sparkle(self, p, r, Logo.PALETTE[_sparks.find(s) % Logo.PALETTE.size()])
	# fade de saída
	var fade_out := clampf((t - (DURATION - 0.45)) / 0.45, 0.0, 1.0)
	if fade_out > 0.0:
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, fade_out))
