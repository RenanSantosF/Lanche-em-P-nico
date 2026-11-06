extends Node3D

const BM = preload("res://scripts/BurgerModels.gd")

signal ingredient_added(type: int, total_count: int)
signal assembly_cleared()
signal burger_completed(ingredients: Array, has_fries: bool, has_soda: bool)

@export var plate_path: NodePath
var plate_node: Node3D

var current_stack: Array[int] = []
var stacked_nodes: Array[Node3D] = []
var current_height: float = 0.0

var has_side_fries: bool = false
var has_side_soda: bool = false
var side_nodes: Array[Node3D] = []

func _ready() -> void:
	if not plate_path.is_empty():
		plate_node = get_node(plate_path)
	else:
		plate_node = self

func get_current_layers() -> Array:
	return current_stack.duplicate()

func can_add_ingredient(type: int) -> bool:
	if current_stack.is_empty() and type != Recipes.IngredientType.BUN_BOTTOM:
		return false
	if current_stack.size() > 0 and current_stack.back() == Recipes.IngredientType.BUN_TOP:
		return false
	return true

func add_ingredient(type: int) -> bool:
	if not can_add_ingredient(type):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("error")
		return false

	var node = BM.create_ingredient_node(type)
	if node == null:
		return false

	current_stack.append(type)
	stacked_nodes.append(node)
	plate_node.add_child(node)

	var target_y = current_height
	node.position = Vector3(0, target_y + 0.6, 0)
	node.rotation.y = randf_range(-0.1, 0.1)

	var tween = create_tween()
	tween.tween_property(node, "position:y", target_y, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	node.scale = Vector3(1.15, 0.8, 1.15)
	tween.parallel().tween_property(node, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var item_height: float = Recipes.INGREDIENT_DATA[type]["height"]
	current_height += item_height

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ingredient_drop")
	ingredient_added.emit(type, current_stack.size())
	return true

func add_side_fries() -> bool:
	if has_side_fries:
		return false
	has_side_fries = true
	var fries = BM.create_french_fries()
	plate_node.add_child(fries)
	fries.position = Vector3(-0.7, 0, 0)
	fries.scale = Vector3(0.1, 0.1, 0.1)
	var tw = create_tween()
	tw.tween_property(fries, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	side_nodes.append(fries)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ingredient_drop")
	return true

func add_side_soda() -> bool:
	if has_side_soda:
		return false
	has_side_soda = true
	var soda = BM.create_soda_cup()
	plate_node.add_child(soda)
	soda.position = Vector3(0.7, 0, 0)
	soda.scale = Vector3(0.1, 0.1, 0.1)
	var tw = create_tween()
	tw.tween_property(soda, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	side_nodes.append(soda)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ingredient_drop")
	return true

func clear_assembly() -> void:
	for node in stacked_nodes:
		if is_instance_valid(node):
			node.queue_free()
	for side in side_nodes:
		if is_instance_valid(side):
			side.queue_free()

	stacked_nodes.clear()
	side_nodes.clear()
	current_stack.clear()
	current_height = 0.0
	has_side_fries = false
	has_side_soda = false
	assembly_cleared.emit()

func deliver_burger(target_delivery_pos: Vector3, on_complete: Callable = Callable()) -> void:
	if current_stack.is_empty():
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("error")
		return

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("bell")

	var tw = create_tween()
	var orig_pos = plate_node.position
	tw.tween_property(plate_node, "position", target_delivery_pos, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		burger_completed.emit(current_stack.duplicate(), has_side_fries, has_side_soda)
		if on_complete.is_valid():
			on_complete.call()
		clear_assembly()
		plate_node.position = orig_pos
	)
