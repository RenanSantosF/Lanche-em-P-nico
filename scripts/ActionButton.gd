extends BaseButton
# Botões grandes de ação: ENTREGAR, LIXO e pausa.

const D = preload("res://scripts/Draw.gd")

var label: String = ""
var color: Color = Color("51cf66")
var icon: String = "check"
var glow: bool = false:
	set(v):
		glow = v
		queue_redraw()
var _pop: float = 0.0
var _t: float = 0.0


func setup(l: String, c: Color, ic: String) -> void:
	label = l
	color = c
	icon = ic
	action_mode = ACTION_MODE_BUTTON_PRESS
	focus_mode = FOCUS_NONE
	button_down.connect(_on_down)


func _on_down() -> void:
	var tw := create_tween()
	tw.tween_method(_set_pop, 1.0, 0.0, 0.25)


func _set_pop(v: float) -> void:
	_pop = v
	queue_redraw()


func _process(delta: float) -> void:
	if glow:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-size.x * _pop * 0.05)
	var c := color
	if disabled:
		c = Color("ced4da")
	if glow:
		var s := 0.5 + 0.5 * sin(_t * 7.0)
		D.fill_rrect(self, r.grow(4 + s * 4), 26, Color(1, 1, 0.6, 0.5 + 0.4 * s))
	D.fill_rrect(self, Rect2(r.position + Vector2(0, 7), r.size), 22, Color(0, 0, 0, 0.25))
	D.fill_rrect(self, r, 22, c.darkened(0.25))
	D.fill_rrect(self, Rect2(r.position, r.size - Vector2(0, 6)), 22, c)
	D.fill_rrect(self, Rect2(r.position + Vector2(10, 6), Vector2(r.size.x - 20, r.size.y * 0.25)), 12, Color(1, 1, 1, 0.25))
	var ic := r.position + Vector2(r.size.x / 2, r.size.y * (0.4 if label != "" else 0.47))
	var s := minf(r.size.x, r.size.y) * (0.22 if label != "" else 0.26)
	var white := Color.WHITE
	match icon:
		"check":
			draw_polyline(PackedVector2Array([ic + Vector2(-s, 0), ic + Vector2(-s * 0.3, s * 0.7), ic + Vector2(s, -s * 0.7)]), white, s * 0.4, true)
		"trash":
			D.fill_rrect(self, Rect2(ic.x - s * 0.7, ic.y - s * 0.5, s * 1.4, s * 1.4), s * 0.2, white)
			D.fill_rrect(self, Rect2(ic.x - s * 0.95, ic.y - s * 0.85, s * 1.9, s * 0.25), s * 0.1, white)
			D.fill_rrect(self, Rect2(ic.x - s * 0.3, ic.y - s * 1.05, s * 0.6, s * 0.25), s * 0.1, white)
			for k in [-1, 0, 1]:
				draw_line(ic + Vector2(k * s * 0.35, -s * 0.3), ic + Vector2(k * s * 0.35, s * 0.7), c.darkened(0.2), s * 0.15)
		"pause":
			D.fill_rrect(self, Rect2(ic.x - s * 0.7, ic.y - s * 0.8, s * 0.5, s * 1.6), s * 0.15, white)
			D.fill_rrect(self, Rect2(ic.x + s * 0.2, ic.y - s * 0.8, s * 0.5, s * 1.6), s * 0.15, white)
	if label != "":
		D.text(self, Game.font, Vector2(r.position.x, r.end.y - 20), label, 24, white,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 6, c.darkened(0.45))
