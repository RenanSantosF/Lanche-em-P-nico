extends Control

# UpgradeStore.gd - Shop UI allowing players to purchase permanent upgrades

signal store_closed()

@onready var coins_label: Label = $Panel/VBoxContainer/CoinsLabel

const UPGRADES_INFO = [
	{
		"id": "fast_grill",
		"name": "🔥 Chapa Turbo",
		"desc": "Cozinha as carnes de hambúrguer mais rápido",
		"max_level": 3,
		"costs": [100, 250, 500]
	},
	{
		"id": "fast_fryer",
		"name": "🍟 Fritadeira Veloz",
		"desc": "Frita batatas com tempo reduzido",
		"max_level": 3,
		"costs": [80, 200, 450]
	},
	{
		"id": "patience_boost",
		"name": "☕ Café de Boas-Vindas",
		"desc": "Aumenta a paciência dos clientes em fila",
		"max_level": 3,
		"costs": [120, 300, 600]
	},
	{
		"id": "counter_style",
		"name": "🎨 Estilo da Bancada",
		"desc": "Muda a cor e acabamento da sua bancada de preparo",
		"max_level": 2,
		"costs": [150, 400]
	}
]

func _ready() -> void:
	$Panel/VBoxContainer/CloseBtn.pressed.connect(_on_close_pressed)
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").coins_changed.connect(_update_coins_display)
		_update_coins_display(get_node("/root/SaveManager").get_coins())
	_build_upgrade_items()

func _update_coins_display(amount: int) -> void:
	if coins_label:
		coins_label.text = "Moedas Disponíveis: 🪙 " + str(amount)

func _build_upgrade_items() -> void:
	var container = $Panel/VBoxContainer/ScrollContainer/ItemsList
	for child in container.get_children():
		child.queue_free()

	var sm = get_node("/root/SaveManager") if has_node("/root/SaveManager") else null

	for upg in UPGRADES_INFO:
		var current_lvl = sm.get_upgrade_level(upg["id"]) if sm else 0
		var item_panel = PanelContainer.new()
		item_panel.custom_minimum_size = Vector2(0, 90)

		var hbox = HBoxContainer.new()
		item_panel.add_child(hbox)

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)

		var title = Label.new()
		title.text = "%s (Nível %d/%d)" % [upg["name"], current_lvl, upg["max_level"]]
		title.add_theme_font_size_override("font_size", 18)
		vbox.add_child(title)

		var desc = Label.new()
		desc.text = upg["desc"]
		desc.add_theme_font_size_override("font_size", 13)
		desc.modulate = Color(0.8, 0.8, 0.8)
		vbox.add_child(desc)

		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(130, 48)
		if current_lvl >= upg["max_level"]:
			buy_btn.text = "MÁXIMO"
			buy_btn.disabled = true
		else:
			var cost: int = upg["costs"][current_lvl]
			buy_btn.text = "🪙 " + str(cost)
			buy_btn.pressed.connect(_buy_upgrade.bind(upg["id"], cost))
		hbox.add_child(buy_btn)

		container.add_child(item_panel)

func _buy_upgrade(id: String, cost: int) -> void:
	var sm = get_node("/root/SaveManager") if has_node("/root/SaveManager") else null
	if sm and sm.spend_coins(cost):
		var current = sm.get_upgrade_level(id)
		sm.set_upgrade_level(id, current + 1)
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		_build_upgrade_items()
	else:
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("error")

func _on_close_pressed() -> void:
	visible = false
	store_closed.emit()
