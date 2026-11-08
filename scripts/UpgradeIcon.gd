extends Control
# Ícone de item da loja.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

var upgrade: Dictionary = {}
var locked: bool = false


func _draw() -> void:
	var c := size / 2
	var s := minf(size.x, size.y)
	D.fill_rrect(self, Rect2(Vector2.ZERO, size), 18, Color("fff3e0") if not locked else Color("e9ecef"))
	match upgrade.get("kind", ""):
		"ing", "side":
			D.draw_icon(self, upgrade["item"], c, s * 0.8)
		"seat":
			D.fill_rrect(self, Rect2(c.x - s * 0.3, c.y - s * 0.3, s * 0.6, s * 0.16), 8, Color("e63946"))
			draw_line(c + Vector2(0, -s * 0.15), c + Vector2(0, s * 0.3), Color("868e96"), s * 0.08)
			draw_line(c + Vector2(-s * 0.2, s * 0.32), c + Vector2(s * 0.2, s * 0.32), Color("868e96"), s * 0.08)
			D.text(self, Game.font, Vector2(c.x + s * 0.05, c.y + s * 0.05), "+1", int(s * 0.3), Color("2b8a3e"), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)
		"grill", "speed":
			D.fill_rrect(self, Rect2(s * 0.12, c.y - s * 0.05, s * 0.76, s * 0.34), 8, Color("343a40"))
			draw_colored_polygon(D.ellipse(c + Vector2(0, s * 0.06), s * 0.24, s * 0.12), Color("7b4226"))
			for k in 3:
				D.draw_flame(self, Vector2(s * 0.3 + k * s * 0.2, s * 0.95), s * 0.1)
			if upgrade["kind"] == "speed":
				D.text(self, Game.font, Vector2(0, s * 0.3), "TURBO", int(s * 0.2), Color("e8590c"), HORIZONTAL_ALIGNMENT_CENTER, s, 6, Color.WHITE)
			else:
				D.text(self, Game.font, Vector2(0, s * 0.3), "+1", int(s * 0.28), Color("2b8a3e"), HORIZONTAL_ALIGNMENT_CENTER, s, 6, Color.WHITE)
		"decor":
			var base := c + Vector2(0, s * 0.18)
			for k in 5:
				var a := -PI / 2.0 + (k - 2) * 0.45
				var tip := base + Vector2(cos(a), sin(a)) * s * 0.38
				draw_line(base, tip, Color("2f9e44"), s * 0.08)
				draw_circle(tip, s * 0.07, Color("40c057"))
			D.fill_rrect(self, Rect2(c.x - s * 0.18, base.y - s * 0.02, s * 0.36, s * 0.26), 6, Color("e8590c"))
		"neon":
			D.fill_rrect(self, Rect2(s * 0.08, c.y - s * 0.22, s * 0.84, s * 0.44), 10, Color("1b1035"))
			D.text(self, Game.font, Vector2(s * 0.08, c.y + s * 0.1), "NEON", int(s * 0.26), Color("ff73c6"), HORIZONTAL_ALIGNMENT_CENTER, s * 0.84, 6, Color(1, 0.2, 0.7, 0.4))
		"tips":
			D.fill_rrect(self, Rect2(c.x - s * 0.25, c.y - s * 0.2, s * 0.5, s * 0.5), 10, Color(0.75, 0.9, 1.0, 0.8))
			for k in 3:
				D.draw_coin(self, c + Vector2((k - 1) * s * 0.12, s * 0.15 - k * s * 0.06), s * 0.1)
		"exhaust":
			var hood := PackedVector2Array([Vector2(s * 0.2, s * 0.62), Vector2(s * 0.8, s * 0.62), Vector2(s * 0.62, s * 0.3), Vector2(s * 0.38, s * 0.3)])
			draw_colored_polygon(hood, Color("adb5bd"))
			D.fill_rrect(self, Rect2(s * 0.42, s * 0.08, s * 0.16, s * 0.24), 4, Color("868e96"))
			for k in 3:
				draw_line(Vector2(s * (0.35 + k * 0.15), s * 0.86), Vector2(s * (0.38 + k * 0.15), s * 0.7), Color(0.6, 0.6, 0.6, 0.7), s * 0.04)
		"tv":
			D.fill_rrect(self, Rect2(s * 0.14, s * 0.2, s * 0.72, s * 0.5), 8, Color("343a40"))
			D.fill_rrect(self, Rect2(s * 0.19, s * 0.25, s * 0.62, s * 0.4), 4, Color("4dabf7"))
			draw_circle(Vector2(s * 0.4, s * 0.42), s * 0.07, Color("ffd43b"))
			draw_line(Vector2(s * 0.5, s * 0.7), Vector2(s * 0.5, s * 0.82), Color("343a40"), s * 0.05)
		"calm":
			D.fill_rrect(self, Rect2(s * 0.25, s * 0.38, s * 0.42, s * 0.4), 10, Color.WHITE)
			D.fill_rrect(self, Rect2(s * 0.28, s * 0.42, s * 0.36, s * 0.14), 6, Color("ffd8a8"))
			draw_arc(Vector2(s * 0.7, s * 0.56), s * 0.1, -PI / 2, PI / 2, 10, Color.WHITE, s * 0.05)
			for k in 2:
				draw_line(Vector2(s * (0.38 + k * 0.14), s * 0.32), Vector2(s * (0.42 + k * 0.14), s * 0.16), Color(0.7, 0.7, 0.7, 0.8), s * 0.03)
		"marketing":
			D.fill_rrect(self, Rect2(s * 0.22, s * 0.16, s * 0.5, s * 0.66), 6, Color("ffe066"))
			D.fill_rrect(self, Rect2(s * 0.3, s * 0.22, s * 0.5, s * 0.66), 6, Color("ff6b6b"))
			D.text(self, Game.font, Vector2(s * 0.3, s * 0.58), "$!", int(s * 0.28), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, s * 0.5)
		"helper":
			draw_circle(Vector2(s * 0.5, s * 0.58), s * 0.18, Color("ffd9b8"))
			D.fill_rrect(self, Rect2(s * 0.32, s * 0.32, s * 0.36, s * 0.14), 6, Color.WHITE)
			draw_circle(Vector2(s * 0.4, s * 0.28), s * 0.1, Color.WHITE)
			draw_circle(Vector2(s * 0.6, s * 0.28), s * 0.1, Color.WHITE)
			draw_circle(Vector2(s * 0.5, s * 0.22), s * 0.11, Color.WHITE)
			draw_circle(Vector2(s * 0.44, s * 0.58), s * 0.025, Color("2b1a10"))
			draw_circle(Vector2(s * 0.56, s * 0.58), s * 0.025, Color("2b1a10"))
			draw_arc(Vector2(s * 0.5, s * 0.63), s * 0.06, 0.2, PI - 0.2, 8, Color("7a2e1f"), s * 0.02)
	if locked:
		var lc := Vector2(size.x - 20, 20)
		D.fill_rrect(self, Rect2(lc.x - 11, lc.y - 4, 22, 18), 4, Color("495057"))
		draw_arc(lc + Vector2(0, -4), 7, PI, TAU, 10, Color("495057"), 4.0)
