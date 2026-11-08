extends Control
# Lanche em Pânico - controlador principal.
# Menu -> Dia (clientes, chapa, fritadeira, combo, rush, meta) -> Resultado (estrelas, XP) -> Loja.

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
const GrillScript = preload("res://scripts/Grill.gd")
const XpBarScript = preload("res://scripts/XpBar.gd")

enum { MENU, PLAY, CLOSING, RESULTS, SHOP, PAUSED }

const TOP_H := 84.0
const WORK_H := 300.0
const GRILL_H := 110.0
const TILE_H := 116.0
const GAP := 10.0
const MAX_LINE := 6


class StarFx extends Control:
	var filled := true
	var radius := 26.0
	func _draw() -> void:
		preload("res://scripts/Draw.gd").draw_star(self, size / 2, radius, filled)


var state: int = MENU
var rng := RandomNumberGenerator.new()

# nós do jogo
var game_root: Control
var restaurant: Control
var counter_front: Control
var customer_layer: Control
var top_bar: Control
var grill: Control
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

# menu / painéis
var menu_screen: Control
var menu_bg: Control
var menu_art: Control
var menu_xp: Control
var menu_info: Label
var mode_btn: Button
var sfx_btn: Button
var music_btn: Button
var overlay: ColorRect
var results_panel: PanelContainer
var shop_panel: PanelContainer
var pause_panel: PanelContainer
var mode_panel: PanelContainer
var shop_list: VBoxContainer
var shop_coins: Label

# estado do dia
var seats: Array = []
var line_count: int = 0
var built: Array = []
var built_sides: Array = []
var selected = null
var time_left: float = 0.0
var day_len: float = 60.0
var elapsed: float = 0.0
var spawn_t: float = 0.0
var goal: int = 50
var rush: Array = []
var in_rush: bool = false
var stats: Dictionary = {}
var fry_t: float = -1.0
var fries_ready: int = 0
var pour_t: float = -1.0
var announced: Dictionary = {}
var tut: int = 99
var tile_h: float = TILE_H
var work_h: float = WORK_H
var tile_cols: int = 4
var _menu_t: float = 0.0
var _menu_acc: float = 0.0


func _ready() -> void:
	rng.randomize()
	theme = _make_theme()
	_build_game()
	_build_menu()
	_build_overlays()
	resized.connect(_layout)
	Game.coins_changed.connect(func(_v): _refresh_labels())
	_show_menu()
	Sfx.set_music(true)
	if not Game.mode_chosen:
		_pop_panel(mode_panel)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_on_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()


func _on_back() -> void:
	match state:
		PLAY, CLOSING:
			_on_pause()
		PAUSED:
			_resume()
		SHOP:
			_close_shop()
		MENU:
			if mode_panel.visible:
				return
			Game.save_game()
			get_tree().quit()


# ------------------------------------------------------------------ tema / helpers de UI
func _box(c: Color, radius: int = 26) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.border_width_bottom = 8
	sb.border_color = c.darkened(0.3)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 12
	sb.content_margin_bottom = 16
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
	t.set_color("font_color", "Label", Color("4a2a12"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("fff8ec")
	panel.set_corner_radius_all(32)
	panel.border_width_bottom = 10
	panel.border_color = Color("e0b07a")
	panel.content_margin_left = 26
	panel.content_margin_right = 26
	panel.content_margin_top = 22
	panel.content_margin_bottom = 26
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


func _panel_rect(c: Color) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.border_width_top = 6
	sb.border_color = c.darkened(0.2)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


# ------------------------------------------------------------------ montagem da tela de jogo
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

	grill = GrillScript.new()
	grill.slot_tapped.connect(_on_grill_tap)
	grill.patty_ready.connect(func(_i): Sfx.play("ready", 1.0, -3.0))
	grill.patty_burnt.connect(_on_patty_burnt)
	game_root.add_child(grill)

	work_bg = _panel_rect(Color("c8d6df"))
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

	tiles_bg = _panel_rect(Color("8d5a3b"))
	game_root.add_child(tiles_bg)

	top_bar = TopBarScript.new()
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(top_bar)

	btn_pause = ActionBtn.new()
	btn_pause.setup("", Color("ff8c42"), "pause")
	btn_pause.pressed.connect(_on_pause)
	game_root.add_child(btn_pause)

	banner = _label("", 26, Color.WHITE, 10)
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
	for n in [top_bar, btn_pause, banner]:
		game_root.move_child(n, -1)
	_layout()


func _work_y() -> float:
	var n := maxi(tiles.size(), 1)
	tile_cols = 4 if n <= 8 else 6
	var rows := int(ceil(float(n) / tile_cols))
	var base_panel := rows * (TILE_H + GAP) + GAP + 12
	var extra := maxf(0.0, size.y - TOP_H - GRILL_H - WORK_H - base_panel - 470.0)
	tile_h = TILE_H + minf(40.0, extra * 0.4 / rows)
	work_h = WORK_H + minf(80.0, extra * 0.3)
	var panel_h := rows * (tile_h + GAP) + GAP + 12
	return size.y - panel_h - work_h


func _layout() -> void:
	if game_root == null:
		return
	var w := size.x
	var h := size.y
	var wy := _work_y()
	var gy := wy - GRILL_H
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(w, TOP_H + 64)
	btn_pause.position = Vector2(12, 12)
	btn_pause.size = Vector2(64, 60)
	restaurant.position = Vector2(0, TOP_H)
	restaurant.size = Vector2(w, gy - TOP_H)
	customer_layer.position = Vector2.ZERO
	customer_layer.size = size
	counter_front.position = Vector2(0, gy - 60)
	counter_front.size = Vector2(w, 60)
	grill.position = Vector2(0, gy)
	grill.size = Vector2(w, GRILL_H)
	work_bg.position = Vector2(0, wy)
	work_bg.size = Vector2(w, work_h)
	ticket.position = Vector2(10, wy + 12)
	ticket.size = Vector2(228, work_h - 24)
	var right := w - 142
	plate.position = Vector2(244, wy + 2)
	plate.size = Vector2(right - 244 - 4, work_h - 6)
	var dh := (work_h - 46) * 0.56
	btn_deliver.position = Vector2(right, wy + 14)
	btn_deliver.size = Vector2(132, dh)
	btn_trash.position = Vector2(right, wy + 30 + dh)
	btn_trash.size = Vector2(132, work_h - 46 - dh)
	tiles_bg.position = Vector2(0, wy + work_h)
	tiles_bg.size = Vector2(w, h - wy - work_h)
	var tw := (w - GAP * (tile_cols + 1)) / tile_cols
	var i := 0
	for it in tiles.keys():
		var b = tiles[it]
		var col := i % tile_cols
		var row := i / tile_cols
		b.position = Vector2(GAP + col * (tw + GAP), wy + work_h + GAP + 6 + row * (tile_h + GAP))
		b.base_y = b.position.y
		b.size = Vector2(tw, tile_h)
		i += 1
	banner.position = Vector2(10, gy - 54)
	banner.size = Vector2(w - 20, 50)
	_layout_customers()


func _seat_rect(i: int) -> Rect2:
	var w := size.x
	var n := maxi(seats.size(), 1)
	var sw := w / n
	var cw := minf(sw - 8, 230)
	var counter_top := _work_y() - GRILL_H - 60
	var cy := maxf(TOP_H + 56, counter_top - 330)
	return Rect2(sw * i + (sw - cw) / 2, cy, cw, counter_top + 60 - cy)


func _layout_customers() -> void:
	for i in seats.size():
		var c = seats[i]
		if c == null or c.mood != "wait":
			continue
		var r := _seat_rect(i)
		c.size = r.size
		c.position = r.position


# ------------------------------------------------------------------ menu
func _build_menu() -> void:
	menu_screen = Control.new()
	menu_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu_screen)
	menu_bg = RestaurantScript.new()
	menu_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_screen.add_child(menu_bg)
	menu_art = Control.new()
	menu_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_art.draw.connect(_draw_menu_art)
	menu_screen.add_child(menu_art)

	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = -260
	box.offset_right = 260
	box.offset_top = -560
	box.offset_bottom = -30
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 14)
	menu_screen.add_child(box)

	var card := PanelContainer.new()
	box.add_child(card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	card.add_child(cv)
	menu_xp = XpBarScript.new()
	menu_xp.custom_minimum_size = Vector2(0, 64)
	cv.add_child(menu_xp)
	menu_info = _label("", 22, Color("8a6a52"))
	cv.add_child(menu_info)

	var play := _btn("JOGAR", Color("37b24d"), 48)
	play.custom_minimum_size = Vector2(0, 110)
	play.pressed.connect(_start_day)
	box.add_child(play)
	var shop := _btn("LOJA / EXPANDIR", Color("ff8c42"), 30)
	shop.custom_minimum_size = Vector2(0, 80)
	shop.pressed.connect(_open_shop)
	box.add_child(shop)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	mode_btn = _btn("", Color("4dabf7"), 20)
	sfx_btn = _btn("", Color("cc5de8"), 20)
	music_btn = _btn("", Color("cc5de8"), 20)
	for b in [mode_btn, sfx_btn, music_btn]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 66)
		row.add_child(b)
	mode_btn.pressed.connect(func(): _pop_panel(mode_panel))
	sfx_btn.pressed.connect(func():
		Game.sfx_on = not Game.sfx_on
		Game.save_game()
		_refresh_labels())
	music_btn.pressed.connect(func():
		Game.music_on = not Game.music_on
		Game.save_game()
		Sfx.set_music(Game.music_on)
		_refresh_labels())


func _process(delta: float) -> void:
	if state == MENU:
		_menu_t += delta
		_menu_acc += delta
		if _menu_acc >= 1.0 / 30.0:
			_menu_acc = 0.0
			menu_art.queue_redraw()
	elif state == PLAY or state == CLOSING:
		_tick(delta)


func _draw_menu_art() -> void:
	var art := menu_art
	var w := art.size.x
	var t := _menu_t
	art.draw_rect(Rect2(0, 0, w, art.size.y), Color(0.2, 0.08, 0.02, 0.4))
	var f := Game.font
	var title_y := 190.0 + sin(t * 2.0) * 6.0
	D.text(art, f, Vector2(0, title_y), "LANCHE", 100, Color("ffd21f"), HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color("5c2c0c"))
	D.text(art, f, Vector2(0, title_y + 96), "EM PÂNICO!", 80, Color("ff6b6b"), HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color("5c2c0c"))
	var layers := [R.BUN_BOTTOM, R.LETTUCE, R.TOMATO, R.PATTY, R.CHEESE, R.BACON, R.EGG, R.BUN_TOP]
	var cyc := fmod(t * 2.2, layers.size() + 5.0)
	var shown := mini(int(cyc) + 1, layers.size())
	var cx := w / 2
	var base := minf(580.0, art.size.y - 600.0)
	if base < 380.0:
		return
	art.draw_colored_polygon(D.ellipse(Vector2(cx, base + 6), 160, 28), Color(0, 0, 0, 0.25))
	art.draw_colored_polygon(D.ellipse(Vector2(cx, base), 160, 26), Color("e9f1f6"))
	var y := base - 4
	for i in shown:
		var bounce := 0.0
		if i == shown - 1 and int(cyc) < layers.size():
			bounce = -pow(1.0 - fmod(cyc, 1.0), 3) * 70.0
		D.draw_layer(art, layers[i], cx, y + bounce, 210)
		y -= D.layer_step(layers[i], 210)


func _refresh_labels() -> void:
	if menu_info:
		var best_txt := ""
		if Game.best_combo >= 2:
			best_txt = "   •   Melhor combo x%d" % Game.best_combo
		menu_info.text = "Dia %d   •   %d moedas%s" % [Game.day, Game.coins, best_txt]
		mode_btn.text = "Modo: %s" % ("Fácil" if Game.easy else "Normal")
		sfx_btn.text = "Sons: %s" % ("SIM" if Game.sfx_on else "NÃO")
		music_btn.text = "Música: %s" % ("SIM" if Game.music_on else "NÃO")
		menu_xp.set_xp(Game.xp)
	if shop_coins:
		shop_coins.text = "Moedas: %d   •   Nível %d (%s)" % [Game.coins, Game.level(), R.title_for_level(Game.level())]


func _show_menu() -> void:
	state = MENU
	_clear_customers()
	grill.clear()
	Sfx.set_grill(false)
	Sfx.set_music(true, false)
	game_root.visible = false
	menu_screen.visible = true
	menu_bg.owned = Game.owned
	menu_bg.refresh()
	_hide_overlays()
	_refresh_labels()


# ------------------------------------------------------------------ painéis
func _build_overlays() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.1, 0.04, 0.0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	results_panel = _make_panel()
	shop_panel = _make_panel()
	pause_panel = _make_panel()
	mode_panel = _make_panel()

	var pb := pause_panel.get_child(0) as VBoxContainer
	pb.add_child(_label("Pausado", 48))
	var cont := _btn("CONTINUAR", Color("37b24d"), 36)
	cont.pressed.connect(_resume)
	pb.add_child(cont)
	var restart := _btn("RECOMEÇAR O DIA", Color("ff8c42"), 26)
	restart.pressed.connect(_start_day)
	pb.add_child(restart)
	var quit := _btn("SAIR PARA O MENU", Color("f03e3e"), 26)
	quit.pressed.connect(func():
		Game.save_game()
		_show_menu())
	pb.add_child(quit)

	var mb := mode_panel.get_child(0) as VBoxContainer
	mb.add_child(_label("Como você quer jogar?", 38))
	var easy := _btn("FÁCIL", Color("37b24d"), 34)
	easy.custom_minimum_size = Vector2(0, 90)
	easy.pressed.connect(_choose_mode.bind(true))
	mb.add_child(easy)
	mb.add_child(_label("Com dicas: o próximo ingrediente brilha e a comanda mostra o que está certo. Ótimo para crianças.", 20, Color("8a6a52")))
	var normal := _btn("NORMAL", Color("e8590c"), 34)
	normal.custom_minimum_size = Vector2(0, 90)
	normal.pressed.connect(_choose_mode.bind(false))
	mb.add_child(normal)
	mb.add_child(_label("Sem dicas: preste atenção na comanda e na chapa. Mais desafio!", 20, Color("8a6a52")))
	mb.add_child(_label("Dá pra trocar depois no menu.", 18, Color("adb5bd")))

	var sb := shop_panel.get_child(0) as VBoxContainer
	sb.add_child(_label("Loja da Lanchonete", 40))
	shop_coins = _label("", 22, Color("e8590c"))
	sb.add_child(shop_coins)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 780)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sb.add_child(scroll)
	shop_list = VBoxContainer.new()
	shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list.add_theme_constant_override("separation", 10)
	scroll.add_child(shop_list)
	var back := _btn("VOLTAR", Color("4dabf7"), 30)
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
	p.custom_minimum_size = Vector2(660, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	add_child(p)
	p.visible = false
	return p


func _hide_overlays() -> void:
	overlay.visible = false
	for p in [results_panel, shop_panel, pause_panel, mode_panel]:
		p.visible = false


func _pop_panel(p: Control) -> void:
	overlay.visible = true
	p.visible = true
	move_child(overlay, -1)
	move_child(p, -1)
	p.modulate.a = 0.0
	p.scale = Vector2.ONE
	await get_tree().process_frame
	p.pivot_offset = p.size / 2
	p.scale = Vector2(0.8, 0.8)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.12)


func _choose_mode(easy: bool) -> void:
	Game.easy = easy
	Game.mode_chosen = true
	Game.save_game()
	mode_panel.visible = false
	overlay.visible = false
	_refresh_labels()


func _on_pause() -> void:
	if state != PLAY and state != CLOSING:
		return
	pause_panel.set_meta("prev", state)
	state = PAUSED
	_set_paused(true)
	_pop_panel(pause_panel)


func _resume() -> void:
	_hide_overlays()
	state = pause_panel.get_meta("prev", PLAY)
	_set_paused(false)


func _set_paused(p: bool) -> void:
	for c in seats:
		if c != null:
			c.paused = p
	grill.paused = p
	Sfx.set_grill(not p and grill.any_cooking())


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
	var order := {"ok": 0, "poor": 1, "locked": 2, "max": 3}
	var items := R.UPGRADES.duplicate()
	items.sort_custom(func(a, b):
		var sa: int = order[Game.buy_state(a)]
		var sb2: int = order[Game.buy_state(b)]
		if sa != sb2:
			return sa < sb2
		var na := R.next_tier(Game.owned, a)
		var nb := R.next_tier(Game.owned, b)
		return int(na.get("price", 0)) < int(nb.get("price", 0)))
	for u in items:
		var st := Game.buy_state(u)
		var nt := R.next_tier(Game.owned, u)
		var row := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("e6f4ea") if st == "max" else (Color("f1f3f5") if st == "locked" else Color.WHITE)
		sb.set_corner_radius_all(20)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		row.add_theme_stylebox_override("panel", sb)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)
		var icon := UpgradeIconScript.new()
		icon.upgrade = u
		icon.locked = st == "locked"
		icon.custom_minimum_size = Vector2(92, 92)
		h.add_child(icon)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 0)
		h.add_child(v)
		var title_txt: String = u["name"]
		var mt := R.max_tier(u)
		if mt > 1:
			var tr := R.tier(Game.owned, u["id"])
			title_txt += "  " + "●".repeat(tr) + "○".repeat(mt - tr)
		var title := _label(title_txt, 26)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(title)
		var desc := _label(u["desc"], 19, Color("8a6a52"))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(desc)
		var b: Button
		match st:
			"max":
				b = _btn("TEM!", Color("37b24d"), 22)
				b.disabled = true
			"locked":
				b = _btn("Nível %d" % nt["level"], Color("adb5bd"), 20)
				b.disabled = true
			"poor":
				b = _btn(str(nt["price"]), Color("adb5bd"), 26)
				b.disabled = true
			_:
				b = _btn(str(nt["price"]), Color("ffb31f"), 26)
				b.pressed.connect(_buy.bind(u["id"]))
		b.custom_minimum_size = Vector2(124, 76)
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
	_clear_customers()
	state = PLAY
	restaurant.owned = Game.owned
	counter_front.owned = Game.owned
	restaurant.menu_lines = []
	for r in R.available_recipes(Game.owned, Game.day):
		restaurant.menu_lines.append([r["name"], int(round(r["price"] * R.price_mult(Game.owned)))])
	restaurant.refresh()
	counter_front.refresh()
	seats = []
	for i in R.seat_count(Game.owned):
		seats.append(null)
	grill.setup(R.grill_slots(Game.owned), R.cook_time(Game.owned), R.BURN_AFTER)
	line_count = 0
	built = []
	built_sides = []
	selected = null
	fry_t = -1.0
	fries_ready = 0
	pour_t = -1.0
	announced = {}
	day_len = R.day_duration(Game.day)
	time_left = day_len
	elapsed = 0.0
	spawn_t = 0.8
	goal = R.day_goal(Game.day, Game.owned)
	rush = R.rush_window(Game.day)
	in_rush = false
	stats = {"served": 0, "stars": 0, "coins": 0, "tips": 0, "lost": 0, "perfect": 0,
		"combo": 0, "best_combo": 0, "xp": 0, "burnt": 0}
	tut = 0 if not Game.tutorial_done else 99
	_rebuild_tiles()
	_update_hud()
	_refresh_build()
	Sfx.set_music(true, false)
	Sfx.play("fanfare")
	if tut == 0:
		_tutorial_banner()
		_spawn_in_seat(0)
	else:
		_show_banner("DIA %d  •  Meta: %d moedas" % [Game.day, goal], 2.5)


func _clear_customers() -> void:
	for c in customer_layer.get_children():
		c.queue_free()
	seats = []
	selected = null


func _tick(delta: float) -> void:
	# fritadeira / refri
	if fry_t >= 0.0:
		fry_t += delta
		if fry_t >= R.FRY_TIME:
			fry_t = -1.0
			fries_ready = mini(fries_ready + 1, 2)
			Sfx.play("fries_ready")
	if pour_t >= 0.0:
		pour_t += delta
		if pour_t >= R.POUR_TIME:
			pour_t = -1.0
			if not built_sides.has(R.SODA):
				built_sides.append(R.SODA)
				plate.push_side()
				Sfx.play("pop", 1.3)
				_refresh_build()
	if tiles.has(R.FRIES):
		tiles[R.FRIES].progress = fry_t / R.FRY_TIME if fry_t >= 0.0 else -1.0
		tiles[R.FRIES].ready_count = fries_ready
	if tiles.has(R.SODA):
		tiles[R.SODA].progress = pour_t / R.POUR_TIME if pour_t >= 0.0 else -1.0
	Sfx.set_grill(grill.any_cooking())
	if tut < 99:
		_tut_eval()
		_update_hud()
		_update_hints()
		return
	if state == PLAY:
		time_left -= delta
		elapsed += delta
		if time_left <= 0.0:
			time_left = 0.0
			_start_closing()
		var rush_now: bool = rush.size() == 2 and elapsed >= rush[0] and elapsed < rush[1]
		if rush_now != in_rush:
			in_rush = rush_now
			Sfx.set_music(true, in_rush)
			if in_rush:
				Sfx.play("rush")
				_show_banner("HORA DO RUSH! Muitos clientes!", 2.5)
				spawn_t = minf(spawn_t, 0.5)
		spawn_t -= delta
		if spawn_t <= 0.0:
			var iv := R.spawn_interval(Game.day, seats.size())
			if in_rush:
				iv /= 2.2
			spawn_t = iv * rng.randf_range(0.75, 1.25)
			_new_customer()
	elif state == CLOSING:
		var any := false
		for c in seats:
			if c != null:
				any = true
		if not any:
			_end_day()
	_update_hud()
	_update_hints()


func _update_hud() -> void:
	top_bar.set_vals({
		"day": Game.day, "time": int(ceil(time_left)), "ratio": time_left / day_len if day_len > 0 else 0.0,
		"coins": Game.coins, "earned": stats.get("coins", 0), "goal": goal,
		"combo": stats.get("combo", 0), "line": line_count, "rush": in_rush, "closing": state == CLOSING,
	})


func _start_closing() -> void:
	state = CLOSING
	in_rush = false
	Sfx.set_music(true, false)
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
		else:
			stats["lost"] += 1
			_break_combo()
		return
	_spawn_in_seat(free)


func _spawn_in_seat(i: int) -> void:
	var kind := R.pick_customer_kind(Game.day, rng)
	var rec: Dictionary
	if tut < 99:
		kind = "normal"
		rec = R.MENU[1] if R.available_recipes(Game.owned, Game.day).has(R.MENU[1]) else R.MENU[0]
	elif Game.day >= 4 and rng.randf() < 0.2:
		rec = R.custom_recipe(Game.owned, Game.day, rng)
	else:
		var recs := R.available_recipes(Game.owned, Game.day)
		rec = recs[rng.randi_range(0, recs.size() - 1)]
		if recs.size() > 2 and rng.randf() < 0.45:
			rec = recs[rng.randi_range(recs.size() / 2, recs.size() - 1)]
	var sides := []
	if tut >= 99:
		for s in R.unlocked_sides(Game.owned):
			if rng.randf() < 0.4:
				sides.append(s)
	var c := CustomerScript.new()
	c.setup(rec, sides, R.max_patience(rec, sides, Game.day, Game.owned, kind),
		R.order_value(rec, sides, Game.owned, kind), kind)
	c.tapped.connect(_on_customer_tapped)
	c.ran_out.connect(_on_customer_ran_out)
	customer_layer.add_child(c)
	seats[i] = c
	var r := _seat_rect(i)
	c.size = r.size
	c.position = Vector2(-r.size.x if i < seats.size() / 2.0 else size.x, r.position.y)
	var tw := create_tween()
	tw.tween_property(c, "position", r.position, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_arrived.bind(c))
	if tut < 99:
		c.paused = true
	Sfx.play("bell")
	if kind == "vip" and not announced.has("vip"):
		announced["vip"] = true
		_show_banner("Cliente VIP! Paga em dobro, mas tem pressa!", 2.5)
	elif kind == "critic" and not announced.has("critic"):
		announced["critic"] = true
		_show_banner("CRÍTICO! Só paga se ficar PERFEITO (paga x3)", 2.8)
	elif rec.get("custom", false) and not announced.has("custom"):
		announced["custom"] = true
		_show_banner("Pedido \"Do Meu Jeito\": confira a comanda!", 2.5)
	if selected == null:
		_select(c)


func _arrived(c) -> void:
	if is_instance_valid(c):
		c.waiting = true


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


# ------------------------------------------------------------------ ações
func _on_tile(item: int) -> void:
	if state != PLAY and state != CLOSING:
		return
	if item == R.PATTY:
		if grill.add_raw():
			Sfx.play("sizzle")
		else:
			_nope("Chapa cheia!")
		return
	if item == R.FRIES:
		if built_sides.has(R.FRIES):
			built_sides.erase(R.FRIES)
			fries_ready = mini(fries_ready + 1, 2)
			Sfx.play("click", 0.8)
			_refresh_build()
		elif fries_ready > 0:
			fries_ready -= 1
			built_sides.append(R.FRIES)
			plate.push_side()
			Sfx.play("pop", 1.2)
			_refresh_build()
		elif fry_t < 0.0:
			fry_t = 0.0
			Sfx.play("fry")
		else:
			_nope("Fritando...")
		return
	if item == R.SODA:
		if built_sides.has(R.SODA):
			built_sides.erase(R.SODA)
			Sfx.play("click", 0.8)
			_refresh_build()
		elif pour_t < 0.0:
			pour_t = 0.0
			Sfx.play("pour")
		return
	if _is_closed():
		_nope("Lanche fechado! Toque em ENTREGAR.")
		return
	var layer := item
	if item == R.BUN:
		layer = R.BUN_BOTTOM if built.is_empty() else R.BUN_TOP
	_add_layer(layer)


func _add_layer(layer: int) -> void:
	if built.size() >= 12:
		_nope("")
		return
	built.append(layer)
	Sfx.play("bun" if layer == R.BUN_BOTTOM or layer == R.BUN_TOP else "pop", 0.9 + built.size() * 0.05)
	plate.set_build(built, built_sides)
	plate.push_layer()
	if Game.easy and selected != null and is_instance_valid(selected):
		var want: Array = selected.recipe["layers"]
		var k := built.size() - 1
		if k >= want.size() or want[k] != layer:
			plate.shake()
			Sfx.play("nope", 1.2)
	_refresh_build()


func _on_grill_tap(i: int) -> void:
	if state != PLAY and state != CLOSING:
		return
	match grill.state_of(i):
		"empty":
			_on_tile(R.PATTY)
		"raw":
			_nope("Ainda assando!")
		"burnt":
			grill.take(i)
			Sfx.play("trash")
			_float_text(grill.position + Vector2(size.x / 2, 0), "Carne queimada no lixo", Color("ffa8a8"))
		"ready":
			if _is_closed():
				_nope("Lanche fechado! Toque em ENTREGAR.")
				return
			grill.take(i)
			_add_layer(R.PATTY)


func _on_patty_burnt(_i: int) -> void:
	stats["burnt"] += 1
	Sfx.play("burnt")
	_show_banner("Queimou! Toque na carne pra jogar fora.")


func _nope(msg: String) -> void:
	Sfx.play("nope")
	plate.shake()
	if msg != "":
		_show_banner(msg, 1.2)


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
	var want_tile := -999
	var want_slot := -1
	var deliver := _is_closed()
	var trash := false
	if (Game.easy or tut < 99) and selected != null and is_instance_valid(selected):
		var want: Array = selected.recipe["layers"]
		var ok := true
		for i in built.size():
			if i >= want.size() or built[i] != want[i]:
				ok = false
		deliver = false
		if not ok:
			trash = true
		elif built.size() < want.size():
			var nxt: int = want[built.size()]
			if nxt == R.BUN_BOTTOM or nxt == R.BUN_TOP:
				want_tile = R.BUN
			elif nxt == R.PATTY:
				want_slot = grill.first_in_state("ready")
				if want_slot == -1 and grill.count_state("raw") == 0:
					want_tile = R.PATTY
			else:
				want_tile = nxt
			# carne cozinha devagar: já sugere colocar na chapa no começo
			if want.has(R.PATTY) and built.size() <= 1 and grill.count_state("raw") + grill.count_state("ready") == 0:
				want_tile = R.PATTY
		else:
			var missing := false
			for s in selected.sides:
				if not built_sides.has(s):
					missing = true
					want_tile = s
					break
			deliver = not missing
	if tut == 0:
		want_tile = R.PATTY
	elif tut == 1:
		want_tile = R.BUN
	for it in tiles:
		tiles[it].hint = it == want_tile
	grill.hint_slot = want_slot
	btn_deliver.glow = deliver
	btn_trash.glow = trash


func _on_trash() -> void:
	if built.is_empty() and built_sides.is_empty():
		return
	built = []
	built_sides = []
	Sfx.play("trash")
	plate.shake()
	_refresh_build()


func _break_combo() -> void:
	if stats.get("combo", 0) >= 3:
		_show_banner("Combo perdido!", 1.2)
	stats["combo"] = 0


func _on_deliver() -> void:
	if built.is_empty():
		return
	if selected == null or not is_instance_valid(selected) or selected.mood != "wait":
		_auto_select()
		if selected == null:
			_nope("Nenhum cliente esperando!")
			return
	var c = selected
	var stars := R.grade(c.recipe["layers"], built, c.sides, built_sides)
	if stars == 3:
		stats["combo"] += 1
	else:
		_break_combo()
	var combo: int = stats["combo"]
	var pay := R.payout(c.value, stars, c.ratio(), maxi(combo - 1, 0), Game.owned, c.kind)
	var earned: int = pay["coins"] + pay["tip"]
	c.waiting = false
	c.mood = "happy" if stars >= 2 else "sad"
	c.selected = false
	stats["served"] += 1
	stats["stars"] += stars
	stats["coins"] += earned
	stats["tips"] += pay["tip"]
	stats["xp"] += R.xp_for_order(stars, c.kind)
	stats["best_combo"] = maxi(stats["best_combo"], combo)
	if stars == 3:
		stats["perfect"] += 1
	Game.add_coins(earned)
	Game.total_served += 1
	top_bar.bump_coins()

	var head: Vector2 = c.position + Vector2(c.size.x / 2, c.bubble_h + 40)
	_burst_stars(head, stars)
	if earned > 0:
		_float_text(head + Vector2(0, -170), "+%d" % earned, Color("ffd21f"))
		Sfx.play("coin", 1.0, -4.0)
	if pay["tip"] > 0:
		_float_text(head + Vector2(0, -115), "Gorjeta!", Color("69db7c"), 0.25)
	match stars:
		3:
			Sfx.play("perfect")
			var word: String = ["PERFEITO!", "DELÍCIA!", "UAU!", "SHOW!"].pick_random()
			if combo >= 2:
				word = "COMBO x%d!" % combo
				Sfx.play("combo", 1.0 + mini(combo, 10) * 0.06)
			_float_text(head + Vector2(0, -230), word, Color("ff922b"))
			if combo >= 3 or c.kind != "normal":
				_burst_confetti(head)
			Input.vibrate_handheld(35)
		2:
			Sfx.play("good")
			_float_text(head + Vector2(0, -230), "Bom!", Color("74c0fc"))
		1:
			Sfx.play("good", 0.85)
			_float_text(head + Vector2(0, -230), "Hmm... quase", Color("ffa8a8"))
		0:
			Sfx.play("bad")
			_float_text(head + Vector2(0, -230), "Eca! Errado!", Color("ff6b6b"))
			Input.vibrate_handheld(80)
	if c.kind == "critic" and stars < 3:
		_show_banner("O crítico não gostou... nada de moedas.", 2.0)

	built = []
	built_sides = []
	if tut < 99:
		tut = 99
		Game.tutorial_done = true
		Game.save_game()
		_show_banner("Isso! Agora é com você. Bata a META do dia!", 3.0)
	_leave(c, 0.9)
	selected = null
	_auto_select()
	_refresh_build()


func _on_customer_ran_out(c) -> void:
	stats["lost"] += 1
	_break_combo()
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
	var out_x: float = -c.size.x - 20 if rng.randf() < 0.5 else size.x + 20
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
		spawn_t = minf(spawn_t, 1.5)


# ------------------------------------------------------------------ tutorial
const TUT_TEXT := [
	"1. Toque em CARNE pra colocar na chapa",
	"2. Enquanto assa, toque em PÃO",
	"3. Carne PRONTA? Toque nela na chapa!",
	"4. Siga a comanda e feche com o PÃO",
	"5. Agora toque em ENTREGAR!",
]


func _tutorial_banner() -> void:
	if tut < TUT_TEXT.size():
		banner.text = TUT_TEXT[tut]
		banner.modulate.a = 1.0


# O passo do tutorial é deduzido do estado atual (funciona em qualquer ordem de toques).
func _tut_eval() -> void:
	if tut >= 99:
		return
	var step := 0
	var on_grill: bool = grill.count_state("raw") + grill.count_state("ready") > 0
	if not on_grill and not built.has(R.PATTY):
		step = 0
	elif built.is_empty():
		step = 1
	elif not built.has(R.PATTY):
		step = 2
	elif not _is_closed():
		step = 3
	else:
		step = 4
	if step != tut:
		if step > tut:
			Sfx.play("good", 1.2, -6.0)
		tut = step
		_tutorial_banner()


# ------------------------------------------------------------------ fim do dia
func _end_day() -> void:
	state = RESULTS
	grill.clear()
	Sfx.set_grill(false)
	var earned: int = stats["coins"]
	var day_stars := R.day_stars(earned, goal)
	var old_xp := Game.xp
	var bonus_xp := day_stars * 3
	Game.xp += stats["xp"] + bonus_xp
	Game.best_combo = maxi(Game.best_combo, stats["best_combo"])
	var finished_day := Game.day
	Game.day_best[finished_day] = maxi(int(Game.day_best.get(finished_day, 0)), day_stars)
	if day_stars >= 1:
		Game.day += 1
	Game.save_game()
	_show_results(finished_day, day_stars, old_xp, bonus_xp)


func _show_results(finished_day: int, day_stars: int, old_xp: int, bonus_xp: int) -> void:
	var v := results_panel.get_child(0) as VBoxContainer
	for c in v.get_children():
		c.queue_free()
	v.add_theme_constant_override("separation", 8)
	var titles := ["Meta não batida...", "Dia concluído!", "Muito bem!", "INCRÍVEL!"]
	v.add_child(_label("Fim do Dia %d" % finished_day, 26, Color("8a6a52")))
	v.add_child(_label(titles[day_stars], 46, Color("e8590c") if day_stars > 0 else Color("c92a2a")))
	var sv := StarsScript.new()
	sv.custom_minimum_size = Vector2(0, 120)
	v.add_child(sv)
	sv.reveal(day_stars)
	v.add_child(_label("Moedas do dia: %d   (meta %d)" % [stats["coins"], goal], 28, Color("e8590c")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	for l in ["Atendidos: %d" % stats["served"], "Perfeitos: %d" % stats["perfect"],
			"Melhor combo: x%d" % stats["best_combo"], "Foram embora: %d" % stats["lost"],
			"Gorjetas: %d" % stats["tips"], "Carnes queimadas: %d" % stats["burnt"]]:
		var lab := _label(l, 21)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(lab)
	v.add_child(grid)
	var xpb := XpBarScript.new()
	xpb.custom_minimum_size = Vector2(0, 64)
	v.add_child(xpb)
	var xp_line := _label("+%d XP%s" % [Game.xp - old_xp, ("  (bônus de estrelas +%d)" % bonus_xp) if bonus_xp > 0 else ""], 20, Color("1971c2"))
	v.add_child(xp_line)
	var lvl_box := VBoxContainer.new()
	v.add_child(lvl_box)
	xpb.leveled_up.connect(_on_level_up.bind(lvl_box))
	xpb.animate(old_xp, Game.xp, 1.2)
	if day_stars == 0:
		v.add_child(_label("Faltaram %d moedas. Dica: use a chapa antes do cliente chegar e faça combos!" % (goal - stats["coins"]), 20, Color("8a6a52")))
	var shop := _btn("LOJA / EXPANDIR", Color("ff8c42"), 26)
	shop.custom_minimum_size = Vector2(0, 72)
	shop.pressed.connect(_open_shop)
	v.add_child(shop)
	var nxt := _btn("PRÓXIMO DIA" if day_stars > 0 else "TENTAR DE NOVO", Color("37b24d"), 34)
	nxt.custom_minimum_size = Vector2(0, 88)
	nxt.pressed.connect(_start_day)
	v.add_child(nxt)
	var menu := _btn("MENU", Color("4dabf7"), 22)
	menu.pressed.connect(_show_menu)
	v.add_child(menu)
	Sfx.play("fanfare" if day_stars > 0 else "bad")
	if day_stars == 3:
		_burst_confetti(Vector2(size.x / 2, size.y * 0.3))
	_pop_panel(results_panel)


func _on_level_up(level: int, box: VBoxContainer) -> void:
	Sfx.play("levelup")
	_burst_confetti(Vector2(size.x / 2, size.y * 0.55))
	var l := _label("SUBIU PRO NÍVEL %d: %s!" % [level, R.title_for_level(level)], 28, Color("2b8a3e"))
	box.add_child(l)
	var un := R.unlocks_at_level(level)
	if un.size() > 0:
		box.add_child(_label("Liberado na loja: " + ", ".join(un), 20, Color("2b8a3e")))
	l.pivot_offset = Vector2(300, 20)
	l.scale = Vector2(0.5, 0.5)
	create_tween().tween_property(l, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ efeitos
func _show_banner(text: String, hold: float = 1.8) -> void:
	if tut < 99 and not text.begins_with("Isso"):
		return
	banner.text = text
	banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.15)
	tw.tween_interval(hold)
	tw.tween_property(banner, "modulate:a", 0.0, 0.35)


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
	var l := _label(text, 38, color, 12)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(l)
	l.size = Vector2(440, 60)
	l.position = Vector2(clampf(pos.x - 220, 0, size.x - 440), pos.y)
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
	p.amount = 40
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 1.3
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 250.0
	p.initial_velocity_max = 600.0
	p.gravity = Vector2(0, 900)
	p.scale_amount_min = 6.0
	p.scale_amount_max = 12.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	g.colors = PackedColorArray([Color("ff6b6b"), Color("ffd43b"), Color("69db7c"), Color("4dabf7"), Color("da77f2")])
	p.color_initial_ramp = g
	fx.add_child(p)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)
