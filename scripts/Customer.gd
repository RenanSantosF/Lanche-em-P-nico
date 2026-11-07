extends Control
# Cliente: bonequinho com balão do pedido e barra de paciência.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

signal tapped(customer)
signal ran_out(customer)

const SKINS := [Color("ffd9b8"), Color("f1c08f"), Color("d79a6a"), Color("a86b45"), Color("7a4a2e")]
const SHIRTS := [Color("ff6b6b"), Color("4dabf7"), Color("51cf66"), Color("fcc419"), Color("cc5de8"), Color("ff922b"), Color("20c997")]
const HAIRS := [Color("2b1a10"), Color("6b3e1f"), Color("e8b84a"), Color("d9480f"), Color("343a40"), Color("f783ac")]

var recipe: Dictionary = {}
var sides: Array = []
var patience: float = 30.0
var max_patience: float = 30.0
var value: int = 0
var waiting: bool = false
var paused: bool = false
var selected: bool = false:
	set(v):
		selected = v
		queue_redraw()
var mood: String = "wait"
var bubble_h: float = 150.0

var skin: Color
var shirt: Color
var hair: Color
var hair_style: int
var kid: bool
var glasses: bool
var _t: float = 0.0
var _blink: float = 2.0
var _warned: bool = false


func setup(rec: Dictionary, sd: Array, pat: float, val: int) -> void:
	recipe = rec
	sides = sd
	max_patience = pat
	patience = pat
	value = val
	skin = SKINS.pick_random()
	shirt = SHIRTS.pick_random()
	hair = HAIRS.pick_random()
	hair_style = randi() % 5
	kid = randf() < 0.3
	glasses = randf() < 0.25
	_t = randf() * 10.0
	mouse_filter = MOUSE_FILTER_STOP


func ratio() -> float:
	return clampf(patience / max_patience, 0.0, 1.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(self)
		accept_event()


func _process(delta: float) -> void:
	_t += delta
	_blink -= delta
	if _blink < -0.12:
		_blink = randf_range(1.5, 4.0)
	if waiting and not paused:
		patience -= delta
		if patience <= 0.0:
			patience = 0.0
			waiting = false
			mood = "sad"
			ran_out.emit(self)
		elif ratio() < 0.3 and not _warned:
			_warned = true
			Sfx.play("angry", 1.2)
	queue_redraw()


func _draw() -> void:
	var cw := size.x
	var r := ratio()
	# ---- personagem ----
	var bob := sin(_t * 3.0) * 3.0
	var shake := 0.0
	if mood == "wait" and r < 0.3:
		shake = sin(_t * 40.0) * 3.0
	if mood == "happy":
		bob = -abs(sin(_t * 9.0)) * 14.0
	var sc := 0.82 if kid else 1.0
	var head_r := 44.0 * sc
	var head := Vector2(cw / 2 + shake, bubble_h + 34 + head_r + bob + (1.0 - sc) * 70.0)
	# corpo
	var bw := 118.0 * sc
	var body := Rect2(cw / 2 - bw / 2 + shake * 0.5, head.y + head_r * 0.6, bw, size.y - head.y)
	D.fill_rrect(self, body, 40 * sc, shirt.darkened(0.2))
	D.fill_rrect(self, Rect2(body.position + Vector2(6, 0), body.size - Vector2(12, 8)), 36 * sc, shirt)
	D.fill_rrect(self, Rect2(cw / 2 - 16 * sc, body.position.y - 2, 32 * sc, 26 * sc), 10, skin.darkened(0.1))
	# braços pra cima quando feliz
	if mood == "happy":
		for sgn in [-1, 1]:
			var a := body.position + Vector2(bw / 2 + sgn * bw * 0.45, 30)
			draw_line(a, a + Vector2(sgn * 34, -60 + bob), shirt.darkened(0.1), 20 * sc)
			draw_circle(a + Vector2(sgn * 34, -60 + bob), 13 * sc, skin)
	# cabeça
	var hc := skin
	if mood == "wait" and r < 0.3:
		hc = skin.lerp(Color("ff5a4f"), 0.35 + 0.15 * sin(_t * 8.0))
	if hair_style == 2:
		D.fill_rrect(self, Rect2(head.x - head_r * 1.05, head.y - head_r * 0.6, head_r * 2.1, head_r * 1.9), head_r * 0.6, hair)
	draw_circle(head, head_r, hc.darkened(0.15))
	draw_circle(head - Vector2(0, 2), head_r - 2, hc)
	draw_circle(head + Vector2(-head_r * 0.95, 4), head_r * 0.2, hc.darkened(0.1))
	draw_circle(head + Vector2(head_r * 0.95, 4), head_r * 0.2, hc.darkened(0.1))
	_draw_hair(head, head_r)
	# olhos
	var eye_y := head.y - head_r * 0.05
	for sgn in [-1, 1]:
		var e := Vector2(head.x + sgn * head_r * 0.38, eye_y)
		if mood == "happy":
			draw_arc(e + Vector2(0, 4), head_r * 0.16, PI * 1.1, PI * 1.9, 10, Color("2b1a10"), 4.0, true)
		elif _blink < 0.0:
			draw_line(e - Vector2(head_r * 0.14, 0), e + Vector2(head_r * 0.14, 0), Color("2b1a10"), 4.0)
		else:
			draw_circle(e, head_r * 0.17, Color.WHITE)
			draw_circle(e + Vector2(0, 1), head_r * 0.1, Color("2b1a10"))
			draw_circle(e + Vector2(-2, -2), head_r * 0.035, Color.WHITE)
		if mood == "wait" and r < 0.3:
			var bx := e + Vector2(0, -head_r * 0.28)
			draw_line(bx + Vector2(-sgn * head_r * 0.2, -6), bx + Vector2(sgn * head_r * 0.15, 2), Color("2b1a10"), 4.0)
	if glasses:
		for sgn in [-1, 1]:
			draw_arc(Vector2(head.x + sgn * head_r * 0.38, eye_y), head_r * 0.27, 0, TAU, 20, Color("343a40"), 3.0, true)
		draw_line(Vector2(head.x - head_r * 0.12, eye_y), Vector2(head.x + head_r * 0.12, eye_y), Color("343a40"), 3.0)
	# bochechas
	draw_circle(head + Vector2(-head_r * 0.6, head_r * 0.3), head_r * 0.14, Color(1, 0.45, 0.45, 0.35))
	draw_circle(head + Vector2(head_r * 0.6, head_r * 0.3), head_r * 0.14, Color(1, 0.45, 0.45, 0.35))
	# boca
	var m := head + Vector2(0, head_r * 0.42)
	var mc := Color("7a2e1f")
	if mood == "happy" or (mood == "wait" and r > 0.6):
		var pts := PackedVector2Array()
		var open := 0.55 if mood == "happy" else 0.3
		for i in 13:
			var a := PI * i / 12.0
			pts.append(m + Vector2(cos(a) * head_r * 0.3, sin(a) * head_r * open))
		draw_colored_polygon(pts, mc)
	elif mood == "sad" or r < 0.3:
		draw_arc(m + Vector2(0, head_r * 0.2), head_r * 0.22, PI * 1.15, PI * 1.85, 10, mc, 5.0, true)
	else:
		draw_line(m - Vector2(head_r * 0.2, 0), m + Vector2(head_r * 0.2, 0), mc, 5.0)
	if mood == "sad":
		draw_circle(head + Vector2(-head_r * 0.42, head_r * 0.25 + fmod(_t * 30.0, 20.0)), 5, Color("74c0fc"))

	# ---- balão do pedido ----
	if mood == "wait":
		_draw_bubble(cw, r)


func _draw_hair(head: Vector2, hr: float) -> void:
	match hair_style:
		0:
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				pts.append(head + Vector2(cos(a) * hr * 1.02, sin(a) * hr * 1.02 - 2))
			pts.append(head + Vector2(hr * 0.6, -hr * 0.35))
			pts.append(head + Vector2(-hr * 0.3, -hr * 0.5))
			draw_colored_polygon(pts, hair)
		1:
			var pts := PackedVector2Array()
			for i in 9:
				var a := PI + PI * i / 8.0
				var rr := hr * (1.3 if i % 2 == 1 else 0.95)
				pts.append(head + Vector2(cos(a) * rr, sin(a) * rr - 4))
			pts.append(head + Vector2(-hr * 0.0, -hr * 0.45))
			draw_colored_polygon(pts, hair)
		2:
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				pts.append(head + Vector2(cos(a) * hr * 1.05, sin(a) * hr * 1.05 - 2))
			pts.append(head + Vector2(hr * 0.2, -hr * 0.4))
			draw_colored_polygon(pts, hair)
		3:
			draw_circle(head + Vector2(0, -hr * 1.05), hr * 0.42, hair)
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				pts.append(head + Vector2(cos(a) * hr * 1.02, sin(a) * hr * 1.0 - 2))
			pts.append(head + Vector2(0, -hr * 0.5))
			draw_colored_polygon(pts, hair)
		4:
			var cap := shirt.lerp(Color.WHITE, 0.15)
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				pts.append(head + Vector2(cos(a) * hr * 1.04, sin(a) * hr * 1.0 - 6))
			draw_colored_polygon(pts, cap)
			D.fill_rrect(self, Rect2(head.x - hr * 0.2, head.y - hr * 0.42, hr * 1.5, hr * 0.28), hr * 0.12, cap.darkened(0.2))
			draw_circle(head + Vector2(0, -hr * 1.02), hr * 0.12, cap.darkened(0.3))


func _draw_bubble(cw: float, r: float) -> void:
	var br := Rect2(6, 4, cw - 12, bubble_h - 12)
	if selected:
		var pulse := 0.5 + 0.5 * sin(_t * 6.0)
		D.fill_rrect(self, br.grow(6 + pulse * 3), 26, Color(1.0, 0.55, 0.1, 0.9))
	D.fill_rrect(self, Rect2(br.position + Vector2(0, 5), br.size), 20, Color(0, 0, 0, 0.18))
	D.fill_rrect(self, br, 20, Color.WHITE)
	var tail := PackedVector2Array([Vector2(cw / 2 - 14, br.end.y - 1), Vector2(cw / 2 + 14, br.end.y - 1), Vector2(cw / 2, br.end.y + 18)])
	draw_colored_polygon(tail, Color.WHITE)
	D.text(self, Game.font, Vector2(br.position.x, br.position.y + 26), recipe.get("name", ""), 20,
		Color("5c2c0c"), HORIZONTAL_ALIGNMENT_CENTER, br.size.x)
	var has_sides := sides.size() > 0
	var stack_w := minf(br.size.x * (0.52 if has_sides else 0.62), 84.0)
	var stack_area := br.size.y - 56
	var sh := D.stack_height(recipe.get("layers", []), stack_w)
	if sh > stack_area:
		stack_w *= stack_area / sh
	var scx := br.position.x + br.size.x * (0.38 if has_sides else 0.5)
	D.draw_stack(self, recipe.get("layers", []), scx, br.end.y - 24, stack_w)
	var sy := br.position.y + 56
	for s in sides:
		D.draw_side(self, s, Vector2(br.end.x - 28, sy), 40)
		sy += 44
	# paciência
	var bar := Rect2(br.position.x + 14, br.end.y - 16, br.size.x - 28, 10)
	D.fill_rrect(self, bar, 5, Color("e9ecef"))
	var col := Color("51cf66")
	if r < 0.3:
		col = Color("ff6b6b")
	elif r < 0.6:
		col = Color("fcc419")
	D.fill_rrect(self, Rect2(bar.position, Vector2(bar.size.x * r, bar.size.y)), 5, col)
