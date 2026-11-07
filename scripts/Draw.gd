extends RefCounted
# Desenho vetorial de todos os ingredientes, acompanhamentos e ícones.

const R = preload("res://scripts/Rules.gd")

const C_BUN := Color("f5a93f")
const C_BUN_D := Color("d27a25")
const C_BUN_L := Color("ffd08a")
const C_PATTY := Color("7b4226")
const C_PATTY_D := Color("552b16")
const C_CHEESE := Color("ffd23f")
const C_CHEESE_D := Color("f0a91c")
const C_LETTUCE := Color("6cc644")
const C_LETTUCE_D := Color("3f9a2a")
const C_TOMATO := Color("ef3e36")
const C_TOMATO_L := Color("ff7b6b")
const C_BACON := Color("b8413a")
const C_BACON_L := Color("f2a48e")
const C_EGG := Color("fffaf0")
const C_YOLK := Color("ffb01f")
const C_ONION := Color("b973cf")
const C_PICKLE := Color("7fb432")
const C_PICKLE_L := Color("c4e27a")
const OUTLINE := Color(0.25, 0.13, 0.07, 0.9)


static func ellipse(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func rrect(rect: Rect2, r: float, seg: int = 5) -> PackedVector2Array:
	r = minf(r, minf(rect.size.x, rect.size.y) * 0.5 - 0.01)
	var pts := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(rect.size.x - r, r), -PI / 2.0],
		[rect.position + Vector2(rect.size.x - r, rect.size.y - r), 0.0],
		[rect.position + Vector2(r, rect.size.y - r), PI / 2.0],
		[rect.position + Vector2(r, r), PI],
	]
	for c in corners:
		for i in seg + 1:
			var a: float = c[1] + (PI / 2.0) * i / seg
			pts.append(c[0] + Vector2(cos(a), sin(a)) * r)
	return pts


static func fill_rrect(ci: CanvasItem, rect: Rect2, r: float, color: Color) -> void:
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return
	ci.draw_colored_polygon(rrect(rect, r), color)


static func outline(ci: CanvasItem, pts: PackedVector2Array, color: Color, width: float) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, color, width, true)


static func layer_h(t: int, w: float) -> float:
	match t:
		R.BUN_BOTTOM: return w * 0.22
		R.PATTY: return w * 0.17
		R.CHEESE: return w * 0.06
		R.LETTUCE: return w * 0.075
		R.TOMATO: return w * 0.08
		R.BACON: return w * 0.07
		R.EGG: return w * 0.09
		R.ONION: return w * 0.06
		R.PICKLE: return w * 0.06
		R.BUN_TOP: return w * 0.38
	return w * 0.1


static func layer_step(t: int, w: float) -> float:
	return layer_h(t, w) * 0.86


static func stack_height(layers: Array, w: float) -> float:
	var h := 0.0
	for l in layers:
		h += layer_step(l, w)
	if layers.size() > 0:
		h += layer_h(layers[-1], w) - layer_step(layers[-1], w)
	return h


# Desenha uma camada com a base em (cx, yb).
static func draw_layer(ci: CanvasItem, t: int, cx: float, yb: float, w: float) -> void:
	var h := layer_h(t, w)
	var lw := maxf(1.5, w / 70.0)
	match t:
		R.BUN_BOTTOM:
			var rect := Rect2(cx - w / 2, yb - h, w, h)
			var pts := rrect(rect, h * 0.45)
			ci.draw_colored_polygon(pts, C_BUN_D)
			fill_rrect(ci, Rect2(rect.position + Vector2(lw, lw), Vector2(w - lw * 2, h * 0.55)), h * 0.3, C_BUN)
			outline(ci, pts, OUTLINE, lw)
		R.PATTY:
			var ww := w * 1.04
			var rect := Rect2(cx - ww / 2, yb - h, ww, h)
			var pts := rrect(rect, h * 0.5)
			ci.draw_colored_polygon(pts, C_PATTY_D)
			fill_rrect(ci, Rect2(rect.position + Vector2(lw * 2, lw), Vector2(ww - lw * 4, h * 0.6)), h * 0.3, C_PATTY)
			for i in 5:
				var x := cx - ww * 0.32 + ww * 0.16 * i
				ci.draw_line(Vector2(x, yb - h * 0.75), Vector2(x + ww * 0.05, yb - h * 0.35), C_PATTY_D, lw)
			outline(ci, pts, OUTLINE, lw)
		R.CHEESE:
			var ww := w * 1.06
			var x0 := cx - ww / 2
			var x1 := cx + ww / 2
			var pts := PackedVector2Array([Vector2(x0, yb - h), Vector2(x1, yb - h), Vector2(x1, yb)])
			for k in [0.78, 0.45, 0.15]:
				var xk: float = x0 + ww * k
				pts.append(Vector2(xk + ww * 0.06, yb))
				pts.append(Vector2(xk + ww * 0.02, yb + h * 1.6))
				pts.append(Vector2(xk - ww * 0.02, yb + h * 1.6))
				pts.append(Vector2(xk - ww * 0.06, yb))
			pts.append(Vector2(x0, yb))
			ci.draw_colored_polygon(pts, C_CHEESE)
			outline(ci, pts, C_CHEESE_D, lw)
		R.LETTUCE:
			var ww := w * 1.12
			var x0 := cx - ww / 2
			var n := 14
			var pts := PackedVector2Array()
			for i in n + 1:
				var x := x0 + ww * i / n
				pts.append(Vector2(x, yb - h + sin(i * 1.9) * h * 0.25))
			for i in range(n, -1, -1):
				var x := x0 + ww * i / n
				pts.append(Vector2(x, yb + h * 0.35 + (h * 0.35 if i % 2 == 0 else -h * 0.1)))
			ci.draw_colored_polygon(pts, C_LETTUCE)
			outline(ci, pts, C_LETTUCE_D, lw)
		R.TOMATO:
			for i in 3:
				var sw := w * 0.36
				var sx := cx - w * 0.5 + i * w * 0.32
				var rect := Rect2(sx, yb - h, sw, h)
				var pts := rrect(rect, h * 0.5)
				ci.draw_colored_polygon(pts, C_TOMATO)
				fill_rrect(ci, rect.grow(-h * 0.22), h * 0.25, C_TOMATO_L)
				for s in 3:
					ci.draw_circle(Vector2(sx + sw * (0.3 + s * 0.2), yb - h * 0.5), maxf(1.0, h * 0.12), Color("ffe3a3"))
				outline(ci, pts, Color("a5221c"), lw)
		R.BACON:
			var ww := w * 1.04
			for k in 2:
				var pts := PackedVector2Array()
				var y := yb - h * (0.3 + k * 0.4)
				for i in 13:
					var x := cx - ww / 2 + ww * i / 12.0
					pts.append(Vector2(x, y + sin(i * 1.2 + k * 1.5) * h * 0.25))
				ci.draw_polyline(pts, C_BACON, h * 0.55, true)
				ci.draw_polyline(pts, C_BACON_L, h * 0.16, true)
		R.EGG:
			var pts := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24
				var wob := 1.0 + 0.06 * sin(a * 5.0)
				pts.append(Vector2(cx + cos(a) * w * 0.47 * wob, yb - h * 0.5 + sin(a) * h * 0.62 * wob))
			ci.draw_colored_polygon(pts, C_EGG)
			outline(ci, pts, Color("d8cfb8"), lw)
			var yc := Vector2(cx + w * 0.08, yb - h * 0.62)
			ci.draw_colored_polygon(ellipse(yc, h * 0.95, h * 0.7), C_YOLK)
			ci.draw_circle(yc + Vector2(-h * 0.3, -h * 0.25), h * 0.2, Color(1, 1, 1, 0.7))
		R.ONION:
			for i in 4:
				var c := Vector2(cx - w * 0.36 + i * w * 0.24, yb - h * 0.5)
				var e := ellipse(c, w * 0.13, h * 0.55, 20)
				outline(ci, e, C_ONION, maxf(2.0, h * 0.35))
				outline(ci, ellipse(c, w * 0.07, h * 0.25, 16), Color("e3c1ef"), maxf(1.0, h * 0.18))
		R.PICKLE:
			for i in 4:
				var c := Vector2(cx - w * 0.36 + i * w * 0.24, yb - h * 0.5)
				var e := ellipse(c, w * 0.12, h * 0.6, 20)
				ci.draw_colored_polygon(e, C_PICKLE)
				ci.draw_colored_polygon(ellipse(c, w * 0.07, h * 0.3, 14), C_PICKLE_L)
				outline(ci, e, Color("4d7a16"), lw * 0.8)
		R.BUN_TOP:
			var pts := PackedVector2Array()
			var c := Vector2(cx, yb - h * 0.2)
			for i in 25:
				var a := PI + PI * i / 24.0
				pts.append(c + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.8))
			pts.append(Vector2(cx + w * 0.5, yb - h * 0.08))
			pts.append(Vector2(cx + w * 0.47, yb))
			pts.append(Vector2(cx - w * 0.47, yb))
			pts.append(Vector2(cx - w * 0.5, yb - h * 0.08))
			ci.draw_colored_polygon(pts, C_BUN)
			fill_rrect(ci, Rect2(cx - w * 0.49, yb - h * 0.22, w * 0.98, h * 0.22), h * 0.1, C_BUN_D)
			var hl := PackedVector2Array()
			for i in 9:
				var a := PI * 1.15 + PI * 0.35 * i / 8.0
				hl.append(c + Vector2(cos(a) * w * 0.38, sin(a) * h * 0.6))
			ci.draw_polyline(hl, C_BUN_L, maxf(2.0, w * 0.035), true)
			var seeds := [[-0.25, 0.55], [-0.05, 0.7], [0.15, 0.6], [0.3, 0.42], [-0.35, 0.3], [0.02, 0.42], [0.2, 0.25], [-0.17, 0.33]]
			for s in seeds:
				var p := Vector2(cx + w * s[0], c.y - h * 0.8 * s[1])
				ci.draw_colored_polygon(ellipse(p, w * 0.03, w * 0.016, 10), Color("fff6dc"))
			outline(ci, pts, OUTLINE, lw)


static func draw_stack(ci: CanvasItem, layers: Array, cx: float, yb: float, w: float) -> void:
	var y := yb
	for l in layers:
		draw_layer(ci, l, cx, y, w)
		y -= layer_step(l, w)


# Ícone de botão: ingrediente centralizado dentro de um quadrado de lado `s`.
static func draw_icon(ci: CanvasItem, t: int, center: Vector2, s: float) -> void:
	if t == R.FRIES or t == R.SODA:
		draw_side(ci, t, center, s)
		return
	if t == R.BUN:
		var w := s * 0.8
		draw_layer(ci, R.BUN_BOTTOM, center.x, center.y + s * 0.32, w)
		draw_layer(ci, R.BUN_TOP, center.x, center.y + s * 0.08, w)
		return
	if t == R.EGG:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24
			pts.append(center + Vector2(cos(a), sin(a)) * s * 0.36 * (1.0 + 0.07 * sin(a * 5.0)))
		ci.draw_colored_polygon(pts, C_EGG)
		outline(ci, pts, Color("d8cfb8"), maxf(1.5, s / 50.0))
		ci.draw_circle(center + Vector2(s * 0.04, -s * 0.02), s * 0.15, C_YOLK)
		ci.draw_circle(center + Vector2(-s * 0.02, -s * 0.07), s * 0.04, Color(1, 1, 1, 0.8))
		return
	# camadas finas são "esticadas" na vertical para o ícone ficar legível
	var w := s * 0.85
	var h := layer_h(t, w)
	var k := clampf(s * 0.36 / h, 1.0, 3.2)
	if t == R.EGG:
		k = minf(k, 1.7)
	ci.draw_set_transform(center, 0.0, Vector2(1.0, k))
	draw_layer(ci, t, 0.0, h * 0.5, w)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_side(ci: CanvasItem, t: int, c: Vector2, s: float) -> void:
	var lw := maxf(1.5, s / 40.0)
	if t == R.FRIES:
		for i in 6:
			var x := c.x - s * 0.22 + i * s * 0.088
			var top := c.y - s * (0.42 - (i % 3) * 0.05)
			var r := Rect2(x, top, s * 0.07, s * 0.45)
			ci.draw_rect(r, Color("ffd23f"))
			ci.draw_rect(r, Color("e0a51a"), false, lw * 0.7)
		var box := PackedVector2Array([
			Vector2(c.x - s * 0.3, c.y - s * 0.12), Vector2(c.x + s * 0.3, c.y - s * 0.12),
			Vector2(c.x + s * 0.22, c.y + s * 0.4), Vector2(c.x - s * 0.22, c.y + s * 0.4)])
		ci.draw_colored_polygon(box, Color("e8343a"))
		ci.draw_circle(c + Vector2(0, s * 0.12), s * 0.09, Color("ffd23f"))
		outline(ci, box, Color("8f1a1e"), lw)
	elif t == R.SODA:
		var cup := PackedVector2Array([
			Vector2(c.x - s * 0.24, c.y - s * 0.25), Vector2(c.x + s * 0.24, c.y - s * 0.25),
			Vector2(c.x + s * 0.18, c.y + s * 0.42), Vector2(c.x - s * 0.18, c.y + s * 0.42)])
		ci.draw_line(c + Vector2(s * 0.05, -s * 0.28), c + Vector2(s * 0.16, -s * 0.48), Color("ff4f8b"), s * 0.06)
		ci.draw_colored_polygon(cup, Color("2a9df4"))
		var band := PackedVector2Array([
			Vector2(c.x - s * 0.215, c.y - s * 0.02), Vector2(c.x + s * 0.215, c.y - s * 0.02),
			Vector2(c.x + s * 0.2, c.y + s * 0.14), Vector2(c.x - s * 0.2, c.y + s * 0.14)])
		ci.draw_colored_polygon(band, Color.WHITE)
		fill_rrect(ci, Rect2(c.x - s * 0.28, c.y - s * 0.32, s * 0.56, s * 0.09), s * 0.04, Color("e8f4ff"))
		outline(ci, cup, Color("0f5a99"), lw)


static func star_points(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts


static func draw_star(ci: CanvasItem, c: Vector2, r: float, filled: bool) -> void:
	var pts := star_points(c, r)
	if filled:
		ci.draw_colored_polygon(pts, Color("ffd21f"))
		outline(ci, pts, Color("c7860a"), maxf(1.5, r * 0.12))
		ci.draw_circle(c + Vector2(-r * 0.15, -r * 0.2), r * 0.13, Color(1, 1, 1, 0.8))
	else:
		ci.draw_colored_polygon(pts, Color(0, 0, 0, 0.18))
		outline(ci, pts, Color(0, 0, 0, 0.3), maxf(1.5, r * 0.1))


static func draw_coin(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r, Color("c7860a"))
	ci.draw_circle(c, r * 0.85, Color("ffd21f"))
	ci.draw_circle(c, r * 0.6, Color("f5b70f"))
	ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.18, Color(1, 1, 1, 0.8))


static func text(ci: CanvasItem, font: Font, pos: Vector2, s: String, size: int, color: Color,
		align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0, outline_size: int = 0,
		outline_color: Color = Color.BLACK) -> void:
	if outline_size > 0:
		ci.draw_string_outline(font, pos, s, align, width, size, outline_size, outline_color)
	ci.draw_string(font, pos, s, align, width, size, color)
