extends Control
# Comanda: lista o pedido do cliente selecionado, de cima para baixo,
# marcando o que já foi colocado certo (verde) ou errado (vermelho).

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

var recipe: Dictionary = {}
var sides: Array = []
var built: Array = []
var built_sides: Array = []
var _t: float = 0.0


func show_order(rec: Dictionary, sd: Array, b: Array, bs: Array) -> void:
	recipe = rec
	sides = sd
	built = b
	built_sides = bs
	queue_redraw()


const SHOW_MARKS := false  # modo Normal: a comanda não diz o que está certo
var _acc: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	# só pisca a linha "próxima" no modo Fácil, e a ~10 quadros/s
	if SHOW_MARKS and not recipe.is_empty():
		_acc += delta
		if _acc > 0.1:
			_acc = 0.0
			queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	D.fill_rrect(self, Rect2(r.position + Vector2(0, 6), r.size), 16, Color(0, 0, 0, 0.2))
	D.fill_rrect(self, r, 16, Color("fffdf2"))
	D.fill_rrect(self, Rect2(0, 0, size.x, 50), 16, Color("ff8c42"))
	draw_rect(Rect2(0, 34, size.x, 16), Color("ff8c42"))
	if recipe.is_empty():
		D.text(self, Game.font, Vector2(0, 34), L.t("COMANDA"), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		D.text(self, Game.font, Vector2(10, size.y * 0.5), L.t("Esperando"), 22, Color("adb5bd"), HORIZONTAL_ALIGNMENT_CENTER, size.x - 20)
		D.text(self, Game.font, Vector2(10, size.y * 0.5 + 30), L.t("clientes..."), 22, Color("adb5bd"), HORIZONTAL_ALIGNMENT_CENTER, size.x - 20)
		return
	D.text(self, Game.font, Vector2(4, 34), L.t(recipe["name"]), D.fit(Game.font, L.t(recipe["name"]), 24, size.x - 16), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8)

	var layers: Array = recipe["layers"]
	var rows := layers.size() + sides.size()
	var top := 58.0
	var row_h := minf(50.0, (size.y - top - 8) / rows)
	var y := top
	var font_size := int(clampf(row_h * 0.55, 15, 26))
	var next_idx := built.size()
	var prefix_ok := true
	for i in built.size():
		if i >= layers.size() or built[i] != layers[i]:
			prefix_ok = false
	# de cima (último) para baixo (primeiro)
	for k in range(layers.size() - 1, -1, -1):
		var state := 0  # 0 pendente, 1 ok, 2 errado, 3 próximo
		if not SHOW_MARKS:
			pass
		elif k < built.size():
			state = 1 if built[k] == layers[k] else 2
		elif k == next_idx and prefix_ok:
			state = 3
		_row(layers[k], y, row_h, font_size, state)
		y += row_h
	for s in sides:
		_row(s, y, row_h, font_size, 1 if (SHOW_MARKS and built_sides.has(s)) else 0)
		y += row_h


func _row(item: int, y: float, h: float, fs: int, state: int) -> void:
	var rect := Rect2(6, y + 1, size.x - 12, h - 2)
	if state == 3:
		var p := 0.5 + 0.5 * sin(_t * 7.0)
		D.fill_rrect(self, rect, 10, Color(1.0, 0.85, 0.3, 0.35 + p * 0.35))
	elif state == 1:
		D.fill_rrect(self, rect, 10, Color(0.4, 0.85, 0.4, 0.25))
	elif state == 2:
		D.fill_rrect(self, rect, 10, Color(1.0, 0.35, 0.35, 0.3))
	var icon_s := h * 0.95
	D.draw_icon(self, item, Vector2(14 + icon_s * 0.5, y + h * 0.5), icon_s)
	var col := Color("5c3d2e")
	if state == 1:
		col = Color("2b8a3e")
	elif state == 2:
		col = Color("c92a2a")
	var item_name: String = L.t(R.NAMES[item])
	D.text(self, Game.font, Vector2(20 + icon_s, y + h * 0.5 + fs * 0.36), item_name, D.fit(Game.font, item_name, fs, size.x - icon_s - 54), col)
	var mark := Vector2(size.x - 24, y + h * 0.5)
	if state == 1:
		draw_polyline(PackedVector2Array([mark + Vector2(-9, 0), mark + Vector2(-2, 7), mark + Vector2(10, -8)]), Color("2b8a3e"), 5.0, true)
	elif state == 2:
		draw_line(mark + Vector2(-8, -8), mark + Vector2(8, 8), Color("c92a2a"), 5.0, true)
		draw_line(mark + Vector2(-8, 8), mark + Vector2(8, -8), Color("c92a2a"), 5.0, true)
