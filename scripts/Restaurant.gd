extends Control
# Cenário da lanchonete. Muda conforme o jogador expande (plantas, neon, luzinhas, bancos).
# mode = "wall" desenha o fundo; mode = "counter" desenha o balcão da frente.

const D = preload("res://scripts/Draw.gd")

var mode: String = "wall"
var owned: Dictionary = {}
var seats: int = 2
var menu_lines: Array = []
var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	if mode == "wall" and (owned.has("neon") or owned.has("lights")):
		queue_redraw()


func _draw() -> void:
	if mode == "counter":
		_draw_counter()
	else:
		_draw_wall()


func _draw_wall() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color("ffe3b8"))
	var x := 0.0
	while x < w:
		draw_rect(Rect2(x, 0, 24, h), Color("ffd9a3"))
		x += 48.0
	# rodapé de azulejos
	var tile_y := h * 0.62
	draw_rect(Rect2(0, tile_y, w, h - tile_y), Color("7ec8e3"))
	var tx := 0.0
	var row := 0
	var ty := tile_y
	while ty < h:
		tx = -20.0 if row % 2 == 1 else 0.0
		while tx < w:
			draw_rect(Rect2(tx + 2, ty + 2, 36, 36), Color("9fd8ec"))
			tx += 40.0
		ty += 40.0
		row += 1
	draw_rect(Rect2(0, tile_y - 8, w, 10), Color("4ea8c9"))
	# janelas
	for wx in [w * 0.18, w * 0.82]:
		var wr := Rect2(wx - 70, 96, 140, 120)
		D.fill_rrect(self, wr.grow(8), 18, Color("b5651d"))
		D.fill_rrect(self, wr, 12, Color("a5e3ff"))
		draw_circle(wr.position + Vector2(40, 40), 16, Color("fff3b0"))
		draw_circle(wr.position + Vector2(95, 70), 14, Color.WHITE)
		draw_circle(wr.position + Vector2(112, 66), 18, Color.WHITE)
		draw_circle(wr.position + Vector2(128, 72), 12, Color.WHITE)
		draw_line(Vector2(wx, wr.position.y), Vector2(wx, wr.end.y), Color("b5651d"), 6)
		draw_line(Vector2(wr.position.x, wr.position.y + 60), Vector2(wr.end.x, wr.position.y + 60), Color("b5651d"), 6)
	# quadro do cardápio
	if menu_lines.size() > 0:
		var avail_h := tile_y - (134.0 if owned.has("lights") else 90.0)
		var rows := mini(menu_lines.size(), int((avail_h - 56) / 30.0))
		if rows > 0:
			var board := Rect2(w / 2 - 125, 120 if owned.has("lights") else 76, 250, 56 + rows * 30)
			D.fill_rrect(self, board.grow(8), 14, Color("8d5524"))
			D.fill_rrect(self, board, 10, Color("2f3e36"))
			D.text(self, Game.font, Vector2(board.position.x, board.position.y + 38), "CARDÁPIO", 28, Color("fff3bf"), HORIZONTAL_ALIGNMENT_CENTER, board.size.x)
			var first := menu_lines.size() - rows
			for k in rows:
				var line: Array = menu_lines[first + k]
				var ly := board.position.y + 74 + k * 30
				D.text(self, Game.font, Vector2(board.position.x + 16, ly), line[0], 20, Color("e9ecef"))
				D.text(self, Game.font, Vector2(board.position.x, ly), "$%d" % line[1], 20, Color("ffd43b"), HORIZONTAL_ALIGNMENT_RIGHT, board.size.x - 16)
	# toldo listrado
	var stripe := 60.0
	var cols := [Color("ef476f"), Color.WHITE]
	if owned.has("neon"):
		cols = [Color("7b2cbf"), Color("ffd166")]
	var i := 0
	var sx := 0.0
	while sx < w:
		var c: Color = cols[i % 2]
		draw_rect(Rect2(sx, 0, stripe, 50), c)
		draw_circle(Vector2(sx + stripe / 2, 50), stripe / 2, c)
		sx += stripe
		i += 1
	draw_rect(Rect2(0, 0, w, 8), Color(0, 0, 0, 0.12))
	# letreiro neon
	if owned.has("neon"):
		var glow := 0.75 + 0.25 * sin(_t * 3.0)
		if fmod(_t, 5.0) > 4.8:
			glow = 0.3
		var sign := Rect2(w / 2 - 210, 6, 420, 52)
		D.fill_rrect(self, sign, 16, Color("1b1035"))
		D.text(self, Game.font, Vector2(sign.position.x, sign.position.y + 38), "LANCHE EM PÂNICO", 32,
			Color(1.0, 0.45, 0.8, glow), HORIZONTAL_ALIGNMENT_CENTER, sign.size.x, 10, Color(1.0, 0.2, 0.7, 0.35 * glow))
	# luzinhas
	if owned.has("lights"):
		var bulbs := [Color("ff6b6b"), Color("ffd43b"), Color("69db7c"), Color("4dabf7"), Color("da77f2")]
		var pts := PackedVector2Array()
		var n := 16
		for k in n + 1:
			var px := w * k / n
			pts.append(Vector2(px, 92 + sin(PI * fmod(float(k), 4.0) / 4.0) * 18))
		draw_polyline(pts, Color("495057"), 2.0, true)
		for k in n + 1:
			var on := int(_t * 3.0 + k) % 3 != 0
			var bc: Color = bulbs[k % bulbs.size()]
			if not on:
				bc = bc.darkened(0.5)
			draw_circle(pts[k] + Vector2(0, 8), 7, bc)
			if on:
				draw_circle(pts[k] + Vector2(0, 8), 13, Color(bc, 0.25))
	# plantinhas
	if owned.has("plants"):
		for px in [34.0, w - 34.0]:
			var base := Vector2(px, h - 70)
			for k in 5:
				var a := -PI / 2.0 + (k - 2) * 0.4
				var tip := base + Vector2(cos(a), sin(a)) * 90.0
				draw_line(base, tip, Color("2f9e44"), 16.0, true)
				draw_circle(tip, 12, Color("40c057"))
			D.fill_rrect(self, Rect2(base.x - 26, base.y - 6, 52, 50), 10, Color("e8590c"))


func _draw_counter() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, 10), Color(0, 0, 0, 0.18))
	D.fill_rrect(self, Rect2(-10, 4, w + 20, 26), 8, Color("f8c98a"))
	draw_rect(Rect2(0, 22, w, 8), Color("d99a52"))
	var front := Color("e63946")
	if owned.has("neon"):
		front = Color("5a189a")
	draw_rect(Rect2(0, 30, w, h - 30), front)
	var x := 0.0
	while x < w:
		draw_rect(Rect2(x + 10, 30, 22, h - 30), front.lightened(0.12))
		x += 64.0
	draw_rect(Rect2(0, 30, w, 6), front.darkened(0.25))
