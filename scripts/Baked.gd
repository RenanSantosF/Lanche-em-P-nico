extends Control
# "Assa" um desenho numa textura: o desenho (host.fn) roda só quando refresh() é chamado,
# e todo quadro custa 1 draw call. Ideal para celulares fracos.

class Painter extends Control:
	var baked
	func _draw() -> void:
		baked.host.call(baked.fn, self)


var host
var fn: String = ""
var pad: float = 0.0   # margem extra para desenhos que saem da área (sombras, etiquetas)
var _vp: SubViewport
var _p: Painter
var _pending := false


func setup(h, f: String, margin: float = 0.0) -> void:
	host = h
	fn = f
	pad = margin
	mouse_filter = MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	material = mat
	resized.connect(refresh)


func refresh() -> void:
	# agrupa vários pedidos no mesmo quadro
	if _pending:
		return
	_pending = true
	_do_refresh.call_deferred()


func _do_refresh() -> void:
	_pending = false
	if size.x < 1.0 or size.y < 1.0 or host == null:
		return
	if _vp == null:
		_vp = SubViewport.new()
		_vp.disable_3d = true
		_vp.transparent_bg = true
		_p = Painter.new()
		_p.baked = self
		_vp.add_child(_p)
		add_child(_vp)
	_vp.size = Vector2i(ceili(size.x + pad * 2), ceili(size.y + pad * 2))
	_p.position = Vector2(pad, pad)
	_p.size = size
	_p.queue_redraw()
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	queue_redraw()


func _draw() -> void:
	if _vp != null:
		draw_texture(_vp.get_texture(), Vector2(-pad, -pad))
