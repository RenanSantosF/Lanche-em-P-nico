extends Control
# Ícone de item da loja.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

var upgrade: Dictionary = {}


func _draw() -> void:
	var c := size / 2
	var s := minf(size.x, size.y)
	D.fill_rrect(self, Rect2(Vector2.ZERO, size), 18, Color("fff3e0"))
	match upgrade.get("kind", ""):
		"ing", "side":
			D.draw_icon(self, upgrade["item"], c, s * 0.8)
		"seat":
			D.fill_rrect(self, Rect2(c.x - s * 0.3, c.y - s * 0.3, s * 0.6, s * 0.16), 8, Color("e63946"))
			draw_line(c + Vector2(0, -s * 0.15), c + Vector2(0, s * 0.3), Color("868e96"), s * 0.08)
			draw_line(c + Vector2(-s * 0.2, s * 0.32), c + Vector2(s * 0.2, s * 0.32), Color("868e96"), s * 0.08)
			D.text(self, Game.font, Vector2(c.x + s * 0.05, c.y + s * 0.05), "+1", int(s * 0.3), Color("2b8a3e"), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)
		"decor":
			var base := c + Vector2(0, s * 0.18)
			for k in 5:
				var a := -PI / 2.0 + (k - 2) * 0.45
				var tip := base + Vector2(cos(a), sin(a)) * s * 0.38
				draw_line(base, tip, Color("2f9e44"), s * 0.08, true)
				draw_circle(tip, s * 0.07, Color("40c057"))
			D.fill_rrect(self, Rect2(c.x - s * 0.18, base.y - s * 0.02, s * 0.36, s * 0.26), 6, Color("e8590c"))
			if upgrade["id"] == "lights":
				for k in 4:
					draw_circle(Vector2(s * 0.15 + k * s * 0.23, s * 0.15), s * 0.06, [Color("ff6b6b"), Color("ffd43b"), Color("4dabf7"), Color("da77f2")][k])
		"neon":
			D.fill_rrect(self, Rect2(s * 0.08, c.y - s * 0.22, s * 0.84, s * 0.44), 10, Color("1b1035"))
			D.text(self, Game.font, Vector2(s * 0.08, c.y + s * 0.1), "NEON", int(s * 0.26), Color("ff73c6"), HORIZONTAL_ALIGNMENT_CENTER, s * 0.84, 6, Color(1, 0.2, 0.7, 0.4))
