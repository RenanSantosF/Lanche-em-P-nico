class_name BurgerModels
extends RefCounted

# BurgerModels.gd - Low-poly 3D meshes for mobile performance.

static var _materials_cache: Dictionary = {}

static func get_shared_material(key: String, color: Color, roughness: float = 0.6) -> StandardMaterial3D:
	if _materials_cache.has(key):
		return _materials_cache[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.05
	mat.specular_mode = StandardMaterial3D.SPECULAR_SCHLICK_GGX
	_materials_cache[key] = mat
	return mat

static func create_bun_bottom() -> Node3D:
	var root = Node3D.new()
	root.name = "BunBottom"
	var mesh_inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.52
	cyl.bottom_radius = 0.48
	cyl.height = 0.14
	cyl.radial_segments = 14
	mesh_inst.mesh = cyl
	mesh_inst.material_override = get_shared_material("bun_bread", Color(0.86, 0.58, 0.28))
	mesh_inst.position.y = 0.07
	root.add_child(mesh_inst)
	return root

static func create_patty(state: String = "cooked") -> Node3D:
	var root = Node3D.new()
	root.name = "Patty"
	var mesh_inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.50
	cyl.bottom_radius = 0.50
	cyl.height = 0.12
	cyl.radial_segments = 14
	mesh_inst.mesh = cyl

	var mat: StandardMaterial3D
	match state:
		"raw":
			mat = get_shared_material("patty_raw", Color(0.78, 0.25, 0.25), 0.5)
		"cooking":
			mat = get_shared_material("patty_cooking", Color(0.55, 0.30, 0.20), 0.7)
		"burnt":
			mat = get_shared_material("patty_burnt", Color(0.18, 0.12, 0.10), 0.9)
		_:
			mat = get_shared_material("patty_cooked", Color(0.38, 0.20, 0.12), 0.75)

	mesh_inst.material_override = mat
	mesh_inst.position.y = 0.06
	root.add_child(mesh_inst)
	return root

static func create_cheese() -> Node3D:
	var root = Node3D.new()
	root.name = "Cheese"
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 0.04, 1.0)
	mesh_inst.mesh = box
	mesh_inst.rotation_degrees.y = 22.5
	mesh_inst.material_override = get_shared_material("cheese", Color(1.0, 0.76, 0.12), 0.4)
	mesh_inst.position.y = 0.02
	root.add_child(mesh_inst)
	return root

static func create_lettuce() -> Node3D:
	var root = Node3D.new()
	root.name = "Lettuce"
	var mesh_inst = MeshInstance3D.new()
	var prism = CylinderMesh.new()
	prism.top_radius = 0.56
	prism.bottom_radius = 0.53
	prism.height = 0.05
	prism.radial_segments = 8
	mesh_inst.mesh = prism
	mesh_inst.material_override = get_shared_material("lettuce", Color(0.32, 0.78, 0.22), 0.5)
	mesh_inst.position.y = 0.025
	root.add_child(mesh_inst)
	return root

static func create_tomato() -> Node3D:
	var root = Node3D.new()
	root.name = "Tomato"
	for i in range(2):
		var slice = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.22
		cyl.bottom_radius = 0.22
		cyl.height = 0.06
		cyl.radial_segments = 10
		slice.mesh = cyl
		slice.material_override = get_shared_material("tomato", Color(0.92, 0.20, 0.15), 0.3)
		slice.position = Vector3(0.18 if i == 0 else -0.18, 0.03, 0.0)
		root.add_child(slice)
	return root

static func create_sauce() -> Node3D:
	var root = Node3D.new()
	root.name = "Sauce"
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.06
	sphere.radial_segments = 10
	sphere.rings = 4
	mesh_inst.mesh = sphere
	mesh_inst.material_override = get_shared_material("sauce", Color(0.95, 0.45, 0.12), 0.3)
	mesh_inst.position.y = 0.03
	root.add_child(mesh_inst)
	return root

static func create_bun_top() -> Node3D:
	var root = Node3D.new()
	root.name = "BunTop"
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.52
	sphere.height = 0.38
	sphere.radial_segments = 14
	sphere.rings = 6
	mesh_inst.mesh = sphere
	mesh_inst.material_override = get_shared_material("bun_bread", Color(0.86, 0.58, 0.28))
	mesh_inst.position.y = 0.19
	root.add_child(mesh_inst)

	for i in range(5):
		var seed_inst = MeshInstance3D.new()
		var seed_box = BoxMesh.new()
		seed_box.size = Vector3(0.04, 0.02, 0.02)
		seed_inst.mesh = seed_box
		seed_inst.material_override = get_shared_material("sesame", Color(0.95, 0.92, 0.82))
		var angle = i * (TAU / 5.0)
		seed_inst.position = Vector3(cos(angle) * 0.25, 0.37, sin(angle) * 0.25)
		seed_inst.rotation.y = angle
		root.add_child(seed_inst)

	return root

static func create_french_fries() -> Node3D:
	var root = Node3D.new()
	root.name = "FrenchFries"
	var box_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.45, 0.55, 0.28)
	box_inst.mesh = box_mesh
	box_inst.material_override = get_shared_material("fries_box", Color(0.88, 0.18, 0.18))
	box_inst.position.y = 0.27
	root.add_child(box_inst)

	for i in range(6):
		var stick = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = Vector3(0.06, 0.35, 0.06)
		stick.mesh = sm
		stick.material_override = get_shared_material("fry_stick", Color(0.96, 0.82, 0.22))
		var offset_x = (i - 2.5) * 0.06
		stick.position = Vector3(offset_x, 0.55 + randf_range(-0.04, 0.04), randf_range(-0.04, 0.04))
		stick.rotation_degrees.z = randf_range(-12.0, 12.0)
		root.add_child(stick)

	return root

static func create_soda_cup() -> Node3D:
	var root = Node3D.new()
	root.name = "SodaCup"
	var cup_inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.18
	cyl.height = 0.65
	cyl.radial_segments = 12
	cup_inst.mesh = cyl
	cup_inst.material_override = get_shared_material("soda_cup", Color(0.20, 0.55, 0.90))
	cup_inst.position.y = 0.32
	root.add_child(cup_inst)

	var lid_inst = MeshInstance3D.new()
	var lid_mesh = CylinderMesh.new()
	lid_mesh.top_radius = 0.27
	lid_mesh.bottom_radius = 0.27
	lid_mesh.height = 0.06
	lid_mesh.radial_segments = 12
	lid_inst.mesh = lid_mesh
	lid_inst.material_override = get_shared_material("soda_lid", Color(0.95, 0.95, 0.95))
	lid_inst.position.y = 0.65
	root.add_child(lid_inst)

	var straw_inst = MeshInstance3D.new()
	var straw_mesh = CylinderMesh.new()
	straw_mesh.top_radius = 0.02
	straw_mesh.bottom_radius = 0.02
	straw_mesh.height = 0.35
	straw_mesh.radial_segments = 6
	straw_inst.mesh = straw_mesh
	straw_inst.material_override = get_shared_material("soda_straw", Color(0.95, 0.2, 0.2))
	straw_inst.position = Vector3(0.06, 0.78, 0.0)
	straw_inst.rotation_degrees.z = -15.0
	root.add_child(straw_inst)
	return root

static func create_ingredient_node(type: int) -> Node3D:
	match type:
		Recipes.IngredientType.BUN_BOTTOM:
			return create_bun_bottom()
		Recipes.IngredientType.PATTY:
			return create_patty("cooked")
		Recipes.IngredientType.CHEESE:
			return create_cheese()
		Recipes.IngredientType.LETTUCE:
			return create_lettuce()
		Recipes.IngredientType.TOMATO:
			return create_tomato()
		Recipes.IngredientType.SAUCE:
			return create_sauce()
		Recipes.IngredientType.BUN_TOP:
			return create_bun_top()
		Recipes.IngredientType.FRIES:
			return create_french_fries()
		Recipes.IngredientType.SODA:
			return create_soda_cup()
		_:
			return Node3D.new()
