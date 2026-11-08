extends Control
# Barra de nível do chef. animate(de, para) enche a barra e avisa quando sobe de nível.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

signal leveled_up(level: int)

var shown_xp: float = 0.0
var dark: bool = false
var _level: int = 1


func set_xp(x: int) -> void:
	shown_xp = x
	_level = R.level_for_xp(x)
	queue_redraw()


func animate(from_xp: int, to_xp: int, delay: float = 0.6) -> void:
	set_xp(from_xp)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_method(_step, float(from_xp), float(to_xp), clampf((to_xp - from_xp) * 0.06, 0.4, 2.2)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _step(v: float) -> void:
	shown_xp = v
	var lv := R.level_for_xp(int(v))
	if lv > _level:
		_level = lv
		leveled_up.emit(lv)
	queue_redraw()


func _draw() -> void:
	var lv := R.level_for_xp(int(shown_xp))
	var a := R.xp_for_level(lv)
	var b := R.xp_for_level(lv + 1)
	var k := clampf((shown_xp - a) / float(b - a), 0.0, 1.0)
	var txt := Color.WHITE if dark else Color("4a2a12")
	# medalha do nível
	var c := Vector2(30, size.y / 2)
	draw_circle(c, 28, Color("c7860a"))
	draw_circle(c, 24, Color("ffd21f"))
	D.text(self, Game.font, Vector2(c.x - 28, c.y + 10), str(lv), 28, Color("5c2c0c"), HORIZONTAL_ALIGNMENT_CENTER, 56)
	var x0 := 70.0
	D.text(self, Game.font, Vector2(x0, size.y / 2 - 8), L.t(R.title_for_level(lv)), 24, txt)
	D.text(self, Game.font, Vector2(x0, size.y / 2 - 8), "%d/%d XP" % [int(shown_xp) - a, b - a], 18, txt.lerp(Color.GRAY, 0.3), HORIZONTAL_ALIGNMENT_RIGHT, size.x - x0)
	var bar := Rect2(x0, size.y / 2 + 2, size.x - x0, 18)
	D.fill_rrect(self, bar, 9, Color(0, 0, 0, 0.25))
	if k > 0.02:
		D.fill_rrect(self, Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), 9, Color("4dabf7"))
