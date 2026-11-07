extends BaseButton
# Botão grande e fofinho de ingrediente / acompanhamento.

const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")

var item: int = 0
var hint: bool = false:
	set(v):
		hint = v
		queue_redraw()
var _pop: float = 0.0
var _t: float = 0.0


func setup(it: int) -> void:
	item = it
	action_mode = ACTION_MODE_BUTTON_PRESS
	focus_mode = FOCUS_NONE
	button_down.connect(_on_down)


func _on_down() -> void:
	var tw := create_tween()
	tw.tween_method(_set_pop, 1.0, 0.0, 0.25)


func _process(delta: float) -> void:
	if hint:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var squash := 1.0 - _pop * 0.08
	var inset := r.grow(-size.x * (1.0 - squash) * 0.5)
	var lift := 0.0
	if hint:
		lift = abs(sin(_t * 5.0)) * 6.0
		D.fill_rrect(self, inset.grow(5), 26, Color(1, 1, 1, 0.55 + 0.35 * sin(_t * 6.0)))
	var body := Rect2(inset.position - Vector2(0, lift), inset.size)
	D.fill_rrect(self, Rect2(body.position + Vector2(0, 7), body.size), 22, Color(0, 0, 0, 0.25))
	var col: Color = R.TILE_COLORS.get(item, Color.WHITE)
	D.fill_rrect(self, body, 22, col.darkened(0.25))
	D.fill_rrect(self, Rect2(body.position, body.size - Vector2(0, 6)), 22, col)
	D.fill_rrect(self, Rect2(body.position + Vector2(10, 6), Vector2(body.size.x - 20, body.size.y * 0.28)), 14, Color(1, 1, 1, 0.3))
	var icon_s := minf(body.size.x, body.size.y) * 0.62
	D.draw_icon(self, item, body.position + Vector2(body.size.x / 2, body.size.y * 0.42), icon_s)
	D.text(self, Game.font, Vector2(body.position.x, body.position.y + body.size.y - 16), R.NAMES[item],
		22, Color("4a2a12"), HORIZONTAL_ALIGNMENT_CENTER, body.size.x, 6, Color(1, 1, 1, 0.8))


func _set_pop(v: float) -> void:
	_pop = v
	queue_redraw()
