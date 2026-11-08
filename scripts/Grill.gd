extends Control
# Chapa: a carne assa com o tempo e QUEIMA se esquecer.
# O cheddar vai em cima da carne NA CHAPA e precisa derreter antes de servir.
# Redesenha no máximo ~15x por segundo (leve para celulares fracos).

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

signal patty_ready(slot: int)
signal patty_burnt(slot: int)
signal cheese_done(slot: int)
signal slot_tapped(slot: int)

const RAW := Color("ef8f80")
const RAW_D := Color("c4645a")
const DONE := Color("7b4226")
const DONE_D := Color("552b16")
const BURNT := Color("2b1d17")

# cada slot: on, t (tempo assando), cheese (tem cheddar), melt (tempo derretendo), avisos enviados
var slots: Array = []
var cook_time: float = 7.5
var burn_after: float = 6.0
var melt_time: float = 2.0
var paused: bool = false
var hint_slot: int = -1
var _acc: float = 0.0
var _t: float = 0.0


func setup(n: int, cook: float, burn: float, melt: float = R.MELT_TIME) -> void:
	slots = []
	for i in n:
		slots.append(_empty())
	cook_time = cook
	burn_after = burn
	melt_time = melt
	mouse_filter = MOUSE_FILTER_STOP
	queue_redraw()


func _empty() -> Dictionary:
	return {"on": false, "t": 0.0, "cheese": false, "melt": 0.0, "ready_sent": false, "burnt_sent": false, "melt_sent": false}


func clear() -> void:
	for i in slots.size():
		slots[i] = _empty()
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


func has_cheese(i: int) -> bool:
	return slots[i]["on"] and slots[i]["cheese"]


func cheese_melted(i: int) -> bool:
	return has_cheese(i) and slots[i]["melt"] >= melt_time


func count_state(st: String) -> int:
	var n := 0
	for i in slots.size():
		if state_of(i) == st:
			n += 1
	return n


# Carne pronta para servir (mais perto de queimar primeiro). with_cheese: -1 tanto faz, 0 sem, 1 com
func best_ready(with_cheese: int = -1) -> int:
	var best := -1
	for i in slots.size():
		if state_of(i) != "ready":
			continue
		if with_cheese == 0 and has_cheese(i):
			continue
		if with_cheese == 1 and not cheese_melted(i):
			continue
		if best == -1 or slots[i]["t"] > slots[best]["t"]:
			best = i
	return best


func add_raw() -> bool:
	for i in slots.size():
		if not slots[i]["on"]:
			slots[i] = _empty()
			slots[i]["on"] = true
			queue_redraw()
			return true
	return false


# Põe cheddar na carne mais adiantada que ainda não tem queijo. Retorna o slot ou -1.
func add_cheese() -> int:
	var best := -1
	for i in slots.size():
		var st := state_of(i)
		if st == "empty" or st == "burnt" or has_cheese(i):
			continue
		if best == -1 or slots[i]["t"] > slots[best]["t"]:
			best = i
	if best >= 0:
		slots[best]["cheese"] = true
		slots[best]["melt"] = 0.0
		queue_redraw()
	return best


# Tira a carne da chapa. Retorna "ready", "ready_cheese", "burnt", "raw", "melting" ou "empty".
func take(i: int) -> String:
	var st := state_of(i)
	if st == "ready" and has_cheese(i) and not cheese_melted(i):
		return "melting"
	if st == "ready" or st == "burnt":
		var cheese := has_cheese(i)
		slots[i] = _empty()
		queue_redraw()
		if st == "ready" and cheese:
			return "ready_cheese"
	return st


func slot_center(i: int) -> Vector2:
	return position + _slot_rect(i).get_center()


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
		if s["cheese"]:
			s["melt"] += delta
			if not s["melt_sent"] and s["melt"] >= melt_time:
				s["melt_sent"] = true
				cheese_done.emit(i)
		if not s["ready_sent"] and s["t"] >= cook_time:
			s["ready_sent"] = true
			patty_ready.emit(i)
		if not s["burnt_sent"] and s["t"] >= cook_time + burn_after:
			s["burnt_sent"] = true
			patty_burnt.emit(i)
	if active or hint_slot >= 0:
		_acc += delta
		if _acc >= 0.066:
			_acc = 0.0
			queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	D.fill_rrect(self, Rect2(0, 0, w, h), 14, Color("5c636a"))
	D.fill_rrect(self, Rect2(4, 4, w - 8, h - 8), 12, Color("2b3035"))
	draw_line(Vector2(14, 7), Vector2(w - 14, 7), Color(1, 1, 1, 0.12), 2.0)
	# placa "CHAPA" com chamas
	D.fill_rrect(self, Rect2(10, 12, 88, h - 24), 12, Color("e8590c"))
	D.fill_rrect(self, Rect2(10, 12, 88, (h - 24) * 0.45), 12, Color("ff922b"))
	D.text(self, Game.font, Vector2(10, h * 0.5 - 4), L.t("CHAPA"), D.fit(Game.font, L.t("CHAPA"), 19, 80), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 88, 6, Color("a33b06"))
	var any := any_cooking()
	for k in 3:
		var fl := 0.6 + 0.4 * sin(_t * 9.0 + k * 2.0) if any else 0.35
		D.draw_flame(self, Vector2(32.0 + k * 20.0, h * 0.5 + 30), 7.0 + fl * 5.0)
	for i in slots.size():
		_draw_slot(i)


func _draw_slot(i: int) -> void:
	var r := _slot_rect(i).grow(-4)
	var c := r.get_center() + Vector2(0, -4)
	D.fill_rrect(self, r, 12, Color("1e2226"))
	var grate := PackedVector2Array()
	for k in 4:
		var y := r.position.y + 10 + k * (r.size.y - 20) / 3.0
		grate.append(Vector2(r.position.x + 8, y))
		grate.append(Vector2(r.end.x - 8, y))
	draw_multiline(grate, Color("30363b"), 3.0)
	var st := state_of(i)
	if st == "empty":
		draw_arc(c, minf(r.size.x, r.size.y) * 0.3, 0, TAU, 20, Color(1, 1, 1, 0.1), 3.0)
		D.text(self, Game.font, Vector2(r.position.x, c.y + 7), "+", 26, Color(1, 1, 1, 0.18), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		return
	var s: Dictionary = slots[i]
	var t: float = s["t"]
	var rx := minf(r.size.x * 0.36, 50.0)
	var ry := rx * 0.7
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
	# gordura chiando em volta
	if st != "burnt":
		for k in 5:
			var a := k * 1.3 + _t * 0.5
			var p := c + Vector2(cos(a) * rx * 1.15, sin(a) * ry * 1.25)
			draw_circle(p, 2.0 + fmod(_t * 3.0 + k, 1.0) * 2.0, Color(1, 0.9, 0.6, 0.35))
	draw_colored_polygon(D.ellipse(c + Vector2(0, 5), rx, ry, 18), dark)
	draw_colored_polygon(D.ellipse(c, rx, ry, 18), top)
	draw_colored_polygon(D.ellipse(c + Vector2(-rx * 0.25, -ry * 0.3), rx * 0.45, ry * 0.25, 10), Color(1, 1, 1, 0.08))
	var marks := PackedVector2Array()
	for k in 3:
		var x := c.x - rx * 0.5 + k * rx * 0.5
		marks.append(Vector2(x - 6, c.y - ry * 0.5))
		marks.append(Vector2(x + 6, c.y + ry * 0.5))
	draw_multiline(marks, dark, 4.0)
	# cheddar derretendo em cima da carne
	if s["cheese"]:
		var m := clampf(s["melt"] / melt_time, 0.0, 1.0)
		_draw_cheese(c, rx * 0.95, ry, m)
	# vapor / fumaça
	var smoke := 0
	var smoke_col := Color(1, 1, 1, 0.35)
	if st == "burnt":
		smoke = 4
		smoke_col = Color(0.35, 0.35, 0.35, 0.7)
	elif st == "ready" and (t - cook_time) / burn_after > 0.6:
		smoke = 3
		smoke_col = Color(0.55, 0.55, 0.55, 0.6)
	elif st == "raw" and t > cook_time * 0.3:
		smoke = 2
	for k in smoke:
		var ph := fmod(_t * 0.8 + k * 0.33, 1.0)
		draw_circle(c + Vector2(sin(ph * 6.0 + k) * 10 - 10 + k * 10, -ry - ph * 38), 5 + ph * 9, Color(smoke_col, smoke_col.a * (1.0 - ph)))
	var label := ""
	var lc := Color.WHITE
	if st == "ready" and s["cheese"] and s["melt"] < melt_time:
		label = L.t("DERRETENDO")
		lc = Color("ffe066")
	elif st == "ready":
		label = L.t("PRONTA!")
		lc = Color("8ce99a")
	elif st == "burnt":
		label = L.t("QUEIMOU")
		lc = Color("ff8787")
	if label != "":
		D.text(self, Game.font, Vector2(r.position.x, r.end.y - 5), label, 16, lc, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 5, Color.BLACK)


func _draw_cheese(c: Vector2, w: float, h: float, m: float) -> void:
	# fatia quadrada que vai "escorrendo" pelas bordas conforme derrete
	var half := w * 0.62
	var droop := h * (0.15 + 0.75 * m)
	var col := Color("ffc61a").lerp(Color("ffb000"), m)
	var pts := PackedVector2Array([
		c + Vector2(0, -half * 0.62),
		c + Vector2(half, -h * 0.05),
		c + Vector2(half * 0.75, droop * 0.6),
		c + Vector2(half * 0.45, droop),
		c + Vector2(half * 0.2, droop * 0.55),
		c + Vector2(0, droop * 1.15),
		c + Vector2(-half * 0.3, droop * 0.6),
		c + Vector2(-half * 0.55, droop * 0.95),
		c + Vector2(-half * 0.8, droop * 0.5),
		c + Vector2(-half, -h * 0.05),
	])
	draw_colored_polygon(pts, col)
	D.outline(self, pts, Color("e09400"), 2.0)
	draw_circle(c + Vector2(-half * 0.25, -half * 0.2), half * 0.12, Color(1, 1, 1, 0.45))
