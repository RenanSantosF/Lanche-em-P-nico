extends Control
# Chapa: as carnes cozinham com o tempo. Pronta = pode ir pro lanche.
# Se esquecer, queima e vai pro lixo. Redesenha no máximo ~15x por segundo.

const D = preload("res://scripts/Draw.gd")

signal patty_ready(slot: int)
signal patty_burnt(slot: int)
signal slot_tapped(slot: int)

const RAW := Color("e88a7d")
const RAW_D := Color("c4645a")
const DONE := Color("7b4226")
const DONE_D := Color("552b16")
const BURNT := Color("2b1d17")

var slots: Array = []  # cada um: {"on": bool, "t": float, "ready_sent": bool, "burnt_sent": bool}
var cook_time: float = 6.5
var burn_after: float = 6.0
var paused: bool = false
var hint_slot: int = -1
var _acc: float = 0.0
var _t: float = 0.0


func setup(n: int, cook: float, burn: float) -> void:
	slots = []
	for i in n:
		slots.append({"on": false, "t": 0.0, "ready_sent": false, "burnt_sent": false})
	cook_time = cook
	burn_after = burn
	mouse_filter = MOUSE_FILTER_STOP
	queue_redraw()


func clear() -> void:
	for s in slots:
		s["on"] = false
	queue_redraw()


func any_cooking() -> bool:
	for s in slots:
		if s["on"]:
			return true
	return false


func state_of(i: int) -> String:
	var s: Dictionary = slots[i]
	if not s["on"]:
		return "empty"
	if s["t"] >= cook_time + burn_after:
		return "burnt"
	if s["t"] >= cook_time:
		return "ready"
	return "raw"


func count_state(st: String) -> int:
	var n := 0
	for i in slots.size():
		if state_of(i) == st:
			n += 1
	return n


func first_in_state(st: String) -> int:
	# a carne pronta mais antiga primeiro (mais perto de queimar)
	var best := -1
	for i in slots.size():
		if state_of(i) == st and (best == -1 or slots[i]["t"] > slots[best]["t"]):
			best = i
	return best


func add_raw() -> bool:
	for s in slots:
		if not s["on"]:
			s["on"] = true
			s["t"] = 0.0
			s["ready_sent"] = false
			s["burnt_sent"] = false
			queue_redraw()
			return true
	return false


# Retorna o estado da carne retirada ("ready", "burnt", "raw" ou "empty").
func take(i: int) -> String:
	var st := state_of(i)
	if st == "ready" or st == "burnt":
		slots[i]["on"] = false
		queue_redraw()
	return st


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _slot_at(event.position.x)
		if i >= 0:
			slot_tapped.emit(i)
		accept_event()


func _slot_rect(i: int) -> Rect2:
	var n := slots.size()
	var sw := minf(170.0, (size.x - 120.0) / n)
	var x0 := 108.0 + ((size.x - 120.0) - sw * n) / 2.0
	return Rect2(x0 + i * sw, 8, sw, size.y - 16)


func _slot_at(x: float) -> int:
	for i in slots.size():
		var r := _slot_rect(i)
		if x >= r.position.x and x <= r.end.x:
			return i
	return -1


func _process(delta: float) -> void:
	_t += delta
	if paused:
		return
	var active := false
	for i in slots.size():
		var s: Dictionary = slots[i]
		if not s["on"]:
			continue
		active = true
		s["t"] += delta
		if not s["ready_sent"] and s["t"] >= cook_time:
			s["ready_sent"] = true
			patty_ready.emit(i)
			queue_redraw()
		if not s["burnt_sent"] and s["t"] >= cook_time + burn_after:
			s["burnt_sent"] = true
			patty_burnt.emit(i)
			queue_redraw()
	if active or hint_slot >= 0:
		_acc += delta
		if _acc >= 0.066:
			_acc = 0.0
			queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	D.fill_rrect(self, Rect2(0, 0, w, h), 14, Color("495057"))
	D.fill_rrect(self, Rect2(4, 4, w - 8, h - 8), 12, Color("343a40"))
	# placa "CHAPA"
	D.fill_rrect(self, Rect2(10, 12, 88, h - 24), 12, Color("e8590c"))
	D.text(self, Game.font, Vector2(10, h * 0.5 - 2), "CHAPA", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 88)
	var flame := 0.6 + 0.4 * sin(_t * 9.0)
	for k in 3:
		var fx := 32.0 + k * 20.0
		var fy := h * 0.5 + 24
		D.draw_flame(self, Vector2(fx, fy), 9.0 + flame * 3.0)
	for i in slots.size():
		_draw_slot(i)


func _draw_slot(i: int) -> void:
	var r := _slot_rect(i).grow(-4)
	var c := r.get_center()
	D.fill_rrect(self, r, 12, Color("212529"))
	var grate := PackedVector2Array()
	for k in 4:
		var y := r.position.y + 10 + k * (r.size.y - 20) / 3.0
		grate.append(Vector2(r.position.x + 8, y))
		grate.append(Vector2(r.end.x - 8, y))
	draw_multiline(grate, Color("2b3035"), 3.0)
	var st := state_of(i)
	if st == "empty":
		draw_arc(c, minf(r.size.x, r.size.y) * 0.3, 0, TAU, 20, Color(1, 1, 1, 0.12), 3.0)
		return
	var s: Dictionary = slots[i]
	var t: float = s["t"]
	var rx := minf(r.size.x * 0.36, 52.0)
	var ry := rx * 0.72
	var top: Color
	var dark: Color
	if st == "raw":
		var k := t / cook_time
		top = RAW.lerp(DONE, k)
		dark = RAW_D.lerp(DONE_D, k)
	elif st == "ready":
		var k := clampf((t - cook_time) / burn_after, 0.0, 1.0)
		top = DONE.lerp(BURNT, maxf(0.0, k - 0.5) * 1.2)
		dark = DONE_D.lerp(BURNT, maxf(0.0, k - 0.5))
	else:
		top = BURNT
		dark = Color("150d0a")
	var ring_r := rx + 12
	# anel de progresso
	if st == "raw":
		draw_arc(c, ring_r, -PI / 2, -PI / 2 + TAU * (t / cook_time), 24, Color("ffd43b"), 6.0)
	elif st == "ready":
		var left := 1.0 - (t - cook_time) / burn_after
		var col := Color("51cf66") if left > 0.4 else Color("ff6b6b")
		if left <= 0.4 and fmod(_t, 0.4) < 0.2:
			col = Color("ffa8a8")
		draw_arc(c, ring_r, -PI / 2, -PI / 2 + TAU * left, 24, col, 7.0)
	if i == hint_slot:
		draw_arc(c, ring_r + 8, 0, TAU, 24, Color(1, 1, 0.6, 0.5 + 0.5 * sin(_t * 8.0)), 5.0)
	draw_colored_polygon(D.ellipse(c + Vector2(0, 5), rx, ry, 20), dark)
	draw_colored_polygon(D.ellipse(c, rx, ry, 20), top)
	for k in 3:
		var x := c.x - rx * 0.5 + k * rx * 0.5
		draw_line(Vector2(x - 6, c.y - ry * 0.5), Vector2(x + 6, c.y + ry * 0.5), dark, 4.0)
	# fumaça / chiado
	var smoke := 0
	if st == "burnt":
		smoke = 4
	elif st == "ready" and (t - cook_time) / burn_after > 0.6:
		smoke = 2
	for k in smoke:
		var ph := fmod(_t * 0.8 + k * 0.27, 1.0)
		draw_circle(c + Vector2(sin(ph * 6.0 + k) * 10, -ry - ph * 40), 6 + ph * 10, Color(0.6, 0.6, 0.6, 0.6 * (1.0 - ph)))
	var label := ""
	var lc := Color.WHITE
	if st == "ready":
		label = "PRONTA!"
		lc = Color("8ce99a")
	elif st == "burnt":
		label = "QUEIMOU"
		lc = Color("ff8787")
	if label != "":
		D.text(self, Game.font, Vector2(r.position.x, r.end.y - 6), label, 17, lc, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 5, Color.BLACK)
