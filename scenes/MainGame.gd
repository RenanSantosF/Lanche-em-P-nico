extends Node3D

const LM = preload("res://scripts/LevelManager.gd")

# MainGame.gd - Core game controller coordinating Counter, QueueManager,
# BurgerAssembly, GameUI, level timer, scoring, audio and AdMob triggers.

@onready var counter: Node3D = $World/Counter
@onready var queue_manager: Node3D = $World/QueueManager
@onready var assembly: Node3D = $World/Counter/AssemblyStation/BurgerAssembly
@onready var game_ui: Control = $UIOverlay/GameUI
@onready var upgrade_store: Control = $UIOverlay/UpgradeStore
@onready var camera: Camera3D = $Camera3D

var current_level_num: int = 1
var level_time_left: float = 120.0
var current_score: int = 0
var customers_served: int = 0
var customers_lost: int = 0
var is_stage_running: bool = false

func _ready() -> void:
	if has_node("/root/SaveManager"):
		current_level_num = get_node("/root/SaveManager").player_data.get("unlocked_level", 1)

	upgrade_store.visible = false

	_connect_signals()
	start_level(current_level_num)

func _connect_signals() -> void:
	# UI Actions
	game_ui.ingredient_button_pressed.connect(_on_ingredient_pressed)
	game_ui.grill_action_pressed.connect(_on_grill_action_pressed)
	game_ui.fryer_action_pressed.connect(_on_fryer_action_pressed)
	game_ui.soda_action_pressed.connect(_on_soda_action_pressed)
	game_ui.deliver_button_pressed.connect(_on_deliver_pressed)
	game_ui.clear_button_pressed.connect(_on_clear_pressed)
	game_ui.store_pressed.connect(_on_open_store)
	game_ui.next_level_pressed.connect(_on_next_level)
	game_ui.retry_level_pressed.connect(_on_retry_level)
	game_ui.watch_rewarded_ad_pressed.connect(_on_watch_ad)

	upgrade_store.store_closed.connect(_on_close_store)

	# Queue Signals
	queue_manager.queue_updated.connect(_on_queue_updated)
	queue_manager.order_resolved.connect(_on_order_resolved)
	queue_manager.customer_walked_out.connect(_on_customer_walked_out)

	# Counter & Assembly
	counter.patty_cooked.connect(_on_patty_cooked)

func start_level(level_num: int) -> void:
	current_level_num = level_num
	var cfg = LM.get_stage_config(level_num)

	level_time_left = cfg["duration"]
	current_score = 0
	customers_served = 0
	customers_lost = 0
	is_stage_running = true

	game_ui.update_score(current_score)
	game_ui.update_timer(level_time_left)
	game_ui.results_modal.visible = false

	assembly.clear_assembly()

	if has_node("/root/AdManager"):
		get_node("/root/AdManager").set_gameplay_active(true)

	queue_manager.start_queue(level_num, cfg["spawn_interval"])

func _process(delta: float) -> void:
	if not is_stage_running:
		return

	level_time_left = max(0.0, level_time_left - delta)
	game_ui.update_timer(level_time_left)

	if level_time_left <= 0.0:
		_end_level()

func _on_ingredient_pressed(type: int) -> void:
	if not is_stage_running:
		return
	assembly.add_ingredient(type)

func _on_grill_action_pressed() -> void:
	if not is_stage_running:
		return
	if counter.patty_is_cooked:
		var p = counter.take_patty_from_grill()
		if p:
			p.queue_free()
			assembly.add_ingredient(Recipes.IngredientType.PATTY)
	elif not counter.grill_active:
		counter.start_cooking_patty()

func _on_fryer_action_pressed() -> void:
	if not is_stage_running:
		return
	if counter.fries_prepared:
		if counter.take_fries():
			assembly.add_side_fries()
	elif not counter.fryer_active:
		counter.start_fryer()

func _on_soda_action_pressed() -> void:
	if not is_stage_running:
		return
	if counter.soda_prepared:
		if counter.take_soda():
			assembly.add_side_soda()
	elif not counter.soda_active:
		counter.start_soda()

func _on_patty_cooked(_patty_node: Node3D) -> void:
	game_ui.show_feedback("Carne pronta na chapa!", true)

func _on_clear_pressed() -> void:
	assembly.clear_assembly()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("error")
	game_ui.show_feedback("Bancada limpa!", false)

func _on_deliver_pressed() -> void:
	if not is_stage_running:
		return
	var layers = assembly.get_current_layers()
	if layers.is_empty():
		game_ui.show_feedback("Monte o lanche primeiro!", false)
		return

	var delivery_target = counter.delivery_area.global_position
	assembly.deliver_burger(delivery_target, func():
		var result = queue_manager.deliver_order_to_front(layers, assembly.has_side_fries, assembly.has_side_soda)
		game_ui.show_feedback(result["message"], result["success"])
	)

func _on_queue_updated(active_queue: Array) -> void:
	game_ui.render_order_cards(active_queue)

func _on_order_resolved(success: bool, reward: int, _customer: Node3D) -> void:
	if success:
		customers_served += 1
		current_score += reward
		game_ui.update_score(current_score)
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").add_coins(int(reward * 0.5))
	else:
		current_score = max(0, current_score - 15)
		game_ui.update_score(current_score)

func _on_customer_walked_out() -> void:
	customers_lost += 1
	current_score = max(0, current_score - 25)
	game_ui.update_score(current_score)
	game_ui.show_feedback("Cliente perdeu a paciência e foi embora!", false)

func _end_level() -> void:
	is_stage_running = false
	queue_manager.stop_queue()

	if has_node("/root/AdManager"):
		get_node("/root/AdManager").set_gameplay_active(false)

	var cfg = LM.get_stage_config(current_level_num)
	var won = (current_score >= cfg["target_score"] and customers_served >= cfg["target_customers"])
	var stars = LM.calculate_stars(current_level_num, current_score) if won else 0
	var earned_coins = cfg["coin_reward"] if won else 10

	if won and has_node("/root/SaveManager"):
		get_node("/root/SaveManager").record_level_result(current_level_num, stars, current_score)
		get_node("/root/SaveManager").add_coins(earned_coins)

	game_ui.show_level_results(won, stars, current_score, earned_coins)

	# Show safe interstitial ad between levels (respects 3-minute cooldown)
	if has_node("/root/AdManager"):
		get_node("/root/AdManager").show_interstitial()

func _on_next_level() -> void:
	start_level(current_level_num + 1)

func _on_retry_level() -> void:
	start_level(current_level_num)

func _on_open_store() -> void:
	upgrade_store.visible = true

func _on_close_store() -> void:
	upgrade_store.visible = false
	counter._apply_counter_style()
	counter._update_upgrade_speeds()

func _on_watch_ad() -> void:
	if has_node("/root/AdManager"):
		get_node("/root/AdManager").show_rewarded_ad("coins", 100)
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").add_coins(100)
		game_ui.show_feedback("Vídeo assistido! +100 Moedas!", true)
