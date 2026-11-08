extends RefCounted
# Logo do jogo: o mascote "Lanchinho" (hambúrguer em pânico) com raios de sol,
# batata e refri. Usado no menu e para gerar o ícone do app.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

const INK := Color("3b1a08")


static func draw_sunburst(ci: CanvasItem, c: Vector2, r: float, rot: float, a: Color, b: Color, n: int = 18) -> void:
	ci.draw_circle(c, r, b)
	for i in n:
		var a0 := rot + TAU * i / n
		var a1 := a0 + TAU / n * 0.5
		ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r]), a)


# Mascote: c = centro, w = largura do lanche, t = tempo (anima olhos, suor, braços)
static func draw_mascot(ci: CanvasItem, c: Vector2, w: float, t: float = 0.0) -> void:
	var layers := [R.BUN_BOTTOM, R.LETTUCE, R.PATTY, R.CHEESE, R.TOMATO, R.BUN_TOP]
	var h := D.stack_height(layers, w)
	var yb := c.y + h * 0.5
	var lw := w * 0.035
	# perninhas
	for sgn in [-1, 1]:
		var hip := Vector2(c.x + sgn * w * 0.2, yb - w * 0.04)
		var foot := hip + Vector2(sgn * w * 0.05, w * 0.2 + sin(t * 10.0 + sgn) * w * 0.02)
		ci.draw_line(hip, foot, INK, lw * 1.4)
		ci.draw_colored_polygon(D.ellipse(foot + Vector2(sgn * w * 0.05, 0), w * 0.09, w * 0.05, 14), Color("e63946"))
	# bracinhos pra cima (pânico!)
	var arm_y := yb - h * 0.45
	for sgn in [-1, 1]:
		var sh := Vector2(c.x + sgn * w * 0.5, arm_y)
		var wave := sin(t * 12.0 + sgn * 1.3) * w * 0.05
		var el := sh + Vector2(sgn * w * 0.16, -w * 0.08)
		var hand := el + Vector2(sgn * w * 0.04 + wave, -w * 0.2)
		ci.draw_polyline(PackedVector2Array([sh, el, hand]), INK, lw * 1.4, true)
		ci.draw_circle(hand, w * 0.065, Color.WHITE)
		ci.draw_arc(hand, w * 0.065, 0, TAU, 14, INK, lw * 0.6)
	D.draw_stack(ci, layers, c.x, yb, w)
	# rosto no pão de cima
	var top_h := D.layer_h(R.BUN_TOP, w)
	var face_y := yb - h + top_h * 0.55
	var look := sin(t * 2.3) * w * 0.02
	for sgn in [-1, 1]:
		var e := Vector2(c.x + sgn * w * 0.15, face_y)
		ci.draw_colored_polygon(D.ellipse(e, w * 0.095, w * 0.115, 16), Color.WHITE)
		D.outline(ci, D.ellipse(e, w * 0.095, w * 0.115, 16), INK, lw * 0.6)
		ci.draw_circle(e + Vector2(look, w * 0.01), w * 0.045, INK)
		ci.draw_circle(e + Vector2(look - w * 0.015, -w * 0.015), w * 0.015, Color.WHITE)
		# sobrancelhas levantadas
		ci.draw_line(e + Vector2(-sgn * w * 0.05, -w * 0.21), e + Vector2(sgn * w * 0.09, -w * 0.15), INK, lw)
	# boca aberta de susto
	var m := Vector2(c.x, face_y + w * 0.125)
	ci.draw_colored_polygon(D.ellipse(m, w * 0.075, w * 0.06 + sin(t * 8.0) * w * 0.008, 14), Color("7a1f1f"))
	ci.draw_colored_polygon(D.ellipse(m + Vector2(0, w * 0.025), w * 0.04, w * 0.02, 10), Color("ff8fa3"))
	# gotas de suor
	for k in 2:
		var ph := fmod(t * 0.9 + k * 0.5, 1.0)
		var side := -1 if k == 0 else 1
		var p := Vector2(c.x + side * w * (0.42 + ph * 0.12), face_y - w * 0.12 + ph * w * 0.25)
		_drop(ci, p, w * 0.05, 1.0 - ph * 0.6)


static func _drop(ci: CanvasItem, p: Vector2, s: float, alpha: float) -> void:
	ci.draw_colored_polygon(D.ellipse(p, s, s, 12), Color(0.45, 0.8, 1.0, alpha))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.7, -s * 0.5), p + Vector2(0, -s * 1.8), p + Vector2(s * 0.7, -s * 0.5)]), Color(0.45, 0.8, 1.0, alpha))
	ci.draw_circle(p + Vector2(-s * 0.3, -s * 0.2), s * 0.25, Color(1, 1, 1, 0.7 * alpha))


# Composição completa (ícone do app / menu): fundo, raios, batata, refri e mascote.
static func draw_scene(ci: CanvasItem, c: Vector2, s: float, t: float = 0.0, rounded: bool = true, with_bg: bool = true) -> void:
	if with_bg:
		var rect := Rect2(c - Vector2(s, s) / 2, Vector2(s, s))
		if rounded:
			D.fill_rrect(ci, rect, s * 0.22, Color("ff5d2a"))
		else:
			ci.draw_rect(rect, Color("ff5d2a"))
		draw_sunburst(ci, c, s * (0.62 if not rounded else 0.48), t * 0.15, Color("ffb703"), Color("ff8c1a"))
		ci.draw_circle(c, s * 0.3, Color(1, 0.85, 0.3, 0.35))
	D.draw_side(ci, R.FRIES, c + Vector2(-s * 0.33, s * 0.17), s * 0.3)
	D.draw_side(ci, R.SODA, c + Vector2(s * 0.34, s * 0.15), s * 0.3)
	draw_mascot(ci, c + Vector2(0, s * 0.02), s * 0.5, t)
	# estrelinhas
	for i in 3:
		var p := c + Vector2([-0.36, 0.38, 0.0][i] * s, [-0.33, -0.3, -0.42][i] * s)
		D.draw_star(ci, p, s * (0.05 + 0.01 * sin(t * 3.0 + i)), true)
