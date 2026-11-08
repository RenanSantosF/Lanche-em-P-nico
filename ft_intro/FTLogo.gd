extends RefCounted
# Monograma FT (identidade visual). Desenho 100% vetorial, sem imagens.
# O "F" e o "T" compartilham a barra de cima; um nó de circuito laranja
# sai do braço do F (tecnologia). Coordenadas numa grade 0..100.

const BG := Color("14082e")
const BADGE_A := Color("ff006e")   # magenta (canto de cima/esquerda)
const BADGE_B := Color("8338ec")   # violeta (meio)
const BADGE_C := Color("3a86ff")   # azul (canto de baixo/direita)
const BADGE_TOP := BADGE_B
const EDGE := Color("ffbe0b")      # contorno amarelo vivo
const TRACE := Color("00f5d4")     # circuito verde-água
const LETTER_TOP := Color("ffffff")
const LETTER_BOT := Color("fff3b0")
const NODE := Color("00f5d4")
const PALETTE := [Color("ff006e"), Color("ffbe0b"), Color("00f5d4"), Color("3a86ff"), Color("fb5607"), Color("8338ec")]

# [x0, y0, x1, y1, direção de crescimento ("x" ou "y"), início, fim] (tempo 0..1)
const BARS := [
	[8.0, 14.0, 92.0, 31.0, "x", 0.00, 0.35],   # barra de cima (F + T)
	[8.0, 14.0, 25.0, 88.0, "y", 0.20, 0.55],   # haste do F
	[8.0, 46.0, 43.0, 61.0, "x", 0.45, 0.72],   # braço do meio do F
	[58.0, 14.0, 75.0, 88.0, "y", 0.55, 0.90],  # haste do T
]


static func _rr(x0: float, y0: float, x1: float, y1: float, r: float) -> PackedVector2Array:
	r = minf(r, minf(x1 - x0, y1 - y0) * 0.5 - 0.01)
	var pts := PackedVector2Array()
	var cs := [[x1 - r, y0 + r, -PI / 2.0], [x1 - r, y1 - r, 0.0], [x0 + r, y1 - r, PI / 2.0], [x0 + r, y0 + r, PI]]
	for c in cs:
		for i in 5:
			var a: float = c[2] + PI / 2.0 * i / 4.0
			pts.append(Vector2(c[0] + cos(a) * r, c[1] + sin(a) * r))
	return pts


static func _grad(pts: PackedVector2Array, y0: float, y1: float, c0: Color, c1: Color) -> PackedColorArray:
	var cols := PackedColorArray()
	for p in pts:
		cols.append(c0.lerp(c1, clampf((p.y - y0) / maxf(1.0, y1 - y0), 0.0, 1.0)))
	return cols


# degradê diagonal de 3 cores (magenta -> violeta -> azul)
static func _grad3(pts: PackedVector2Array, c: Vector2, half: float, a: float) -> PackedColorArray:
	var cols := PackedColorArray()
	for p in pts:
		var k := clampf(((p.x - c.x) + (p.y - c.y)) / (4.0 * half) + 0.5, 0.0, 1.0)
		var col := BADGE_A.lerp(BADGE_B, k * 2.0) if k < 0.5 else BADGE_B.lerp(BADGE_C, (k - 0.5) * 2.0)
		col.a = a
		cols.append(col)
	return cols


static func _xf(pts: PackedVector2Array, origin: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(origin + (p - Vector2(50, 50)) * s)
	return out


# draw: progresso do traçado 0..1 | badge: 0..1 (escala/alpha do fundo)
# node: 0..1 (nó laranja) | glow: 0..1 (brilho)
static func draw_logo(ci: CanvasItem, center: Vector2, size: float, draw: float = 1.0,
		badge: float = 1.0, node: float = 1.0, glow: float = 0.0) -> void:
	var s := size / 128.0
	# placa (badge)
	if badge > 0.0:
		var bs := s * (0.6 + 0.4 * badge)
		var bp := _xf(_rr(-14, -14, 114, 114, 30), center, bs)
		var a := clampf(badge, 0.0, 1.0)
		if glow > 0.0:
			for k in 3:
				var gp := _xf(_rr(-14 - k * 4, -14 - k * 4, 114 + k * 4, 114 + k * 4, 32 + k * 4), center, bs)
				ci.draw_colored_polygon(gp, Color(EDGE, 0.10 * glow * a))
		ci.draw_polygon(bp, _grad3(bp, center, 64 * bs, a))
		var closed := bp.duplicate()
		closed.append(bp[0])
		ci.draw_polyline(closed, Color(EDGE, 0.9 * a), maxf(2.0, 3.0 * s), true)
	# traço de circuito saindo da haste do T
	var tr := clampf((draw - 0.85) / 0.15, 0.0, 1.0)
	if tr > 0.0:
		var p0 := Vector2(66.5, 88)
		var p1 := Vector2(66.5, 98)
		var p2 := Vector2(92, 98)
		var path := PackedVector2Array([p0, p1])
		if tr > 0.3:
			path.append(p1.lerp(p2, (tr - 0.3) / 0.7))
		ci.draw_polyline(_xf(path, center, s), Color(TRACE, 0.95), maxf(2.0, 3.5 * s), true)
		if tr >= 1.0:
			ci.draw_circle(center + (p2 - Vector2(50, 50)) * s, 4.5 * s, TRACE)
	# barras das letras (primeiro todos os brilhos, depois as barras)
	var shapes := []
	for b in BARS:
		var k := clampf((draw - b[5]) / (b[6] - b[5]), 0.0, 1.0)
		if k <= 0.0:
			continue
		k = 1.0 - pow(1.0 - k, 3.0)
		var x1: float = b[2]
		var y1: float = b[3]
		if b[4] == "x":
			x1 = b[0] + (b[2] - b[0]) * k
		else:
			y1 = b[1] + (b[3] - b[1]) * k
		if x1 - b[0] < 1.0 or y1 - b[1] < 1.0:
			continue
		shapes.append([b[0], b[1], x1, y1])
	if glow > 0.0:
		for r in shapes:
			ci.draw_colored_polygon(_xf(_rr(r[0] - 3, r[1] - 3, r[2] + 3, r[3] + 3, 7), center, s), Color("5a1fb8").lerp(Color("ff5fa2"), 0.5 * glow))
	for r in shapes:
		var pts := _xf(_rr(r[0], r[1], r[2], r[3], 4.5), center, s)
		ci.draw_polygon(pts, _grad(pts, center.y + (14 - 50) * s, center.y + (88 - 50) * s, LETTER_TOP, LETTER_BOT))
	# nó laranja (ponta do braço do F)
	if node > 0.0:
		var nc := center + (Vector2(49.5, 53.5) - Vector2(50, 50)) * s
		var nr := 6.5 * s * node
		ci.draw_circle(nc, nr * 1.9, Color(NODE, 0.25 * minf(node, 1.0)))
		ci.draw_circle(nc, nr, NODE)
		ci.draw_circle(nc + Vector2(-nr * 0.3, -nr * 0.3), nr * 0.35, Color(1, 1, 1, 0.7))


static func draw_sparkle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := -PI / 2.0 + i * PI / 4.0
		var rr := r if i % 2 == 0 else r * 0.22
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, col)
