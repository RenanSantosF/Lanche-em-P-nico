extends Control
# Lanche em Pânico - controlador principal.
# Fluxo: Menu -> Dia (clientes chegam, monta lanche, entrega) -> Resultado -> Loja/Próximo dia.

const R = preload("res://scripts/Rules.gd")
const D = preload("res://scripts/Draw.gd")
const CustomerScript = preload("res://scripts/Customer.gd")
const IngBtn = preload("res://scripts/IngredientButton.gd")
const ActionBtn = preload("res://scripts/ActionButton.gd")
const PlateScript = preload("res://scripts/Plate.gd")
const TicketScript = preload("res://scripts/OrderTicket.gd")
const RestaurantScript = preload("res://scripts/Restaurant.gd")
const TopBarScript = preload("res://scripts/TopBar.gd")
const StarsScript = preload("res://scripts/StarsView.gd")
const UpgradeIconScript = preload("res://scripts/UpgradeIcon.gd")

enum { MENU, PLAY, CLOSING, RESULTS, SHOP, PAUSED }

const TOP_H := 84.0
const WORK_H := 340.0
const TILE_H := 124.0
const GAP := 12.0
const MAX_LINE := 8


class StarFx extends Control:
	var filled := true
	var radius := 26.0
	func _draw() -> void:
		preload("res://scripts/Draw.gd").draw_star(self, size / 2, radius, filled)


var state: int = MENU
var game_root: Control
var restaurant: Control
var counter_front: Control
var customer_layer: Control
var top_bar: Control
var work_bg: Panel
var tiles_bg: Panel
var ticket: Control
var plate: Control
var btn_deliver: BaseButton
var btn_trash: BaseButton
var btn_pause: BaseButton
var tiles: Dictionary = {}
var fx: Control
var banner: Label

var menu_screen: Control
var menu_day_label: Label
var menu_coins_label: Label
var hints_btn: Button
var sound_btn: Button
var overlay: ColorRect
var results_panel: PanelContainer
var shop_panel: PanelContainer
var pause_panel: PanelContainer
var shop_list: VBoxContainer
var shop_coins: Label

var seats: Array = []
var line_count: int = 0
var built: Array = []
var built_sides: Array = []
var selected = null
var time_left: float = 0.0
var day_len: float = 60.0
var spawn_t: float = 0.0
var stats: Dictionary = {}
var _tutorial_step: int = 0
var _menu_t: float = 0.0
var tile_h: float = TILE_H
var work_h: float = WORK_H


func _ready() -> void:
	theme = _make_theme()
	randomize()
	_build_game()
	_build_menu()
	_build_overlays()
	resized.connect(_layout)
	Game.coins_changed.connect(func(_v): _refresh_labels())
	_show_menu()
	Sfx.set_music(true)


# ------------------------------------------------------------------ tema
func _box(c: Color, radius: int = 26, border: int = 0, bc: Color = Color.BLACK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.border_width_bottom = 8 if border == 0 else border
	sb.border_color = c.darkened(0.3) if border == 0 else bc
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 18
	return sb


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = Game.font
	t.default_font_size = 30
	t.set_stylebox("normal", "Button", _box(Color("ff8c42")))
	t.set_stylebox("hover", "Button", _box(Color("ff9d5c")))
	t.set_stylebox("pressed", "Button", _box(Color("e8732a")))
	t.set_stylebox("disabled", "Button", _box(Color("ced4da")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(s, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("868e96"))
	t.set_constant("outline_size", "Button", 0)
	t.set_color("font_color", "Label", Color("4a2a12"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("fff8ec")
	panel.set_corner_radius_all(32)
	panel.border_width_bottom = 10
	panel.border_color = Color("e0b07a")
	panel.content_margin_left = 28
	panel.content_margin_right = 28
	panel.content_margin_top = 24
	panel.content_margin_bottom = 28
	t.set_stylebox("panel", "PanelContainer", panel)
	return t


func _btn(text: String, color: Color = Color("ff8c42"), font_size: int = 32) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("normal", _box(color))
	b.add_theme_stylebox_override("hover", _box(color.lightened(0.1)))
	b.add_theme_stylebox_override("pressed", _box(color.darkened(0.1)))
	b.button_down.connect(func(): Sfx.play("click"))
	return b


func _label(text: String, fs: int, color: Color = Color("4a2a12"), outline: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color("4a2a12"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


# ------------------------------------------------------------------ montagem da tela
func _build_game() -> void:
	game_root = Control.new()
	game_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(game_root)

	restaurant = RestaurantScript.new()
	restaurant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(restaurant)

	customer_layer = Control.new()
	customer_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(customer_layer)

	counter_front = RestaurantScript.new()
	counter_front.mode = "counter"
	counter_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(counter_front)

	work_bg = Panel.new()
	var wsb := StyleBoxFlat.new()
	wsb.bg_color = Color("c8d6df")
	wsb.border_width_top = 6
	wsb.border_color = Color("9fb3c0")
	work_bg.add_theme_stylebox_override("panel", wsb)
	work_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(work_bg)

	ticket = TicketScript.new()
	ticket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(ticket)

	plate = PlateScript.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(plate)

	btn_deliver = ActionBtn.new()
	btn_deliver.setup("ENTREGAR", Color("37b24d"), "check")
	btn_deliver.pressed.connect(_on_deliver)
	game_root.add_child(btn_deliver)

	btn_trash = ActionBtn.new()
	btn_trash.setup("LIXO", Color("f03e3e"), "trash")
	btn_trash.pressed.connect(_on_trash)
	game_root.add_child(btn_trash)

	tiles_bg = Panel.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color("8d5a3b")
	tsb.border_width_top = 8
	tsb.border_color = Color("6b3f25")
	tiles_bg.add_theme_stylebox_override("panel", tsb)
	tiles_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(tiles_bg)

	top_bar = TopBarScript.new()
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(top_bar)

	btn_pause = ActionBtn.new()
	btn_pause.setup("", Color("ff8c42"), "pause")
	btn_pause.pressed.connect(_on_pause)
	game_root.add_child(btn_pause)

	banner = _label("", 28, Color.WHITE, 10)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(banner)

	fx = Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fx)


func _tile_items() -> Array:
	var have := R.unlocked_ingredients(Game.owned)
	var items := [R.BUN]
	for i in [R.PATTY, R.CHEESE, R.LETTUCE, R.TOMATO, R.BACON, R.EGG, R.ONION, R.PICKLE]:
		if have.has(i):
			items.append(i)
	for s in R.unlocked_sides(Game.owned):
		items.append(s)
	return items


func _rebuild_tiles() -> void:
	for t in tiles.values():
		t.queue_free()
	tiles.clear()
	for it in _tile_items():
		var b := IngBtn.new()
		b.setup(it)
		b.pressed.connect(_on_tile.bind(it))
		game_root.add_child(b)
		tiles[it] = b
	game_root.move_child(top_bar, -1)
	game_root.move_child(btn_pause, -1)
	game_root.move_child(banner, -1)
	_layout()


func _work_y() -> float:
	var n := tiles.size()
	var rows := int(ceil(n / 4.0))
	rows = maxi(rows, 1)
	var base_panel := rows * (TILE_H + GAP) + GAP + 14
	var extra := maxf(0.0, size.y - TOP_H - WORK_H - base_panel - 440.0)
	tile_h = TILE_H + minf(46.0, extra * 0.45 / rows)
	work_h = WORK_H + minf(90.0, extra * 0.3)
	var panel_h := rows * (tile_h + GAP) + GAP + 14
	return size.y - panel_h - work_h


func _layout() -> void:
	if game_root == null:
		return
	var w := size.x
	var h := size.y
	var wy := _work_y()
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(w, TOP_H)
	btn_pause.position = Vector2(14, 12)
	btn_pause.size = Vector2(66, 60)
	restaurant.position = Vector2(0, TOP_H)
	restaurant.size = Vector2(w, wy - TOP_H)
	customer_layer.position = Vector2.ZERO
	customer_layer.size = size
	counter_front.position = Vector2(0, wy - 64)
	counter_front.size = Vector2(w, 64)
	work_bg.position = Vector2(0, wy)
	work_bg.size = Vector2(w, work_h)
	ticket.position = Vector2(12, wy + 14)
	ticket.size = Vector2(238, work_h - 28)
	var right := w - 146
	plate.position = Vector2(258, wy + 4)
	plate.size = Vector2(right - 258 - 6, work_h - 10)
	btn_deliver.position = Vector2(right, wy + 18)
	var dh := (work_h - 54) * 0.56
	btn_deliver.size = Vector2(134, dh)
	btn_trash.position = Vector2(right, wy + 36 + dh)
	btn_trash.size = Vector2(134, work_h - 54 - dh)
	tiles_bg.position = Vector2(0, wy + work_h)
	tiles_bg.size = Vector2(w, h - wy - work_h)
	var cols := 4
	var tw := (w - GAP * (cols + 1)) / cols
	var i := 0
	for it in tiles.keys():
		var b: Control = tiles[it]
		var col := i % cols
		var row := i / cols
		b.position = Vector2(GAP + col * (tw + GAP), wy + work_h + GAP + 6 + row * (tile_h + GAP))
		b.size = Vector2(tw, tile_h)
		i += 1
	banner.position = Vector2(10, wy - 52)
	banner.size = Vector2(w - 20, 50)
	_layout_customers(false)


func _seat_rect(i: int) -> Rect2:
	var w := size.x
	var n := seats.size()
	var sw := w / n
	var cw := minf(sw - 8, 230)
	var wy := _work_y()
	var counter_top := wy - 64
	var cy := maxf(TOP_H + 52, counter_top - 330)
	return Rect2(sw * i + (sw - cw) / 2, cy, cw, wy - cy)


func _layout_customers(animate: bool) -> void:
	for i in seats.size():
		var c = seats[i]
		if c == null or c.mood != "wait":
			continue
		var r := _seat_rect(i)
		c.size = r.size
		if animate:
			create_tween().tween_property(c, "position", r.position, 0.3)
		else:
			c.position = r.position


# ------------------------------------------------------------------ menu
func _build_menu() -> void:
	menu_screen = Control.new()
	menu_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu_screen)
	var bg := RestaurantScript.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.owned = {"plants": true, "lights": true}
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_screen.add_child(bg)
	var art := Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(_draw_menu_art.bind(art))
	art.set_process(true)
	menu_screen.add_child(art)
	menu_screen.set_meta("art", art)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = -240
	box.offset_right = 240
	box.offset_top = -470
	box.offset_bottom = -40
	box.add_theme_constant_override("separation", 18)
	menu_screen.add_child(box)

	menu_day_label = _label("", 30, Color.WHITE, 10)
	box.add_child(menu_day_label)
	var play := _btn("JOGAR", Color("37b24d"), 52)
	play.custom_minimum_size = Vector2(0, 120)
	play.pressed.connect(_start_day)
	box.add_child(play)
	var shop := _btn("EXPANDIR LANCHONETE", Color("ff8c42"), 30)
	shop.custom_minimum_size = Vector2(0, 86)
	shop.pressed.connect(_open_shop)
	box.add_child(shop)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	hints_btn = _btn("", Color("4dabf7"), 24)
	hints_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints_btn.custom_minimum_size = Vector2(0, 72)
	hints_btn.pressed.connect(func():
		Game.hints = not Game.hints
		Game.save_game()
		_refresh_labels())
	row.add_child(hints_btn)
	sound_btn = _btn("", Color("cc5de8"), 24)
	sound_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_btn.custom_minimum_size = Vector2(0, 72)
	sound_btn.pressed.connect(func():
		Game.sound = not Game.sound
		Game.save_game()
		Sfx.set_music(Game.sound)
		_refresh_labels())
	row.add_child(sound_btn)
	menu_coins_label = _label("", 26, Color("ffe066"), 8)
	box.add_child(menu_coins_label)


func _process(delta: float) -> void:
	if state == MENU:
		_menu_t += delta
		(menu_screen.get_meta("art") as Control).queue_redraw()
	elif state == PLAY or state == CLOSING:
		_tick(delta)


func _draw_menu_art(art: Control) -> void:
	var w := art.size.x
	var t := _menu_t
	art.draw_rect(Rect2(0, 0, w, art.size.y), Color(0.2, 0.08, 0.02, 0.35))
	var f := Game.font
	var title_y := 210.0 + sin(t * 2.0) * 6.0
	D.text(art, f, Vector2(0, title_y), "LANCHE", 104, Color("ffd21f"), HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color("5c2c0c"))
	D.text(art, f, Vector2(0, title_y + 100), "EM PÂNICO!", 84, Color("ff6b6b"), HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color("5c2c0c"))
	# lanche gigante que vai se montando
	var layers := [R.BUN_BOTTOM, R.LETTUCE, R.TOMATO, R.PATTY, R.CHEESE, R.BACON, R.EGG, R.BUN_TOP]
	var shown := int(fmod(t * 2.5, layers.size() + 4)) + 1
	shown = mini(shown, layers.size())
	var cx := w / 2
	var base := 640.0
	art.draw_colored_polygon(D.ellipse(Vector2(cx, base + 6), 170, 30), Color(0, 0, 0, 0.25))
	art.draw_colored_polygon(D.ellipse(Vector2(cx, base), 170, 28), Color("e9f1f6"))
	var y := base - 4
	for i in shown:
		var bounce := 0.0
		if i == shown - 1 and shown < layers.size():
			var ph := fmod(t * 2.5, 1.0)
			bounce = -pow(1.0 - ph, 3) * 80.0
		D.draw_layer(art, layers[i], cx, y + bounce, 230)
		y -= D.layer_step(layers[i], 230)
	for i in 3:
		var a := t * 1.5 + i * TAU / 3.0
		D.draw_star(art, Vector2(cx + cos(a) * 230, 520 + sin(a) * 40), 26, true)


func _refresh_labels() -> void:
	if menu_day_label:
		menu_day_label.text = "Dia %d   •   %d estrelas" % [Game.day, Game.total_stars]
		menu_coins_label.text = "Moedas: %d" % Game.coins
		hints_btn.text = "Dicas: %s" % ("SIM" if Game.hints else "NÃO")
		sound_btn.text = "Som: %s" % ("SIM" if Game.sound else "NÃO")
	if top_bar:
		top_bar.coins = Game.coins
	if shop_coins:
		shop_coins.text = "Suas moedas: %d" % Game.coins


func _show_menu() -> void:
	state = MENU
	_clear_customers()
	game_root.visible = false
	menu_screen.visible = true
	_hide_overlays()
	_refresh_labels()


# ------------------------------------------------------------------ overlays
func _build_overlays() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.1, 0.04, 0.0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	results_panel = _make_panel()
	shop_panel = _make_panel()
	pause_panel = _make_panel()

	# pausa
	var pb := pause_panel.get_child(0) as VBoxContainer
	pb.add_child(_label("Pausado", 48))
	var cont := _btn("CONTINUAR", Color("37b24d"), 36)
	cont.pressed.connect(_resume)
	pb.add_child(cont)
	var quit := _btn("SAIR PARA O MENU", Color("f03e3e"), 28)
	quit.pressed.connect(func():
		Game.save_game()
		_show_menu())
	pb.add_child(quit)

	# loja
	var sb := shop_panel.get_child(0) as VBoxContainer
	sb.add_child(_label("Expandir Lanchonete", 40))
	shop_coins = _label("", 28, Color("e8590c"))
	sb.add_child(shop_coins)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 760)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sb.add_child(scroll)
	shop_list = VBoxContainer.new()
	shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list.add_theme_constant_override("separation", 12)
	scroll.add_child(shop_list)
	var back := _btn("VOLTAR", Color("4dabf7"), 32)
	back.pressed.connect(_close_shop)
	sb.add_child(back)


func _make_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.custom_minimum_size = Vector2(640, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	add_child(p)
	p.visible = false
	return p


func _hide_overlays() -> void:
	overlay.visible = false
	results_panel.visible = false
	shop_panel.visible = false
	pause_panel.visible = false


func _pop_panel(p: Control) -> void:
	overlay.visible = true
	p.visible = true
	p.pivot_offset = p.size / 2
	p.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(p, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_pause() -> void:
	if state != PLAY and state != CLOSING:
		return
	pause_panel.set_meta("prev", state)
	state = PAUSED
	_set_customers_paused(true)
	_pop_panel(pause_panel)


func _resume() -> void:
	_hide_overlays()
	state = pause_panel.get_meta("prev", PLAY)
	_set_customers_paused(false)


func _set_customers_paused(p: bool) -> void:
	for c in seats:
		if c != null:
			c.paused = p


# ------------------------------------------------------------------ loja
func _open_shop() -> void:
	if state == RESULTS:
		results_panel.visible = false
	shop_panel.set_meta("from", state)
	state = SHOP
	_fill_shop()
	_refresh_labels()
	_pop_panel(shop_panel)


func _close_shop() -> void:
	var from: int = shop_panel.get_meta("from", MENU)
	shop_panel.visible = false
	if from == RESULTS:
		state = RESULTS
		results_panel.visible = true
	else:
		_show_menu()


func _fill_shop() -> void:
	for c in shop_list.get_children():
		c.queue_free()
	var items := R.UPGRADES.duplicate()
	# itens à venda primeiro, comprados no fim
	items.sort_custom(func(a, b):
		var oa := Game.owned.has(a["id"])
		var ob := Game.owned.has(b["id"])
		if oa != ob:
			return ob
		return a["price"] < b["price"])
	for u in items:
		var row := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("ffffff") if not Game.owned.has(u["id"]) else Color("e6f4ea")
		sb.set_corner_radius_all(20)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		row.add_theme_stylebox_override("panel", sb)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		row.add_child(h)
		var icon := UpgradeIconScript.new()
		icon.upgrade = u
		icon.custom_minimum_size = Vector2(96, 96)
		h.add_child(icon)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 2)
		h.add_child(v)
		var title := _label(u["name"], 28)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(title)
		var desc := _label(u["desc"], 20, Color("8a6a52"))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(desc)
		var b: Button
		if Game.owned.has(u["id"]):
			b = _btn("TEM!", Color("37b24d"), 24)
			b.disabled = true
		elif u.has("needs") and not Game.owned.has(u["needs"]):
			b = _btn("Bloq.", Color("adb5bd"), 22)
			b.disabled = true
		else:
			b = _btn(str(u["price"]), Color("ffb31f") if Game.coins >= u["price"] else Color("adb5bd"), 28)
			b.disabled = Game.coins < u["price"]
			b.pressed.connect(_buy.bind(u["id"]))
		b.custom_minimum_size = Vector2(130, 80)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
		shop_list.add_child(row)


func _buy(id: String) -> void:
	if Game.buy(id):
		Sfx.play("buy")
		_burst_confetti(Vector2(size.x / 2, size.y / 2))
		_fill_shop()
		_refresh_labels()


# ------------------------------------------------------------------ dia
func _start_day() -> void:
	_hide_overlays()
	menu_screen.visible = false
	game_root.visible = true
	state = PLAY
	_clear_customers()
	restaurant.owned = Game.owned
	counter_front.owned = Game.owned
	restaurant.menu_lines = []
	for r in R.available_recipes(Game.owned, Game.day):
		restaurant.menu_lines.append([r["name"], int(round(r["price"] * R.price_mult(Game.owned)))])
	restaurant.queue_redraw()
	counter_front.queue_redraw()
	seats = []
	for i in R.seat_count(Game.owned):
		seats.append(null)
	line_count = 0
	built = []
	built_sides = []
	selected = null
	day_len = R.day_duration(Game.day)
	time_left = day_len
	spawn_t = 1.0
	stats = {"served": 0, "stars": 0, "coins": 0, "tips": 0, "lost": 0, "perfect": 0}
	_rebuild_tiles()
	top_bar.day = Game.day
	_update_hud()
	_refresh_build()
	_tutorial_step = 0 if not Game.tutorial_done else 99
	if not Game.tutorial_done:
		_show_banner("Monte igual ao pedido: de baixo pra cima!", 4.0)
	else:
		_show_banner("DIA %d - Abrimos!" % Game.day)
	Sfx.play("fanfare")


func _clear_customers() -> void:
	for c in customer_layer.get_children():
		c.queue_free()
	seats = []
	selected = null


func _tick(delta: float) -> void:
	if state == PLAY:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			_start_closing()
		spawn_t -= delta
		if spawn_t <= 0.0:
			spawn_t = R.spawn_interval(Game.day, seats.size()) * randf_range(0.75, 1.25)
			_new_customer()
	elif state == CLOSING:
		var any := false
		for c in seats:
			if c != null:
				any = true
		if not any:
			_end_day()
	_update_hud()


func _update_hud() -> void:
	top_bar.time_left = time_left
	top_bar.time_ratio = time_left / day_len if day_len > 0 else 0.0
	top_bar.coins = Game.coins
	top_bar.stars = stats.get("stars", 0)
	top_bar.line = line_count
	top_bar.closing = state == CLOSING


func _start_closing() -> void:
	state = CLOSING
	if line_count > 0:
		_show_banner("Fechando! A fila foi pra casa.")
	else:
		_show_banner("Hora de fechar! Atenda quem ficou.")
	line_count = 0


func _new_customer() -> void:
	var free := seats.find(null)
	if free == -1:
		if line_count < MAX_LINE:
			line_count += 1
			Sfx.play("click", 0.7)
		else:
			stats["lost"] += 1
		return
	_spawn_in_seat(free)


func _spawn_in_seat(i: int) -> void:
	var recs := R.available_recipes(Game.owned, Game.day)
	# prefere lanches mais novos/complexos conforme os dias passam
	var rec: Dictionary = recs.pick_random()
	if recs.size() > 2 and randf() < 0.45:
		rec = recs[randi_range(recs.size() / 2, recs.size() - 1)]
	if Game.day == 1 and stats["served"] < 2:
		rec = recs[0] if recs.size() > 0 else rec
	var sides := []
	for s in R.unlocked_sides(Game.owned):
		if randf() < 0.4:
			sides.append(s)
	var c := CustomerScript.new()
	c.setup(rec, sides, R.max_patience(rec, sides, Game.day, Game.owned), R.order_value(rec, sides, Game.owned))
	c.tapped.connect(_on_customer_tapped)
	c.ran_out.connect(_on_customer_ran_out)
	customer_layer.add_child(c)
	seats[i] = c
	var r := _seat_rect(i)
	c.size = r.size
	c.position = Vector2(-r.size.x if i < seats.size() / 2.0 else size.x, r.position.y)
	var tw := create_tween()
	tw.tween_property(c, "position", r.position, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): c.waiting = true)
	Sfx.play("bell")
	if selected == null:
		_select(c)


func _on_customer_tapped(c) -> void:
	if c.mood != "wait":
		return
	Sfx.play("click", 1.3)
	_select(c)


func _select(c) -> void:
	if selected != null and is_instance_valid(selected):
		selected.selected = false
	selected = c
	if c != null:
		c.selected = true
	_refresh_build()


func _auto_select() -> void:
	var best = null
	for c in seats:
		if c != null and c.mood == "wait":
			if best == null or c.ratio() < best.ratio():
				best = c
	_select(best)


func _on_tile(item: int) -> void:
	if state != PLAY and state != CLOSING:
		return
	var layer := item
	if item == R.FRIES or item == R.SODA:
		if built_sides.has(item):
			built_sides.erase(item)
			Sfx.play("click", 0.8)
		else:
			built_sides.append(item)
			Sfx.play("pop", 1.2)
			plate.push_side()
		_refresh_build()
		return
	if _is_closed():
		Sfx.play("nope")
		plate.shake()
		_show_banner("Lanche fechado! Toque em ENTREGAR.")
		return
	if item == R.BUN:
		layer = R.BUN_BOTTOM if built.is_empty() else R.BUN_TOP
	if built.size() >= 12:
		Sfx.play("nope")
		plate.shake()
		return
	built.append(layer)
	Sfx.play("bun" if layer == R.BUN_BOTTOM or layer == R.BUN_TOP else "pop", 0.9 + built.size() * 0.06)
	plate.set_build(built, built_sides)
	plate.push_layer()
	if Game.hints and selected != null:
		var want: Array = selected.recipe["layers"]
		var k := built.size() - 1
		if k >= want.size() or want[k] != layer:
			plate.shake()
			Sfx.play("nope", 1.2)
	_refresh_build()
	if _tutorial_step == 0 and built.size() == 1:
		_tutorial_step = 1


func _is_closed() -> bool:
	return built.size() > 0 and built[-1] == R.BUN_TOP


func _refresh_build() -> void:
	plate.set_build(built, built_sides)
	if selected != null and is_instance_valid(selected) and selected.mood == "wait":
		ticket.show_order(selected.recipe, selected.sides, built, built_sides)
	else:
		ticket.show_order({}, [], built, built_sides)
	btn_deliver.disabled = built.is_empty()
	_update_hints()


func _update_hints() -> void:
	for t in tiles.values():
		t.hint = false
	btn_deliver.glow = false
	btn_trash.glow = false
	if not Game.hints or selected == null or not is_instance_valid(selected):
		btn_deliver.glow = _is_closed()
		return
	var want: Array = selected.recipe["layers"]
	var ok := true
	for i in built.size():
		if i >= want.size() or built[i] != want[i]:
			ok = false
	if not ok:
		btn_trash.glow = true
		return
	if built.size() < want.size():
		var nxt: int = want[built.size()]
		if nxt == R.BUN_BOTTOM or nxt == R.BUN_TOP:
			nxt = R.BUN
		if tiles.has(nxt):
			tiles[nxt].hint = true
		return
	var missing := false
	for s in selected.sides:
		if not built_sides.has(s) and tiles.has(s):
			tiles[s].hint = true
			missing = true
	if not missing:
		btn_deliver.glow = true


func _on_trash() -> void:
	if built.is_empty() and built_sides.is_empty():
		return
	built = []
	built_sides = []
	Sfx.play("trash")
	plate.shake()
	_refresh_build()


func _on_deliver() -> void:
	if built.is_empty():
		return
	if selected == null or not is_instance_valid(selected) or selected.mood != "wait":
		_auto_select()
		if selected == null:
			_show_banner("Nenhum cliente esperando!")
			Sfx.play("nope")
			return
	var c = selected
	var stars := R.grade(c.recipe["layers"], built, c.sides, built_sides)
	var pay := R.payout(c.value, stars, c.ratio())
	var earned: int = pay["coins"] + pay["tip"]
	c.waiting = false
	c.mood = "happy" if stars >= 2 else "sad"
	c.selected = false
	stats["served"] += 1
	stats["stars"] += stars
	stats["coins"] += earned
	stats["tips"] += pay["tip"]
	if stars == 3:
		stats["perfect"] += 1
	Game.add_coins(earned)
	top_bar.bump_coins()

	var head: Vector2 = c.position + Vector2(c.size.x / 2, c.bubble_h + 40)
	_burst_stars(head, stars)
	if earned > 0:
		_float_text(head + Vector2(0, -170), "+%d" % earned, Color("ffd21f"))
	if pay["tip"] > 0:
		_float_text(head + Vector2(0, -115), "Gorjeta!", Color("69db7c"), 0.25)
	match stars:
		3:
			Sfx.play("perfect")
			_float_text(head + Vector2(0, -230), ["PERFEITO!", "DELÍCIA!", "UAU!", "SHOW!"].pick_random(), Color("ff922b"))
			_burst_confetti(head)
			Input.vibrate_handheld(40)
		2:
			Sfx.play("good")
			_float_text(head + Vector2(0, -230), "Bom!", Color("74c0fc"))
		1:
			Sfx.play("good", 0.8)
			_float_text(head + Vector2(0, -230), "Hmm... quase", Color("ffa8a8"))
		0:
			Sfx.play("bad")
			_float_text(head + Vector2(0, -230), "Eca! Errado!", Color("ff6b6b"))
			Input.vibrate_handheld(80)

	built = []
	built_sides = []
	if _tutorial_step < 99:
		_tutorial_step = 99
		Game.tutorial_done = true
	_leave(c, 0.9)
	selected = null
	_auto_select()
	_refresh_build()


func _on_customer_ran_out(c) -> void:
	stats["lost"] += 1
	Sfx.play("bad", 0.8)
	_float_text(c.position + Vector2(c.size.x / 2, c.bubble_h - 20), "Cansei de esperar!", Color("ff6b6b"))
	Input.vibrate_handheld(60)
	var was_sel: bool = c == selected
	_leave(c, 0.6)
	if was_sel:
		selected = null
		_auto_select()
	_refresh_build()


func _leave(c, delay: float) -> void:
	var i := seats.find(c)
	var tw := create_tween()
	tw.tween_interval(delay)
	var out_x: float = -c.size.x - 20 if randf() < 0.5 else size.x + 20
	tw.tween_property(c, "position:x", out_x, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(c.queue_free)
	tw.tween_callback(_seat_freed.bind(i, c))


func _seat_freed(i: int, c) -> void:
	if i < 0 or i >= seats.size() or seats[i] != c:
		return
	seats[i] = null
	if state == PLAY and line_count > 0:
		line_count -= 1
		_spawn_in_seat(i)
	elif state == PLAY:
		spawn_t = minf(spawn_t, 2.0)


func _end_day() -> void:
	state = RESULTS
	var served: int = stats["served"]
	var avg := 0.0
	var total: int = served + stats["lost"]
	if total > 0:
		avg = float(stats["stars"]) / total
	var day_stars := clampi(int(round(avg)), 0, 3)
	if served == 0:
		day_stars = 0
	Game.total_stars += stats["stars"]
	Game.best_day_coins = max(Game.best_day_coins, stats["coins"])
	var finished_day := Game.day
	Game.day += 1
	Game.save_game()
	_show_results(finished_day, day_stars)


func _show_results(finished_day: int, day_stars: int) -> void:
	var v := results_panel.get_child(0) as VBoxContainer
	for c in v.get_children():
		c.queue_free()
	var titles := ["Dia difícil...", "Bom trabalho!", "Muito bem!", "INCRÍVEL!"]
	v.add_child(_label("Fim do Dia %d" % finished_day, 30, Color("8a6a52")))
	v.add_child(_label(titles[day_stars], 52, Color("e8590c")))
	var sv := StarsScript.new()
	sv.custom_minimum_size = Vector2(0, 150)
	v.add_child(sv)
	sv.reveal(day_stars)
	var lines := [
		"Clientes atendidos: %d" % stats["served"],
		"Lanches perfeitos: %d" % stats["perfect"],
		"Estrelas ganhas: %d" % stats["stars"],
		"Foram embora: %d" % stats["lost"],
	]
	for l in lines:
		v.add_child(_label(l, 28))
	v.add_child(_label("+%d moedas  (gorjetas: %d)" % [stats["coins"], stats["tips"]], 32, Color("e8590c")))
	var cheap := 999999
	for u in R.UPGRADES:
		if not Game.owned.has(u["id"]):
			cheap = mini(cheap, u["price"])
	if cheap < 999999 and Game.coins >= cheap:
		v.add_child(_label("Você pode comprar coisas novas!", 24, Color("2b8a3e")))
	var shop := _btn("EXPANDIR LANCHONETE", Color("ff8c42"), 28)
	shop.custom_minimum_size = Vector2(0, 80)
	shop.pressed.connect(_open_shop)
	v.add_child(shop)
	var nxt := _btn("PRÓXIMO DIA", Color("37b24d"), 36)
	nxt.custom_minimum_size = Vector2(0, 96)
	nxt.pressed.connect(_start_day)
	v.add_child(nxt)
	var menu := _btn("MENU", Color("4dabf7"), 24)
	menu.pressed.connect(_show_menu)
	v.add_child(menu)
	Sfx.play("fanfare")
	if day_stars == 3:
		_burst_confetti(Vector2(size.x / 2, size.y * 0.3))
	_pop_panel(results_panel)


# ------------------------------------------------------------------ efeitos
func _show_banner(text: String, hold: float = 1.8) -> void:
	banner.text = text
	banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(hold)
	tw.tween_property(banner, "modulate:a", 0.0, 0.4)


func _burst_stars(pos: Vector2, n: int) -> void:
	for i in 3:
		var s := StarFx.new()
		s.filled = i < n
		s.size = Vector2(60, 60)
		s.position = pos - s.size / 2
		s.pivot_offset = s.size / 2
		s.scale = Vector2.ZERO
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx.add_child(s)
		var target := pos + Vector2((i - 1) * 62, -90 - (14 if i == 1 else 0)) - s.size / 2
		var tw := create_tween()
		tw.tween_interval(i * 0.12)
		tw.set_parallel(true)
		tw.tween_property(s, "position", target, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.set_parallel(false)
		tw.tween_interval(0.7)
		tw.tween_property(s, "modulate:a", 0.0, 0.3)
		tw.tween_callback(s.queue_free)


func _float_text(pos: Vector2, text: String, color: Color, delay: float = 0.0) -> void:
	var l := _label(text, 40, color, 12)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(l)
	l.size = Vector2(400, 60)
	l.position = Vector2(clampf(pos.x - 200, 0, size.x - 400), pos.y)
	l.pivot_offset = l.size / 2
	l.scale = Vector2(0.3, 0.3)
	l.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	tw.tween_property(l, "position:y", pos.y - 70, 1.3)
	tw.set_parallel(false)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


func _burst_confetti(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = 60
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 1.4
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 250.0
	p.initial_velocity_max = 600.0
	p.gravity = Vector2(0, 900)
	p.scale_amount_min = 6.0
	p.scale_amount_max = 12.0
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	g.colors = PackedColorArray([Color("ff6b6b"), Color("ffd43b"), Color("69db7c"), Color("4dabf7"), Color("da77f2")])
	p.color_initial_ramp = g
	fx.add_child(p)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)
