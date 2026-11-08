extends Control
# Cenário da lanchonete. Evolui conforme o jogador compra coisas:
# 4 temas de parede, plantas, luzinhas, quadros, letreiro neon e cardápio.
# mode = "wall" (fundo) ou "counter" (balcão da frente).
# O fundo é desenhado UMA vez; só as luzes/neon (num filho) piscam, a 5 quadros/s.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

const THEMES := [
	{"wall": Color("ffe3b8"), "stripe": Color("ffd9a3"), "tile": Color("7ec8e3"), "tile2": Color("9fd8ec"), "trim": Color("4ea8c9"),
		"awning": [Color("ef476f"), Color.WHITE], "counter": Color("e63946"), "wood": Color("b5651d")},
	{"wall": Color("dff5e3"), "stripe": Color("cdeed4"), "tile": Color("55b7a8"), "tile2": Color("76c9bc"), "trim": Color("2f8f82"),
		"awning": [Color("2f9e44"), Color("fff9db")], "counter": Color("2b8a3e"), "wood": Color("8d5524")},
	{"wall": Color("ebe3ff"), "stripe": Color("ddd2ff"), "tile": Color("8c6ff0"), "tile2": Color("a48cf5"), "trim": Color("6741d9"),
		"awning": [Color("7b2cbf"), Color("ffd166")], "counter": Color("5a189a"), "wood": Color("6b3e1f")},
	{"wall": Color("3d3033"), "stripe": Color("46383b"), "tile": Color("a07850"), "tile2": Color("b48a5e"), "trim": Color("d4a017"),
		"awning": [Color("1a1a1a"), Color("d4a017")], "counter": Color("1f1f1f"), "wood": Color("d4a017")},
]


class Painter extends Control:
	var host
	func _draw() -> void:
		host._draw_wall(self)


class Anim extends Control:
	var host
	var t := 0.0
	var acc := 0.0
	func _process(delta: float) -> void:
		t += delta
		acc += delta
		if acc > 0.2:
			acc = 0.0
			queue_redraw()
	func _draw() -> void:
		host.draw_anim(self, t)


var mode: String = "wall"
var owned: Dictionary = {}
var menu_lines: Array = []
var theme_idx: int = 0
var _anim: Anim
var _vp: SubViewport
var _painter: Painter


func _ready() -> void:
	resized.connect(_rebake)


# O fundo é desenhado uma vez numa textura (1 draw call por quadro em vez de centenas).
func _rebake() -> void:
	if mode != "wall" or size.x < 2 or size.y < 2:
		queue_redraw()
		return
	if _vp == null:
		_vp = SubViewport.new()
		_vp.disable_3d = true
		_vp.transparent_bg = false
		_painter = Painter.new()
		_painter.host = self
		_vp.add_child(_painter)
		add_child(_vp)
		move_child(_vp, 0)
	_vp.size = Vector2i(ceili(size.x), ceili(size.y))
	_painter.size = size
	_painter.queue_redraw()
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	queue_redraw()


func refresh() -> void:
	theme_idx = clampi(R.total_tiers(owned) / 4, 0, THEMES.size() - 1)
	var need_anim := mode == "wall" and (R.tier(owned, "decor") >= 2 or R.tier(owned, "neon") > 0)
	if need_anim and _anim == null:
		_anim = Anim.new()
		_anim.host = self
		_anim.mouse_filter = MOUSE_FILTER_IGNORE
		_anim.set_anchors_preset(PRESET_FULL_RECT)
		add_child(_anim)
	elif not need_anim and _anim != null:
		_anim.queue_free()
		_anim = null
	_rebake()
	if _anim:
		_anim.queue_redraw()


func _draw() -> void:
	if mode == "counter":
		_draw_counter()
	elif _vp != null:
		draw_texture(_vp.get_texture(), Vector2.ZERO)


func _th() -> Dictionary:
	return THEMES[theme_idx]


func _draw_wall(ci: Control) -> void:
	var th := _th()
	var w := size.x
	var h := size.y
	ci.draw_rect(Rect2(0, 0, w, h), th["wall"])
	# listras e azulejos em lote (1 chamada cada) — barato para GPUs fracas
	var tile_y := h * 0.62
	var stripes := PackedVector2Array()
	var x := 12.0
	while x < w + 24:
		stripes.append(Vector2(x, 0))
		stripes.append(Vector2(x, tile_y))
		x += 48.0
	ci.draw_multiline(stripes, th["stripe"], 24.0)
	ci.draw_rect(Rect2(0, tile_y, w, h - tile_y), th["tile2"])
	var grid := PackedVector2Array()
	var ty := tile_y
	var row := 0
	while ty < h:
		grid.append(Vector2(0, ty))
		grid.append(Vector2(w, ty))
		var tx := -20.0 if row % 2 == 1 else 0.0
		while tx < w:
			grid.append(Vector2(tx, ty))
			grid.append(Vector2(tx, minf(ty + 40.0, h)))
			tx += 40.0
		ty += 40.0
		row += 1
	ci.draw_multiline(grid, th["tile"], 4.0)
	ci.draw_rect(Rect2(0, tile_y - 8, w, 10), th["trim"])
	# janelas
	for wx in [w * 0.15, w * 0.85]:
		var wr := Rect2(wx - 60, 96, 120, 110)
		D.fill_rrect(ci, wr.grow(8), 18, th["wood"])
		D.fill_rrect(ci, wr, 12, Color("a5e3ff") if theme_idx < 3 else Color("1b2a4a"))
		if theme_idx < 3:
			ci.draw_circle(wr.position + Vector2(36, 36), 15, Color("fff3b0"))
			ci.draw_circle(wr.position + Vector2(84, 66), 13, Color.WHITE)
			ci.draw_circle(wr.position + Vector2(100, 62), 16, Color.WHITE)
		else:
			ci.draw_circle(wr.position + Vector2(36, 36), 13, Color("fff3b0"))
			for k in 5:
				ci.draw_circle(wr.position + Vector2(20 + k * 21, 70 + (k % 2) * 15), 2, Color.WHITE)
		ci.draw_line(Vector2(wx, wr.position.y), Vector2(wx, wr.end.y), th["wood"], 6)
		ci.draw_line(Vector2(wr.position.x, wr.position.y + 55), Vector2(wr.end.x, wr.position.y + 55), th["wood"], 6)
	# quadros (decoração nível 3)
	if R.tier(owned, "decor") >= 3:
		for fx in [w * 0.15, w * 0.85]:
			var fr := Rect2(fx - 40, tile_y - 110, 80, 70)
			D.fill_rrect(ci, fr.grow(6), 6, Color("d4a017"))
			ci.draw_rect(fr, Color("fff8e7"))
			D.draw_layer(ci, R.BUN_BOTTOM, fx, fr.end.y - 12, 50)
			D.draw_layer(ci, R.PATTY, fx, fr.end.y - 21, 50)
			D.draw_layer(ci, R.BUN_TOP, fx, fr.end.y - 28, 50)
	# cardápio
	if menu_lines.size() > 0:
		var board_y := 120.0 if R.tier(owned, "decor") >= 2 else 76.0
		var rows := mini(menu_lines.size(), int((tile_y - board_y - 70) / 28.0))
		if rows > 0:
			var board := Rect2(w / 2 - 120, board_y, 240, 52 + rows * 28)
			D.fill_rrect(ci, board.grow(8), 14, th["wood"])
			D.fill_rrect(ci, board, 10, Color("2f3e36"))
			D.text(ci, Game.font, Vector2(board.position.x, board.position.y + 36), "CARDÁPIO", 26, Color("fff3bf"), HORIZONTAL_ALIGNMENT_CENTER, board.size.x)
			var first := menu_lines.size() - rows
			for k in rows:
				var line: Array = menu_lines[first + k]
				var ly := board.position.y + 70 + k * 28
				D.text(ci, Game.font, Vector2(board.position.x + 14, ly), line[0], 19, Color("e9ecef"))
				D.text(ci, Game.font, Vector2(board.position.x, ly), "$%d" % line[1], 19, Color("ffd43b"), HORIZONTAL_ALIGNMENT_RIGHT, board.size.x - 14)
	# toldo listrado
	var stripe := 60.0
	var cols: Array = th["awning"]
	var i := 0
	var sx := 0.0
	while sx < w:
		var c: Color = cols[i % 2]
		ci.draw_rect(Rect2(sx, 0, stripe, 50), c)
		ci.draw_circle(Vector2(sx + stripe / 2, 50), stripe / 2, c)
		sx += stripe
		i += 1
	ci.draw_rect(Rect2(0, 0, w, 8), Color(0, 0, 0, 0.12))
	# plantas (decoração nível 1)
	if R.tier(owned, "decor") >= 1:
		for px in [34.0, w - 34.0]:
			var base := Vector2(px, h - 70)
			for k in 5:
				var a := -PI / 2.0 + (k - 2) * 0.4
				var tip := base + Vector2(cos(a), sin(a)) * 90.0
				ci.draw_line(base, tip, Color("2f9e44"), 16.0)
				ci.draw_circle(tip, 12, Color("40c057"))
			D.fill_rrect(ci, Rect2(base.x - 26, base.y - 6, 52, 50), 10, Color("e8590c"))


func draw_anim(ci: Control, t: float) -> void:
	var w := size.x
	if R.tier(owned, "neon") > 0:
		var glow := 0.75 + 0.25 * sin(t * 3.0)
		if fmod(t, 5.0) > 4.7:
			glow = 0.3
		var sign_r := Rect2(w / 2 - 200, 6, 400, 50)
		D.fill_rrect(ci, sign_r, 16, Color("1b1035"))
		D.text(ci, Game.font, Vector2(sign_r.position.x, sign_r.position.y + 37), "LANCHE EM PÂNICO", 30,
			Color(1.0, 0.45, 0.8, glow), HORIZONTAL_ALIGNMENT_CENTER, sign_r.size.x, 10, Color(1.0, 0.2, 0.7, 0.35 * glow))
	if R.tier(owned, "decor") >= 2:
		var bulbs := [Color("ff6b6b"), Color("ffd43b"), Color("69db7c"), Color("4dabf7"), Color("da77f2")]
		var pts := PackedVector2Array()
		var n := 16
		for k in n + 1:
			pts.append(Vector2(w * k / n, 92 + sin(PI * fmod(float(k), 4.0) / 4.0) * 18))
		ci.draw_polyline(pts, Color("495057"), 2.0)
		for k in n + 1:
			var on := int(t * 3.0 + k) % 3 != 0
			var bc: Color = bulbs[k % bulbs.size()]
			if not on:
				bc = bc.darkened(0.5)
			ci.draw_circle(pts[k] + Vector2(0, 8), 7, bc)
			if on:
				ci.draw_circle(pts[k] + Vector2(0, 8), 12, Color(bc, 0.25))


func _draw_counter() -> void:
	var th := _th()
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, 10), Color(0, 0, 0, 0.18))
	D.fill_rrect(self, Rect2(-10, 4, w + 20, 26), 8, Color("f8c98a") if theme_idx < 3 else Color("e9d5a1"))
	draw_rect(Rect2(0, 22, w, 8), Color("d99a52") if theme_idx < 3 else Color("b8935a"))
	var front: Color = th["counter"]
	draw_rect(Rect2(0, 30, w, h - 30), front)
	var x := 0.0
	while x < w:
		draw_rect(Rect2(x + 10, 30, 22, h - 30), front.lightened(0.12))
		x += 64.0
	draw_rect(Rect2(0, 30, w, 6), front.darkened(0.25))
