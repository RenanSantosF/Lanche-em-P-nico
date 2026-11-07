extends Control
# Fileira de 3 estrelas que aparecem uma a uma.

const D = preload("res://scripts/Draw.gd")

var stars: int = 0
var _scales: Array = [0.0, 0.0, 0.0]


func reveal(n: int) -> void:
	stars = n
	_scales = [0.0, 0.0, 0.0]
	for i in 3:
		var tw := create_tween()
		tw.tween_interval(0.25 + i * 0.3)
		tw.tween_method(_set_scale.bind(i), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if i < n:
			tw.tween_callback(Sfx.play.bind("coin", 1.0 + i * 0.15))


func _set_scale(v: float, i: int) -> void:
	_scales[i] = v
	queue_redraw()


func _draw() -> void:
	var r := minf(size.y * 0.45, size.x / 7.0)
	for i in 3:
		var c := Vector2(size.x / 2 + (i - 1) * r * 2.3, size.y / 2 - (r * 0.25 if i == 1 else 0.0))
		var rr: float = r * (1.15 if i == 1 else 1.0) * float(_scales[i])
		if rr > 1.0:
			D.draw_star(self, c, rr, i < stars)
