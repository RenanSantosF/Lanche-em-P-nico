extends ScrollContainer
# Rolagem por arrastar em QUALQUER ponto da lista (inclusive em cima dos itens e botões),
# com inércia. `dragged` fica true quando o toque virou arrasto, para os botões ignorarem o clique.

const DRAG_START := 14.0

var dragged: bool = false
var _tracking: bool = false
var _start_y: float = 0.0
var _start_scroll: float = 0.0
var _last_y: float = 0.0
var _last_ms: int = 0
var _vel: float = 0.0
var _pos: float = 0.0


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_rect().has_point(event.position):
				_tracking = true
				dragged = false
				_vel = 0.0
				_start_y = event.position.y
				_last_y = _start_y
				_last_ms = Time.get_ticks_msec()
				_start_scroll = scroll_vertical
				_pos = scroll_vertical
		else:
			_tracking = false
	elif event is InputEventMouseMotion and _tracking:
		var dy: float = event.position.y - _start_y
		if not dragged and absf(dy) > DRAG_START:
			dragged = true
		if dragged:
			_pos = _start_scroll - dy
			scroll_vertical = int(_pos)
			var now := Time.get_ticks_msec()
			var dt := maxf(1.0, now - _last_ms) / 1000.0
			_vel = lerpf(_vel, -(event.position.y - _last_y) / dt, 0.5)
			_last_y = event.position.y
			_last_ms = now


func _process(delta: float) -> void:
	if _tracking or absf(_vel) < 15.0:
		return
	_pos += _vel * delta
	_vel *= pow(0.04, delta)
	var max_scroll := maxf(0.0, get_child(0).size.y - size.y) if get_child_count() > 0 else 0.0
	_pos = clampf(_pos, 0.0, max_scroll)
	scroll_vertical = int(_pos)
	if _pos <= 0.0 or _pos >= max_scroll:
		_vel = 0.0
