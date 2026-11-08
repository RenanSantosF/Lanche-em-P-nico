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
	if locked:
		var lc := Vector2(size.x - 20, 20)
		D.fill_rrect(self, Rect2(lc.x - 11, lc.y - 4, 22, 18), 4, Color("495057"))
		draw_arc(lc + Vector2(0, -4), 7, PI, TAU, 10, Color("495057"), 4.0)
