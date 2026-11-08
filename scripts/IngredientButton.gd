extends BaseButton
# Botão grande de ingrediente / acompanhamento.
# Animações por transformação (scale/posição) para não redesenhar à toa.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")
const Baked = preload("res://scripts/Baked.gd")

var item: int = 0
var hint: bool = false:
	set(v):
		if v == hint:
			return
		hint = v
		_update_hint()
var progress: float = -1.0:   # 0..1 mostra barra (fritando / enchendo); -1 esconde
	set(v):
		if absf(v - progress) < 0.02 and not (v < 0.0 and progress >= 0.0):
			return
		progress = v
		if _over:
			_over.queue_redraw()
var ready_count: int = 0:     # porções prontas (batata)
	set(v):
		if v != ready_count:
			ready_count = v
			if _over:
				_over.queue_redraw()
var base_y: float = 0.0
var _hint_tw: Tween
var _face
var _over: Over


class Over extends Control:
	var host
	func _draw() -> void:
		host._draw_overlay(self)


func setup(it: int) -> void:
	item = it
	action_mode = ACTION_MODE_BUTTON_PRESS
	focus_mode = FOCUS_NONE
	button_down.connect(_on_down)
	resized.connect(_on_resized)
	_face = Baked.new()
	_face.setup(self, "_draw_face", 4.0)
	add_child(_face)
	_over = Over.new()
	_over.host = self
	_over.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_over)


func _on_resized() -> void:
	pivot_offset = size / 2
	_face.size = size
	_over.size = size


func _on_down() -> void:
	scale = Vector2(0.9, 0.9)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_hint() -> void:
	if _hint_tw:
		_hint_tw.kill()
		_hint_tw = null
	position.y = base_y
	queue_redraw()
	if hint:
		_hint_tw = create_tween().set_loops()
		_hint_tw.tween_property(self, "position:y", base_y - 8, 0.22).set_trans(Tween.TRANS_SINE)
		_hint_tw.tween_property(self, "position:y", base_y, 0.22).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	if hint:
		D.fill_rrect(self, Rect2(Vector2.ZERO, size).grow(5), 26, Color(1, 1, 0.7, 0.9))


# Parte estática (fundo, ícone, nome): assada numa textura uma vez só.
func _draw_face(ci: Control) -> void:
	var body := Rect2(Vector2.ZERO, size)
	D.fill_rrect(ci, Rect2(body.position + Vector2(0, 6), body.size), 20, Color(0, 0, 0, 0.25))
	var col: Color = R.TILE_COLORS.get(item, Color.WHITE)
	D.fill_rrect(ci, body, 20, col.darkened(0.25))
	D.fill_rrect(ci, Rect2(body.position, body.size - Vector2(0, 6)), 20, col)
	D.fill_rrect(ci, Rect2(body.position + Vector2(8, 5), Vector2(body.size.x - 16, body.size.y * 0.26)), 12, Color(1, 1, 1, 0.3))
	var icon_s := minf(body.size.x, body.size.y) * 0.6
	D.draw_icon(ci, item, Vector2(body.size.x / 2, body.size.y * 0.42), icon_s)
	var fs := D.fit(Game.font, L.t(R.NAMES[item]), 21 if size.x > 120 else 18, size.x - 10)
	D.text(ci, Game.font, Vector2(0, body.size.y - 14), L.t(R.NAMES[item]),
		fs, Color("4a2a12"), HORIZONTAL_ALIGNMENT_CENTER, body.size.x, 6, Color(1, 1, 1, 0.8))


# Indicadores dinâmicos ficam num filho desenhado por cima da textura.
func _draw_overlay(ci: Control) -> void:
	var body := Rect2(Vector2.ZERO, size)
	if progress >= 0.0:
		var b := Rect2(10, body.size.y * 0.72, body.size.x - 20, 10)
		D.fill_rrect(ci, b, 5, Color(0, 0, 0, 0.3))
		D.fill_rrect(ci, Rect2(b.position, Vector2(maxf(10.0, b.size.x * progress), b.size.y)), 5, Color("ff922b"))
	if ready_count > 0:
		var c := Vector2(body.size.x - 18, 18)
		ci.draw_circle(c, 16, Color("37b24d"))
		D.text(ci, Game.font, Vector2(c.x - 16, c.y + 8), str(ready_count), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 32)
