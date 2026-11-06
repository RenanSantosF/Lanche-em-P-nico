extends Control

signal ingredient_button_pressed(type: int)
signal grill_action_pressed()
signal fryer_action_pressed()
signal soda_action_pressed()
signal deliver_button_pressed()
signal clear_button_pressed()
signal next_level_pressed()
signal retry_level_pressed()
signal store_pressed()
signal watch_rewarded_ad_pressed()

@onready var coins_label: Label = $TopBar/MarginContainer/HBoxContainer/CoinsBox/CoinsLabel
@onready var timer_label: Label = $TopBar/MarginContainer/HBoxContainer/TimerBox/TimerLabel
@onready var score_label: Label = $TopBar/MarginContainer/HBoxContainer/ScoreBox/ScoreLabel
@onready var order_cards_container: HBoxContainer = $OrderArea/ScrollContainer/CardsContainer
@onready var message_popup: Label = $FeedbackBanner
@onready var results_modal: Panel = $ResultsModal
@onready var results_title: Label = $ResultsModal/VBoxContainer/TitleLabel
@onready var results_desc: Label = $ResultsModal/VBoxContainer/DescLabel
@onready var results_stars: Label = $ResultsModal/VBoxContainer/StarsLabel

var current_order_card_nodes: Array[Control] = []

func _ready() -> void:
	message_popup.modulate.a = 0.0
	results_modal.visible = false

	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").coins_changed.connect(update_coins)
		update_coins(get_node("/root/SaveManager").get_coins())

	_connect_ingredient_buttons()

func update_coins(amount: int) -> void:
	if coins_label:
		coins_label.text = "🪙 " + str(amount)

func update_timer(seconds_left: float) -> void:
	if timer_label:
		var mins = int(seconds_left) / 60
		var secs = int(seconds_left) % 60
		timer_label.text = "⏱️ %02d:%02d" % [mins, secs]

func update_score(score: int) -> void:
	if score_label:
		score_label.text = "⭐ " + str(score)

func show_feedback(text: String, is_success: bool = true) -> void:
	if not message_popup:
		return
	message_popup.text = text
	message_popup.modulate = Color(0.2, 1.0, 0.4) if is_success else Color(1.0, 0.2, 0.2)
	message_popup.modulate.a = 1.0

	var tw = create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(message_popup, "modulate:a", 0.0, 0.3)

func render_order_cards(queue: Array) -> void:
	for c in order_cards_container.get_children():
		c.queue_free()
	current_order_card_nodes.clear()

	for i in range(queue.size()):
		var cust = queue[i]
		if not is_instance_valid(cust):
			continue
		var order = cust.order_data
		if order.is_empty():
			continue

		var card = _create_card(cust, order, i == 0)
		order_cards_container.add_child(card)
		current_order_card_nodes.append(card)

func _create_card(customer: Node3D, order: Dictionary, is_front: bool) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(170, 150) if is_front else Vector2(120, 110)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = ("👑 VIP: " if customer.is_vip else "🍔 ") + order.get("name", "Lanche")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16 if is_front else 12)
	vbox.add_child(name_lbl)

	var ingredients_flow = HFlowContainer.new()
	vbox.add_child(ingredients_flow)

	var ing_list: Array = order.get("ingredients", [])
	for ing in ing_list:
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16) if is_front else Vector2(10, 10)
		if has_node("/root/Recipes"):
			dot.color = get_node("/root/Recipes").get_ingredient_color(ing)
		ingredients_flow.add_child(dot)

	var sides_box = HBoxContainer.new()
	vbox.add_child(sides_box)
	if order.get("has_fries", false):
		var f_lbl = Label.new()
		f_lbl.text = "🍟"
		f_lbl.add_theme_font_size_override("font_size", 14)
		sides_box.add_child(f_lbl)
	if order.get("has_soda", false):
		var s_lbl = Label.new()
		s_lbl.text = "🥤"
		s_lbl.add_theme_font_size_override("font_size", 14)
		sides_box.add_child(s_lbl)

	if is_front:
		panel.self_modulate = Color(1.0, 0.9, 0.6)

	return panel

func show_level_results(won: bool, stars: int, score: int, coins: int) -> void:
	results_modal.visible = true
	if won:
		results_title.text = "FASE CONCLUÍDA!"
		results_title.modulate = Color(0.2, 1.0, 0.3)
		results_stars.text = "⭐".repeat(stars) + "☆".repeat(3 - stars)
		results_desc.text = "Pontuação: %d\nMoedas ganhas: +%d" % [score, coins]
	else:
		results_title.text = "LANCHONETE FECHADA!"
		results_title.modulate = Color(1.0, 0.25, 0.25)
		results_stars.text = "💀"
		results_desc.text = "Muitos clientes ficaram bravos ou o tempo acabou!\nTente novamente."

func _connect_ingredient_buttons() -> void:
	$IngredientDock/Grid/BunBottomBtn.pressed.connect(func(): ingredient_button_pressed.emit(0))
	$IngredientDock/Grid/CheeseBtn.pressed.connect(func(): ingredient_button_pressed.emit(2))
	$IngredientDock/Grid/LettuceBtn.pressed.connect(func(): ingredient_button_pressed.emit(3))
	$IngredientDock/Grid/TomatoBtn.pressed.connect(func(): ingredient_button_pressed.emit(4))
	$IngredientDock/Grid/SauceBtn.pressed.connect(func(): ingredient_button_pressed.emit(5))
	$IngredientDock/Grid/BunTopBtn.pressed.connect(func(): ingredient_button_pressed.emit(6))

	$EquipmentBar/GrillBtn.pressed.connect(func(): grill_action_pressed.emit())
	$EquipmentBar/FryerBtn.pressed.connect(func(): fryer_action_pressed.emit())
	$EquipmentBar/SodaBtn.pressed.connect(func(): soda_action_pressed.emit())

	$ControlBar/DeliverBtn.pressed.connect(func(): deliver_button_pressed.emit())
	$ControlBar/TrashBtn.pressed.connect(func(): clear_button_pressed.emit())
	$TopBar/MarginContainer/HBoxContainer/StoreBtn.pressed.connect(func(): store_pressed.emit())

	$ResultsModal/VBoxContainer/NextBtn.pressed.connect(func(): next_level_pressed.emit())
	$ResultsModal/VBoxContainer/RetryBtn.pressed.connect(func(): retry_level_pressed.emit())
	$ResultsModal/VBoxContainer/DoubleCoinsBtn.pressed.connect(func(): watch_rewarded_ad_pressed.emit())
