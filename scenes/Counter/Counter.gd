extends Node3D

const BM = preload("res://scripts/BurgerModels.gd")

signal patty_cooked(patty_node: Node3D)
signal fries_ready()
signal soda_ready()
signal burger_served()

@onready var grill_marker: Marker3D = $GrillStation/PattySpawn
@onready var plate_marker: Marker3D = $AssemblyStation/PlateMarker
@onready var fries_marker: Marker3D = $FryerStation/FriesMarker
@onready var soda_marker: Marker3D = $SodaStation/SodaMarker
@onready var delivery_area: Node3D = $DeliveryStation

var grill_active: bool = false
var grill_timer: float = 0.0
var grill_target_time: float = 4.0
var current_patty: Node3D = null
var patty_is_cooked: bool = false

var fryer_active: bool = false
var fryer_timer: float = 0.0
var fryer_target_time: float = 3.5
var fries_prepared: bool = false

var soda_active: bool = false
var soda_timer: float = 0.0
var soda_target_time: float = 2.0
var soda_prepared: bool = false

func _ready() -> void:
	_apply_counter_style()
	_update_upgrade_speeds()

func _update_upgrade_speeds() -> void:
	if has_node("/root/SaveManager"):
		var grill_up = get_node("/root/SaveManager").get_upgrade_level("fast_grill")
		grill_target_time = max(1.8, 4.0 - grill_up * 0.7)
		var fryer_up = get_node("/root/SaveManager").get_upgrade_level("fast_fryer")
		fryer_target_time = max(1.5, 3.5 - fryer_up * 0.6)

func _apply_counter_style() -> void:
	if not has_node("/root/SaveManager"):
		return
	var style_lvl = get_node("/root/SaveManager").get_upgrade_level("counter_style")
	var counter_mesh: MeshInstance3D = $CounterTop
	if counter_mesh and counter_mesh.material_override:
		var mat: StandardMaterial3D = counter_mesh.material_override
		if style_lvl == 0:
			mat.albedo_color = Color(0.25, 0.23, 0.22)
		elif style_lvl == 1:
			mat.albedo_color = Color(0.65, 0.42, 0.28)
		else:
			mat.albedo_color = Color(0.85, 0.20, 0.22)

func _process(delta: float) -> void:
	_process_grill(delta)
	_process_fryer(delta)
	_process_soda(delta)

func start_cooking_patty() -> void:
	if current_patty != null or grill_active:
		return
	grill_active = true
	grill_timer = 0.0
	patty_is_cooked = false

	current_patty = BM.create_patty("raw")
	grill_marker.add_child(current_patty)
	current_patty.position = Vector3.ZERO

	current_patty.scale = Vector3(0.5, 0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(current_patty, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("sizzle")

func _process_grill(delta: float) -> void:
	if not grill_active:
		return
	grill_timer += delta
	if current_patty:
		current_patty.position.y = sin(grill_timer * 35.0) * 0.015

	if grill_timer >= (grill_target_time * 0.5) and not patty_is_cooked and grill_timer < grill_target_time:
		var mesh_inst = current_patty.get_node_or_null("Patty/MeshInstance3D")
		if mesh_inst:
			mesh_inst.material_override = BM.get_shared_material("patty_cooking", Color(0.55, 0.30, 0.20))

	if grill_timer >= grill_target_time and not patty_is_cooked:
		patty_is_cooked = true
		grill_active = false
		var mesh_inst = current_patty.get_node_or_null("Patty/MeshInstance3D")
		if mesh_inst:
			mesh_inst.material_override = BM.get_shared_material("patty_cooked", Color(0.38, 0.20, 0.12))
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("ingredient_drop")
		patty_cooked.emit(current_patty)

func take_patty_from_grill() -> Node3D:
	if current_patty and patty_is_cooked:
		var p = current_patty
		grill_marker.remove_child(p)
		current_patty = null
		patty_is_cooked = false
		return p
	return null

func start_fryer() -> void:
	if fryer_active or fries_prepared:
		return
	fryer_active = true
	fryer_timer = 0.0
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("fryer")

func _process_fryer(delta: float) -> void:
	if not fryer_active:
		return
	fryer_timer += delta
	if fryer_timer >= fryer_target_time:
		fryer_active = false
		fries_prepared = true
		_spawn_fryer_basket_visual()
		fries_ready.emit()
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("bell")

func _spawn_fryer_basket_visual() -> void:
	for child in fries_marker.get_children():
		child.queue_free()
	var fries_node = BM.create_french_fries()
	fries_marker.add_child(fries_node)
	fries_node.position = Vector3(0, -0.3, 0)
	var tw = create_tween()
	tw.tween_property(fries_node, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func take_fries() -> bool:
	if fries_prepared:
		fries_prepared = false
		for child in fries_marker.get_children():
			child.queue_free()
		return true
	return false

func start_soda() -> void:
	if soda_active or soda_prepared:
		return
	soda_active = true
	soda_timer = 0.0
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("pour")

func _process_soda(delta: float) -> void:
	if not soda_active:
		return
	soda_timer += delta
	if soda_timer >= soda_target_time:
		soda_active = false
		soda_prepared = true
		_spawn_soda_visual()
		soda_ready.emit()
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("bell")

func _spawn_soda_visual() -> void:
	for child in soda_marker.get_children():
		child.queue_free()
	var soda_node = BM.create_soda_cup()
	soda_marker.add_child(soda_node)
	soda_node.scale = Vector3(0.2, 0.2, 0.2)
	var tw = create_tween()
	tw.tween_property(soda_node, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func take_soda() -> bool:
	if soda_prepared:
		soda_prepared = false
		for child in soda_marker.get_children():
			child.queue_free()
		return true
	return false
