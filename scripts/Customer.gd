extends Control
# Cliente: bonequinho + balão com o pedido + barra de paciência.
# Otimizado: cada parte só é redesenhada quando muda; o "balanço" é feito movendo o nó.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")
const Baked = preload("res://scripts/Baked.gd")

signal tapped(customer)
signal ran_out(customer)

const SKINS := [Color("ffd9b8"), Color("f1c08f"), Color("d79a6a"), Color("a86b45"), Color("7a4a2e")]
const SHIRTS := [Color("ff6b6b"), Color("4dabf7"), Color("51cf66"), Color("fcc419"), Color("cc5de8"), Color("ff922b"), Color("20c997")]
const HAIRS := [Color("2b1a10"), Color("6b3e1f"), Color("e8b84a"), Color("d9480f"), Color("343a40"), Color("f783ac")]


class Part extends Control:
	var host
	var fn: String
	func _draw() -> void:
		host.call(fn, self)


var recipe: Dictionary = {}
var sides: Array = []
var kind: String = "normal"
var patience: float = 30.0
var max_patience: float = 30.0
var value: int = 0
var waiting: bool = false
var paused: bool = false
var selected: bool = false:
	set(v):
		if v == selected:
			return
		selected = v
		_update_glow()
var mood: String = "wait":
	set(v):
		mood = v
		if body:
			body.refresh()
			bubble.visible = v == "wait"
			bar.visible = v == "wait"
			glow.visible = v == "wait" and selected
var bubble_h: float = 150.0

var skin: Color
var shirt: Color
var hair: Color
var hair_style: int
var kid: bool
var glasses: bool

var body
var bubble
var bar: Part
var glow: Part
var _glow_tw: Tween
var _t: float = 0.0
var _blink: float = 2.0
var _blinking: bool = false
var _angry: bool = false
var _bar_drawn: float = -1.0


func setup(rec: Dictionary, sd: Array, pat: float, val: int, k: String) -> void:
	recipe = rec
	sides = sd
	max_patience = pat
	patience = pat
	value = val
	kind = k
	skin = SKINS.pick_random()
	shirt = SHIRTS.pick_random()
	hair = HAIRS.pick_random()
	hair_style = randi() % 5
	kid = kind == "kid"
	glasses = kind == "critic" or randf() < 0.2
	if kind == "critic":
		shirt = Color("343a40")
	_t = randf() * 10.0
	mouse_filter = MOUSE_FILTER_STOP
	glow = _part("_draw_glow")
	glow.visible = false
	bubble = _baked("_draw_bubble")
	bar = _part("_draw_bar")
	body = _baked("_draw_body")
	resized.connect(_on_resized)


func _part(fn: String) -> Part:
	var p := Part.new()
	p.host = self
	p.fn = fn
	p.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(p)
	return p


func _baked(fn: String):
	var b := Baked.new()
	b.setup(self, fn, 24.0)
	add_child(b)
	return b


func _on_resized() -> void:
	for p in [glow, bubble, bar, body]:
		p.size = size
	glow.queue_redraw()
	bar.queue_redraw()


func ratio() -> float:
	return clampf(patience / max_patience, 0.0, 1.0)


func _update_glow() -> void:
	if glow == null:
		return
	glow.visible = selected and mood == "wait"
	if _glow_tw:
		_glow_tw.kill()
	if glow.visible:
		_glow_tw = create_tween().set_loops()
		_glow_tw.tween_property(glow, "modulate:a", 0.45, 0.35)
		_glow_tw.tween_property(glow, "modulate:a", 1.0, 0.35)


func _gui_input(event: InputEvent) -> void:
	# toque (celular) ou clique (PC); o mouse emulado do toque está desligado no projeto
	if ((event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch) and event.pressed:
		tapped.emit(self)
		accept_event()


func _process(delta: float) -> void:
	_t += delta
	# piscar
	_blink -= delta
	var blinking := _blink < 0.0
	if _blink < -0.12:
		_blink = randf_range(1.5, 4.0)
		blinking = false
	if blinking != _blinking:
		_blinking = blinking
		body.refresh()
	# balanço / pulo via posição (barato)
	var bob := sin(_t * 3.0) * 3.0
	if mood == "happy":
		bob = -abs(sin(_t * 9.0)) * 14.0
	var shake := sin(_t * 40.0) * 3.0 if (_angry and mood == "wait") else 0.0
	body.position = Vector2(shake, bob)
	if waiting and not paused:
		patience -= delta
		if patience <= 0.0:
			patience = 0.0
			waiting = false
			mood = "sad"
			ran_out.emit(self)
		var angry := ratio() < 0.3
		if angry != _angry:
			_angry = angry
			body.refresh()
			if angry:
				Sfx.play("angry", 1.1)
		if abs(ratio() - _bar_drawn) > 0.01:
			bar.queue_redraw()


# ------------------------------------------------------------------ desenho
func _draw_body(ci: Control) -> void:
	var cw := size.x
	var r := ratio()
	var sc := 0.82 if kid else 1.0
	var head_r := 44.0 * sc
	var head := Vector2(cw / 2, bubble_h + 34 + head_r + (1.0 - sc) * 70.0)
	var bw := 118.0 * sc
	var body_r := Rect2(cw / 2 - bw / 2, head.y + head_r * 0.6, bw, size.y - head.y)
	D.fill_rrect(ci, body_r, 40 * sc, shirt.darkened(0.2))
	D.fill_rrect(ci, Rect2(body_r.position + Vector2(6, 0), body_r.size - Vector2(12, 8)), 36 * sc, shirt)
	D.fill_rrect(ci, Rect2(cw / 2 - 16 * sc, body_r.position.y - 2, 32 * sc, 26 * sc), 10, skin.darkened(0.1))
	if kind == "vip":
		ci.draw_line(body_r.position + Vector2(bw / 2, 10), body_r.position + Vector2(bw / 2, 60), Color("ffd21f"), 8)
	if mood == "happy":
		for sgn in [-1, 1]:
			var a := body_r.position + Vector2(bw / 2 + sgn * bw * 0.45, 30)
			ci.draw_line(a, a + Vector2(sgn * 34, -60), shirt.darkened(0.1), 20 * sc)
			ci.draw_circle(a + Vector2(sgn * 34, -60), 13 * sc, skin)
	var hc := skin
	if mood == "wait" and _angry:
		hc = skin.lerp(Color("ff5a4f"), 0.4)
	if hair_style == 2 and kind != "critic":
		D.fill_rrect(ci, Rect2(head.x - head_r * 1.05, head.y - head_r * 0.6, head_r * 2.1, head_r * 1.9), head_r * 0.6, hair)
	ci.draw_circle(head, head_r, hc.darkened(0.15))
	ci.draw_circle(head - Vector2(0, 2), head_r - 2, hc)
	ci.draw_circle(head + Vector2(-head_r * 0.95, 4), head_r * 0.2, hc.darkened(0.1))
	ci.draw_circle(head + Vector2(head_r * 0.95, 4), head_r * 0.2, hc.darkened(0.1))
	if kind == "critic":
		_draw_beret(ci, head, head_r)
	else:
		_draw_hair(ci, head, head_r)
	if kind == "vip":
		_draw_crown(ci, head, head_r)
	var eye_y := head.y - head_r * 0.05
	var ink := Color("2b1a10")
	for sgn in [-1, 1]:
		var e := Vector2(head.x + sgn * head_r * 0.38, eye_y)
		if mood == "happy":
			ci.draw_arc(e + Vector2(0, 4), head_r * 0.16, PI * 1.1, PI * 1.9, 8, ink, 4.0)
		elif _blinking:
			ci.draw_line(e - Vector2(head_r * 0.14, 0), e + Vector2(head_r * 0.14, 0), ink, 4.0)
		else:
			ci.draw_circle(e, head_r * 0.17, Color.WHITE)
			ci.draw_circle(e + Vector2(0, 1), head_r * 0.1, ink)
			ci.draw_circle(e + Vector2(-2, -2), head_r * 0.035, Color.WHITE)
		if mood == "wait" and _angry:
			var bx := e + Vector2(0, -head_r * 0.28)
			ci.draw_line(bx + Vector2(-sgn * head_r * 0.2, -6), bx + Vector2(sgn * head_r * 0.15, 2), ink, 4.0)
	if glasses:
		for sgn in [-1, 1]:
			ci.draw_arc(Vector2(head.x + sgn * head_r * 0.38, eye_y), head_r * 0.27, 0, TAU, 16, Color("343a40"), 3.0)
		ci.draw_line(Vector2(head.x - head_r * 0.12, eye_y), Vector2(head.x + head_r * 0.12, eye_y), Color("343a40"), 3.0)
	ci.draw_circle(head + Vector2(-head_r * 0.6, head_r * 0.3), head_r * 0.14, Color(1, 0.45, 0.45, 0.35))
	ci.draw_circle(head + Vector2(head_r * 0.6, head_r * 0.3), head_r * 0.14, Color(1, 0.45, 0.45, 0.35))
	var m := head + Vector2(0, head_r * 0.42)
	var mc := Color("7a2e1f")
	if kind == "critic":
		var ms := PackedVector2Array([m + Vector2(-head_r * 0.4, -2), m + Vector2(0, -head_r * 0.16), m + Vector2(head_r * 0.4, -2), m + Vector2(0, -head_r * 0.05)])
		ci.draw_colored_polygon(ms, Color("2b1a10"))
	if mood == "happy" or (mood == "wait" and r > 0.6 and kind != "critic"):
		var pts := PackedVector2Array()
		var open := 0.55 if mood == "happy" else 0.3
		for i in 9:
			var a := PI * i / 8.0
			pts.append(m + Vector2(cos(a) * head_r * 0.3, sin(a) * head_r * open))
		ci.draw_colored_polygon(pts, mc)
	elif mood == "sad" or _angry:
		ci.draw_arc(m + Vector2(0, head_r * 0.2), head_r * 0.22, PI * 1.15, PI * 1.85, 8, mc, 5.0)
	else:
		ci.draw_line(m - Vector2(head_r * 0.2, 0), m + Vector2(head_r * 0.2, 0), mc, 5.0)


func _dome(head: Vector2, hr: float, sx: float, sy: float, dy: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 11:
		var a := PI + PI * i / 10.0
		pts.append(head + Vector2(cos(a) * hr * sx, sin(a) * hr * sy + dy))
	return pts


func _draw_hair(ci: Control, head: Vector2, hr: float) -> void:
	match hair_style:
		0, 2:
			var pts := _dome(head, hr, 1.03, 1.03, -2)
			pts.append(head + Vector2(hr * 0.5, -hr * 0.35))
			pts.append(head + Vector2(-hr * 0.3, -hr * 0.5))
			ci.draw_colored_polygon(pts, hair)
		1:
			var pts := PackedVector2Array()
			for i in 9:
				var a := PI + PI * i / 8.0
				var rr := hr * (1.3 if i % 2 == 1 else 0.95)
				pts.append(head + Vector2(cos(a) * rr, sin(a) * rr - 4))
			pts.append(head + Vector2(0, -hr * 0.45))
			ci.draw_colored_polygon(pts, hair)
		3:
			ci.draw_circle(head + Vector2(0, -hr * 1.05), hr * 0.42, hair)
			var pts := _dome(head, hr, 1.02, 1.0, -2)
			pts.append(head + Vector2(0, -hr * 0.5))
			ci.draw_colored_polygon(pts, hair)
		4:
			var cap := shirt.lerp(Color.WHITE, 0.15)
			ci.draw_colored_polygon(_dome(head, hr, 1.04, 1.0, -6), cap)
			D.fill_rrect(ci, Rect2(head.x - hr * 0.2, head.y - hr * 0.42, hr * 1.5, hr * 0.28), hr * 0.12, cap.darkened(0.2))


func _draw_beret(ci: Control, head: Vector2, hr: float) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16
		pts.append(head + Vector2(cos(a) * hr * 1.1 - hr * 0.1, sin(a) * hr * 0.35 - hr * 0.78))
	ci.draw_colored_polygon(pts, Color("c92a2a"))
	ci.draw_circle(head + Vector2(-hr * 0.1, -hr * 1.15), hr * 0.1, Color("c92a2a"))


func _draw_crown(ci: Control, head: Vector2, hr: float) -> void:
	var y := head.y - hr * 0.85
	var w := hr * 1.1
	var pts := PackedVector2Array([
		Vector2(head.x - w / 2, y), Vector2(head.x - w / 2, y - hr * 0.45), Vector2(head.x - w / 4, y - hr * 0.2),
		Vector2(head.x, y - hr * 0.6), Vector2(head.x + w / 4, y - hr * 0.2), Vector2(head.x + w / 2, y - hr * 0.45),
		Vector2(head.x + w / 2, y)])
	ci.draw_colored_polygon(pts, Color("ffd21f"))
	D.outline(ci, pts, Color("c7860a"), 3.0)
	ci.draw_circle(Vector2(head.x, y - hr * 0.15), hr * 0.08, Color("ff6b6b"))


func _bubble_rect() -> Rect2:
	return Rect2(6, 4, size.x - 12, bubble_h - 12)


func _draw_glow(ci: Control) -> void:
	var col := Color("ffd21f") if kind == "vip" else Color(1.0, 0.55, 0.1)
	D.fill_rrect(ci, _bubble_rect().grow(8), 26, col)


func _draw_bubble(ci: Control) -> void:
	var br := _bubble_rect()
	var cw := size.x
	D.fill_rrect(ci, Rect2(br.position + Vector2(0, 5), br.size), 20, Color(0, 0, 0, 0.18))
	var bg := Color.WHITE
	if kind == "vip":
		bg = Color("fff7d6")
	elif recipe.get("custom", false):
		bg = Color("eef6ff")
	D.fill_rrect(ci, br, 20, bg)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(cw / 2 - 14, br.end.y - 1), Vector2(cw / 2 + 14, br.end.y - 1), Vector2(cw / 2, br.end.y + 18)]), bg)
	D.text(ci, Game.font, Vector2(br.position.x, br.position.y + 26), L.t(recipe.get("name", "")), D.fit(Game.font, L.t(recipe.get("name", "")), 19, br.size.x - 12),
		Color("5c2c0c"), HORIZONTAL_ALIGNMENT_CENTER, br.size.x)
	var has_sides := sides.size() > 0
	var layers: Array = recipe.get("layers", [])
	var stack_w := minf(br.size.x * (0.52 if has_sides else 0.62), 84.0)
	var sh := D.stack_height(layers, stack_w)
	var area := br.size.y - 56
	if sh > area:
		stack_w *= area / sh
	D.draw_stack(ci, layers, br.position.x + br.size.x * (0.38 if has_sides else 0.5), br.end.y - 24, stack_w)
	var sy := br.position.y + 56
	for s in sides:
		D.draw_side(ci, s, Vector2(br.end.x - 26, sy), 38)
		sy += 42
	var tag := ""
	var tag_col := Color()
	if kind == "vip":
		tag = L.t("VIP x2")
		tag_col = Color("e8a90c")
	elif kind == "critic":
		tag = L.t("CRÍTICO")
		tag_col = Color("c92a2a")
	if tag != "":
		var tr := Rect2(br.position.x - 4, br.position.y - 14, 92, 26)
		D.fill_rrect(ci, tr, 13, tag_col)
		D.text(ci, Game.font, Vector2(tr.position.x, tr.position.y + 20), tag, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, tr.size.x)


func _draw_bar(ci: Control) -> void:
	var br := _bubble_rect()
	var r := ratio()
	_bar_drawn = r
	var b := Rect2(br.position.x + 14, br.end.y - 16, br.size.x - 28, 10)
	D.fill_rrect(ci, b, 5, Color("e9ecef"))
	var col := Color("51cf66")
	if r < 0.3:
		col = Color("ff6b6b")
	elif r < 0.6:
		col = Color("fcc419")
	if b.size.x * r > 2:
		D.fill_rrect(ci, Rect2(b.position, Vector2(b.size.x * r, b.size.y)), 5, col)
