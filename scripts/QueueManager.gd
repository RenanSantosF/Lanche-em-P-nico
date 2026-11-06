extends Node3D

signal queue_updated(active_customers: Array)
signal order_resolved(was_successful: bool, reward: int, customer: Node3D)
signal customer_walked_out()

const CustomerScene = preload("res://scenes/Customer/Customer.tscn")

@export var max_queue_size: int = 4
@export var slot_spacing: float = 1.3
@export var queue_origin: Vector3 = Vector3(0.0, 0.0, -1.8)

var queue: Array[Node3D] = []
var spawn_timer: float = 0.0
var spawn_interval: float = 8.0
var is_spawning_active: bool = false
var current_level: int = 1

func _process(delta: float) -> void:
	if not is_spawning_active:
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		if queue.size() < max_queue_size:
			spawn_customer()

func start_queue(level: int, initial_interval: float = 7.0) -> void:
	current_level = level
	spawn_interval = initial_interval
	is_spawning_active = true
	spawn_timer = spawn_interval * 0.7

	for c in queue:
		if is_instance_valid(c):
			c.queue_free()
	queue.clear()

	spawn_customer()

func stop_queue() -> void:
	is_spawning_active = false

func spawn_customer() -> Node3D:
	if queue.size() >= max_queue_size:
		return null

	var customer = CustomerScene.instantiate()
	add_child(customer)

	var is_vip = (randf() < 0.2 and current_level >= 3)
	var recipes_mgr = get_node("/root/Recipes") if has_node("/root/Recipes") else null
	var available_recipes = recipes_mgr.get_unlocked_recipes(current_level) if recipes_mgr else []
	var chosen_recipe = available_recipes.pick_random() if not available_recipes.is_empty() else {}

	customer.setup_customer(chosen_recipe, is_vip)

	var slot_index = queue.size()
	var target_pos = queue_origin + Vector3(slot_index * slot_spacing, 0, 0)
	customer.position = target_pos + Vector3(3.0, 0, 0)

	var tw = customer.create_tween()
	tw.tween_property(customer, "position", target_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	customer.patience_depleted.connect(_on_customer_patience_depleted.bind(customer))

	queue.append(customer)
	queue_updated.emit(queue)
	return customer

func _realign_queue() -> void:
	for i in range(queue.size()):
		var c = queue[i]
		if is_instance_valid(c):
			var target_pos = queue_origin + Vector3(i * slot_spacing, 0, 0)
			var tw = c.create_tween()
			tw.tween_property(c, "position", target_pos, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_updated.emit(queue)

func get_front_customer() -> Node3D:
	if queue.is_empty():
		return null
	return queue[0]

func deliver_order_to_front(assembled_layers: Array, has_fries: bool, has_soda: bool) -> Dictionary:
	var front = get_front_customer()
	if front == null:
		return { "success": false, "message": "Nenhum cliente na fila!" }

	var recipe = front.order_data
	var recipes_mgr = get_node("/root/Recipes") if has_node("/root/Recipes") else null
	var validation = recipes_mgr.validate_order(recipe, assembled_layers, has_fries, has_soda) if recipes_mgr else { "is_acceptable": true }

	if validation["is_acceptable"]:
		var base_reward: int = recipe.get("base_reward", 50)
		var patience_bonus: int = int((front.current_patience / front.max_patience) * 20.0)
		var vip_bonus: int = 50 if front.is_vip else 0
		var total_reward: int = base_reward + patience_bonus + vip_bonus

		front.receive_order(true)
		queue.erase(front)
		_realign_queue()
		order_resolved.emit(true, total_reward, front)
		return { "success": true, "reward": total_reward, "message": "Pedido Entregue!" }
	else:
		front.receive_order(false)
		order_resolved.emit(false, 0, front)
		return { "success": false, "message": validation.get("message", "Incorreto!") }

func _on_customer_patience_depleted(customer: Node3D) -> void:
	if queue.has(customer):
		queue.erase(customer)
		_realign_queue()
	customer_walked_out.emit()
