extends Node

# Recipes.gd - Central catalog of ingredients, burger recipes and combo orders

enum IngredientType {
	BUN_BOTTOM,
	PATTY,
	CHEESE,
	LETTUCE,
	TOMATO,
	SAUCE,
	BUN_TOP,
	FRIES,
	SODA
}

const INGREDIENT_DATA = {
	IngredientType.BUN_BOTTOM: {
		"id": "bun_bottom",
		"name": "Pão Inferior",
		"icon_color": Color(0.85, 0.58, 0.28),
		"height": 0.12,
		"cost": 5
	},
	IngredientType.PATTY: {
		"id": "patty",
		"name": "Carne Grelhada",
		"icon_color": Color(0.42, 0.22, 0.12),
		"height": 0.14,
		"cost": 15,
		"needs_cooking": true
	},
	IngredientType.CHEESE: {
		"id": "cheese",
		"name": "Queijo Cheddar",
		"icon_color": Color(0.98, 0.76, 0.15),
		"height": 0.05,
		"cost": 8
	},
	IngredientType.LETTUCE: {
		"id": "lettuce",
		"name": "Alface Fresca",
		"icon_color": Color(0.35, 0.78, 0.25),
		"height": 0.07,
		"cost": 6
	},
	IngredientType.TOMATO: {
		"id": "tomato",
		"name": "Tomate",
		"icon_color": Color(0.92, 0.22, 0.18),
		"height": 0.08,
		"cost": 6
	},
	IngredientType.SAUCE: {
		"id": "sauce",
		"name": "Molho Especial",
		"icon_color": Color(0.95, 0.40, 0.15),
		"height": 0.04,
		"cost": 5
	},
	IngredientType.BUN_TOP: {
		"id": "bun_top",
		"name": "Pão Superior",
		"icon_color": Color(0.82, 0.54, 0.24),
		"height": 0.22,
		"cost": 5
	},
	IngredientType.FRIES: {
		"id": "fries",
		"name": "Batata Frita",
		"icon_color": Color(0.95, 0.85, 0.25),
		"height": 0.35,
		"cost": 12,
		"is_side": true
	},
	IngredientType.SODA: {
		"id": "soda",
		"name": "Refrigerante",
		"icon_color": Color(0.85, 0.25, 0.25),
		"height": 0.45,
		"cost": 10,
		"is_side": true
	}
}

const RECIPES = [
	{
		"id": "classic_burger",
		"name": "Clássico",
		"ingredients": [
			IngredientType.BUN_BOTTOM,
			IngredientType.PATTY,
			IngredientType.CHEESE,
			IngredientType.LETTUCE,
			IngredientType.BUN_TOP
		],
		"has_fries": false,
		"has_soda": false,
		"base_reward": 45,
		"unlocked_at_level": 1
	},
	{
		"id": "cheeseburger",
		"name": "Cheeseburger Duplo",
		"ingredients": [
			IngredientType.BUN_BOTTOM,
			IngredientType.PATTY,
			IngredientType.CHEESE,
			IngredientType.PATTY,
			IngredientType.CHEESE,
			IngredientType.BUN_TOP
		],
		"has_fries": false,
		"has_soda": false,
		"base_reward": 65,
		"unlocked_at_level": 2
	},
	{
		"id": "salad_burger",
		"name": "Salada Especial",
		"ingredients": [
			IngredientType.BUN_BOTTOM,
			IngredientType.PATTY,
			IngredientType.CHEESE,
			IngredientType.TOMATO,
			IngredientType.LETTUCE,
			IngredientType.SAUCE,
			IngredientType.BUN_TOP
		],
		"has_fries": false,
		"has_soda": false,
		"base_reward": 75,
		"unlocked_at_level": 3
	},
	{
		"id": "combo_classic",
		"name": "Combo Clássico",
		"ingredients": [
			IngredientType.BUN_BOTTOM,
			IngredientType.PATTY,
			IngredientType.CHEESE,
			IngredientType.LETTUCE,
			IngredientType.BUN_TOP
		],
		"has_fries": true,
		"has_soda": true,
		"base_reward": 95,
		"unlocked_at_level": 4
	},
	{
		"id": "monster_burger",
		"name": "Lanche Monstro",
		"ingredients": [
			IngredientType.BUN_BOTTOM,
			IngredientType.PATTY,
			IngredientType.CHEESE,
			IngredientType.SAUCE,
			IngredientType.PATTY,
			IngredientType.CHEESE,
			IngredientType.TOMATO,
			IngredientType.LETTUCE,
			IngredientType.SAUCE,
			IngredientType.BUN_TOP
		],
		"has_fries": true,
		"has_soda": false,
		"base_reward": 120,
		"unlocked_at_level": 6
	},
	{
		"id": "panic_combo",
		"name": "Combo em Pânico",
		"ingredients": [
			IngredientType.BUN_BOTTOM,
			IngredientType.PATTY,
			IngredientType.CHEESE,
			IngredientType.PATTY,
			IngredientType.CHEESE,
			IngredientType.TOMATO,
			IngredientType.LETTUCE,
			IngredientType.SAUCE,
			IngredientType.BUN_TOP
		],
		"has_fries": true,
		"has_soda": true,
		"base_reward": 150,
		"unlocked_at_level": 7
	}
]

func get_unlocked_recipes(level: int) -> Array:
	var unlocked = []
	for r in RECIPES:
		if r.unlocked_at_level <= level:
			unlocked.append(r)
	if unlocked.is_empty():
		unlocked.append(RECIPES[0])
	return unlocked

func get_ingredient_name(type: int) -> String:
	if INGREDIENT_DATA.has(type):
		return INGREDIENT_DATA[type]["name"]
	return "Desconhecido"

func get_ingredient_color(type: int) -> Color:
	if INGREDIENT_DATA.has(type):
		return INGREDIENT_DATA[type]["icon_color"]
	return Color.WHITE

func validate_order(target_recipe: Dictionary, assembled_layers: Array, has_fries: bool, has_soda: bool) -> Dictionary:
	var expected_layers: Array = target_recipe["ingredients"]
	var result = {
		"is_perfect": false,
		"is_acceptable": false,
		"accuracy": 0.0,
		"penalty": 0,
		"message": ""
	}

	if assembled_layers.size() != expected_layers.size():
		result["message"] = "Quantidade de ingredientes incorreta!"
		return result

	var matches: int = 0
	for i in range(expected_layers.size()):
		if assembled_layers[i] == expected_layers[i]:
			matches += 1

	var burger_matches: bool = (matches == expected_layers.size())
	var fries_matches: bool = (target_recipe["has_fries"] == has_fries)
	var soda_matches: bool = (target_recipe["has_soda"] == has_soda)

	if burger_matches and fries_matches and soda_matches:
		result["is_perfect"] = true
		result["is_acceptable"] = true
		result["accuracy"] = 1.0
		result["message"] = "Perfeito!"
		return result

	if burger_matches and (not fries_matches or not soda_matches):
		result["is_acceptable"] = false
		result["message"] = "Esqueceu o acompanhamento!"
		result["penalty"] = 20
		return result

	result["accuracy"] = float(matches) / float(expected_layers.size())
	result["message"] = "Ingredientes fora de ordem ou errados!"
	return result
