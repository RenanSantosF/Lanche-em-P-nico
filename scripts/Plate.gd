extends Control
# Prato onde o lanche é montado, com animação de cair e quicar.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

var layers: Array = []
var sides: Array = []
var _drop: float = 0.0
var _squash: float = 0.0
var _shake: float = 0.0
var _side_pop: float = 0.0


func set_build(l: Array, s: Array) -> void:
	layers = l.duplicate()
	sides = s.duplicate()
	queue_redraw()


func push_layer() -> void:
	var tw := create_tween()
	tw.tween_method(_set_drop, -140.0, 0.0, 0.32).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var tw2 := create_tween()
	tw2.tween_interval(0.12)
	tw2.tween_method(_set_squash, 1.0, 0.0, 0.3)


func push_side() -> void:
	var tw := create_tween()
	tw.tween_method(_set_side_pop, 1.0, 0.0, 0.3).set_trans(Tween.TRANS_BACK)


func shake() -> void:
	var tw := create_tween()
	tw.tween_method(_set_shake, 1.0, 0.0, 0.35)


func _draw() -> void:
	var cx := size.x * 0.5 + sin(_shake * 40.0) * 10.0 * _shake
	var plate_y := size.y - 34.0
	var pw := minf(size.x * 0.92, 300.0)
	# prato
	draw_colored_polygon(D.ellipse(Vector2(cx, plate_y + 10), pw * 0.5, 26), Color(0, 0, 0, 0.18))
	draw_colored_polygon(D.ellipse(Vector2(cx, plate_y), pw * 0.5, 24), Color("d9e6ee"))
	draw_colored_polygon(D.ellipse(Vector2(cx, plate_y - 3), pw * 0.38, 16), Color("ffffff"))

	var w := minf(size.x * 0.62, 200.0)
	var avail := plate_y - 20.0
	var h := D.stack_height(layers, w)
	if h > avail:
		w *= avail / h
	var sx := 1.0 + _squash * 0.08
	var sy := 1.0 - _squash * 0.08
	draw_set_transform(Vector2(cx, plate_y), 0.0, Vector2(sx, sy))
	var y := 0.0
	for i in layers.size():
		var off := _drop if i == layers.size() - 1 else 0.0
		D.draw_layer(self, layers[i], 0.0, y + off, w)
		y -= D.layer_step(layers[i], w)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# acompanhamentos ao lado do prato
	var slots := [[R.FRIES, Vector2(cx - pw * 0.4, plate_y - 30)], [R.SODA, Vector2(cx + pw * 0.4, plate_y - 34)]]
	for s in slots:
		if sides.has(s[0]):
			var sc := 1.0 + _side_pop * 0.3
			D.draw_side(self, s[0], s[1], 70.0 * sc)


func _set_drop(v: float) -> void:
	_drop = v
	queue_redraw()


func _set_squash(v: float) -> void:
	_squash = v
	queue_redraw()


func _set_shake(v: float) -> void:
	_shake = v
	queue_redraw()


func _set_side_pop(v: float) -> void:
	_side_pop = v
	queue_redraw()
