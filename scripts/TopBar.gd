extends Control
# Barra de cima: dia, relógio, moedas, estrelas do dia e fila de espera.

const D = preload("res://scripts/Draw.gd")

var day: int = 1
var time_ratio: float = 1.0
var time_left: float = 0.0
var coins: int = 0
var stars: int = 0
var line: int = 0
var closing: bool = false
var _coin_pop: float = 0.0
var _t: float = 0.0


func bump_coins() -> void:
	var tw := create_tween()
	tw.tween_method(_set_pop, 1.0, 0.0, 0.4)


func _set_pop(v: float) -> void:
	_coin_pop = v
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	draw_rect(Rect2(0, 0, w, size.y), Color("5c2c0c"))
	draw_rect(Rect2(0, size.y - 6, w, 6), Color("3d1c06"))
	var f := Game.font
	# dia
	D.fill_rrect(self, Rect2(96, 14, 120, 52), 26, Color("ff8c42"))
	D.text(self, f, Vector2(96, 51), "DIA %d" % day, 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 120)
	# relógio
	var c := Vector2(258, 40)
	draw_circle(c, 28, Color("fff3e0"))
	var col := Color("51cf66") if time_ratio > 0.3 else Color("ff6b6b")
	if closing:
		col = Color("adb5bd")
	if time_ratio > 0.0:
		var pts := PackedVector2Array([c])
		var n := 30
		for i in n + 1:
			var a := -PI / 2.0 + TAU * time_ratio * i / n
			pts.append(c + Vector2(cos(a), sin(a)) * 24.0)
		if pts.size() >= 3:
			draw_colored_polygon(pts, col)
	draw_arc(c, 28, 0, TAU, 32, Color("3d1c06"), 3.0, true)
	var label := "%d" % int(ceil(time_left))
	if closing:
		label = "FIM"
	D.text(self, f, Vector2(c.x - 28, c.y + 9), label, 22 if not closing else 18, Color("3d1c06"), HORIZONTAL_ALIGNMENT_CENTER, 56, 5, Color(1, 1, 1, 0.8))
	# estrelas do dia
	D.draw_star(self, Vector2(316, 40), 20, true)
	D.text(self, f, Vector2(340, 51), str(stars), 28, Color.WHITE)
	# moedas
	var pop := 1.0 + _coin_pop * 0.35
	var cr := Rect2(w - 196, 14, 180, 52)
	D.fill_rrect(self, cr, 26, Color("3d1c06"))
	D.draw_coin(self, Vector2(cr.position.x + 28, 40), 20 * pop)
	D.text(self, f, Vector2(cr.position.x + 52, 52), str(coins), int(30 * pop), Color("ffd21f"))
	# fila
	var lx := 400.0
	if line > 0:
		D.text(self, f, Vector2(lx, 30), "FILA", 18, Color("ffc9a3"))
		var shown := mini(line, 5)
		for i in shown:
			var hc := Vector2(lx + 10 + i * 18, 52 + sin(_t * 6.0 + i) * 2.0)
			draw_circle(hc, 9, Color("ffd9b8"))
			draw_circle(hc + Vector2(0, -5), 7, Color("6b3e1f"))
		if line > 5:
			D.text(self, f, Vector2(lx + 100, 58), "+%d" % (line - 5), 20, Color("ffc9a3"))
