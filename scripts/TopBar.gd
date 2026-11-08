extends Control
# Barra de cima: dia, relógio, META do dia (3 estrelas), moedas.
# Faixa de baixo (transparente): combo, fila e Hora do Rush.
# Só redesenha quando algum valor muda.

const D = preload("res://scripts/Draw.gd")

const BAR_H := 84.0

var vals: Dictionary = {
	"day": 1, "time": 0, "ratio": 1.0, "coins": 0, "earned": 0, "goal": 50,
	"combo": 0, "line": 0, "rush": false, "closing": false,
}
var _coin_pop: float = 0.0
var _combo_pop: float = 0.0


func set_vals(v: Dictionary) -> void:
	var changed := false
	for k in v:
		var nv = v[k]
		if k == "ratio":
			nv = snappedf(nv, 0.01)
		if vals.get(k) != nv:
			if k == "combo" and nv > vals.get("combo", 0):
				_pop_combo()
			vals[k] = nv
			changed = true
	if changed:
		queue_redraw()


func bump_coins() -> void:
	create_tween().tween_method(_set_coin_pop, 1.0, 0.0, 0.4)


func _pop_combo() -> void:
	create_tween().tween_method(_set_combo_pop, 1.0, 0.0, 0.35)


func _set_coin_pop(v: float) -> void:
	_coin_pop = v
	queue_redraw()


func _set_combo_pop(v: float) -> void:
	_combo_pop = v
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var f := Game.font
	var bg := Color("5c2c0c")
	if vals["rush"]:
		bg = Color("8f1d1d")
	draw_rect(Rect2(0, 0, w, BAR_H), bg)
	draw_rect(Rect2(0, BAR_H - 6, w, 6), bg.darkened(0.35))
	# dia
	if vals["rush"]:
		D.fill_rrect(self, Rect2(84, 12, 104, 56), 24, Color("ffd43b"))
		D.text(self, f, Vector2(84, 40), L.t("HORA DO"), 15, Color("8f1d1d"), HORIZONTAL_ALIGNMENT_CENTER, 104)
		D.text(self, f, Vector2(84, 61), L.t("RUSH!"), 24, Color("c92a2a"), HORIZONTAL_ALIGNMENT_CENTER, 104)
	else:
		D.fill_rrect(self, Rect2(88, 16, 96, 48), 24, Color("ff8c42"))
		D.text(self, f, Vector2(88, 49), L.t("DIA %d") % vals["day"], D.fit(f, L.t("DIA %d") % vals["day"], 26, 90), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 96)
	# relógio
	var c := Vector2(222, 40)
	draw_circle(c, 27, Color("fff3e0"))
	var ratio: float = vals["ratio"]
	var col := Color("51cf66") if ratio > 0.25 else Color("ff6b6b")
	if vals["closing"]:
		col = Color("adb5bd")
	if ratio > 0.01:
		var pts := PackedVector2Array([c])
		var n := maxi(3, int(28 * ratio))
		for i in n + 1:
			var a := -PI / 2.0 + TAU * ratio * i / n
			pts.append(c + Vector2(cos(a), sin(a)) * 23.0)
		draw_colored_polygon(pts, col)
	draw_arc(c, 27, 0, TAU, 28, Color("3d1c06"), 3.0)
	var label := L.t("FIM") if vals["closing"] else str(vals["time"])
	D.text(self, f, Vector2(c.x - 28, c.y + 8), label, 20 if not vals["closing"] else 17, Color("3d1c06"), HORIZONTAL_ALIGNMENT_CENTER, 56, 5, Color(1, 1, 1, 0.85))
	# meta do dia
	var gx := 264.0
	var gw := w - 196 - gx - 14
	var goal: int = vals["goal"]
	var earned: int = vals["earned"]
	D.text(self, f, Vector2(gx, 30), L.t("META"), 17, Color("ffc9a3"))
	D.text(self, f, Vector2(gx, 30), "%d/%d" % [earned, goal], 17, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, gw)
	var bar := Rect2(gx, 40, gw, 18)
	D.fill_rrect(self, bar, 9, Color("3d1c06"))
	var full := float(goal * 2)
	var k := clampf(earned / full, 0.0, 1.0) if full > 0 else 0.0
	if k > 0.02:
		var bc := Color("ffd21f") if earned >= goal else Color("ff922b")
		D.fill_rrect(self, Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), 9, bc)
	for i in 3:
		var at: float = [0.5, 0.75, 1.0][i]
		var p := Vector2(bar.position.x + bar.size.x * at - (10 if i == 2 else 0), bar.position.y + 9)
		D.draw_star(self, p, 13, k >= at - 0.001)
	# moedas
	var pop := 1.0 + _coin_pop * 0.3
	var cr := Rect2(w - 190, 16, 176, 48)
	D.fill_rrect(self, cr, 24, Color("3d1c06"))
	D.draw_coin(self, Vector2(cr.position.x + 26, 40), 19 * pop)
	D.text(self, f, Vector2(cr.position.x + 50, 51), str(vals["coins"]), int(28 * pop), Color("ffd21f"))
	# ---- faixa de baixo (sobre a parede) ----
	var y2 := BAR_H + 10
	if vals["combo"] >= 2:
		var cp := 1.0 + _combo_pop * 0.4
		var r := Rect2(12, y2, 150 * cp, 44 * cp)
		D.fill_rrect(self, r, 22, Color("e8590c"))
		D.draw_flame(self, r.position + Vector2(26 * cp, 34 * cp), 13 * cp)
		D.text(self, f, Vector2(r.position.x + 40 * cp, r.position.y + 31 * cp), L.t("COMBO x%d") % vals["combo"], int(22 * cp), Color.WHITE)
	var line: int = vals["line"]
	if line > 0:
		var r := Rect2(w - 176, y2, 164, 44)
		D.fill_rrect(self, r, 22, Color(0.24, 0.11, 0.02, 0.85))
		D.text(self, f, Vector2(r.position.x + 14, r.position.y + 29), L.t("FILA"), 18, Color("ffc9a3"))
		var shown := mini(line, 4)
		for i in shown:
			var hc := Vector2(r.position.x + 74 + i * 18, r.position.y + 26)
			draw_circle(hc, 9, Color("ffd9b8"))
			draw_circle(hc + Vector2(0, -5), 7, Color("6b3e1f"))
		if line > 4:
			D.text(self, f, Vector2(r.position.x, r.position.y + 30), "+%d" % (line - 4), 16, Color("ffc9a3"), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 8)
