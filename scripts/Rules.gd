extends RefCounted
# Regras puras do jogo (sem nós): ingredientes, cardápio, loja, notas e pagamento.

enum { BUN_BOTTOM, PATTY, CHEESE, LETTUCE, TOMATO, BACON, EGG, ONION, PICKLE, BUN_TOP }

const FRIES := 100
const SODA := 101

# "Pão" é um botão só: coloca o pão de baixo quando o prato está vazio
# e o pão de cima (fechando o lanche) quando já tem algo.
const BUN := -1

const NAMES := {
	BUN_BOTTOM: "Pão",
	PATTY: "Carne",
	CHEESE: "Queijo",
	LETTUCE: "Alface",
	TOMATO: "Tomate",
	BACON: "Bacon",
	EGG: "Ovo",
	ONION: "Cebola",
	PICKLE: "Picles",
	BUN_TOP: "Pão",
	FRIES: "Batata",
	SODA: "Refri",
	BUN: "Pão",
}

const TILE_COLORS := {
	BUN: Color("ffcf7a"),
	PATTY: Color("d9906a"),
	CHEESE: Color("ffe680"),
	LETTUCE: Color("a8e68a"),
	TOMATO: Color("ff9a94"),
	BACON: Color("f5a3a0"),
	EGG: Color("fff4c2"),
	ONION: Color("dcb6f0"),
	PICKLE: Color("c9e88a"),
	FRIES: Color("ffd86b"),
	SODA: Color("8fd3ff"),
}

const B := BUN_BOTTOM
const T := BUN_TOP

const MENU := [
	{"name": "Hambúrguer", "layers": [B, PATTY, T], "price": 8},
	{"name": "X-Burger", "layers": [B, PATTY, CHEESE, T], "price": 10},
	{"name": "X-Alface", "layers": [B, LETTUCE, PATTY, CHEESE, T], "price": 12},
	{"name": "Duplo", "layers": [B, PATTY, CHEESE, PATTY, CHEESE, T], "price": 16},
	{"name": "X-Salada", "layers": [B, LETTUCE, TOMATO, PATTY, CHEESE, T], "price": 15},
	{"name": "Tomatinho", "layers": [B, PATTY, TOMATO, T], "price": 11},
	{"name": "X-Bacon", "layers": [B, PATTY, CHEESE, BACON, T], "price": 15},
	{"name": "Bacon Duplo", "layers": [B, PATTY, BACON, PATTY, CHEESE, BACON, T], "price": 22},
	{"name": "X-Egg", "layers": [B, PATTY, EGG, CHEESE, T], "price": 15},
	{"name": "Café da Manhã", "layers": [B, BACON, EGG, CHEESE, T], "price": 16},
	{"name": "X-Cebola", "layers": [B, PATTY, CHEESE, ONION, T], "price": 14},
	{"name": "Picles Show", "layers": [B, PATTY, PICKLE, CHEESE, PICKLE, T], "price": 16},
	{"name": "X-Tudo", "layers": [B, LETTUCE, TOMATO, PATTY, CHEESE, BACON, EGG, ONION, T], "price": 30},
	{"name": "Monstrão", "layers": [B, PATTY, CHEESE, BACON, PATTY, CHEESE, EGG, PICKLE, T], "price": 32},
]

const SIDE_PRICE := {FRIES: 5, SODA: 4}

const START_INGREDIENTS := [BUN_BOTTOM, PATTY, CHEESE, LETTUCE, BUN_TOP]

# Loja: tudo que dá para comprar para expandir a lanchonete.
const UPGRADES := [
	{"id": "tomato", "name": "Tomate", "desc": "Novo ingrediente! Libera X-Salada.", "price": 60, "kind": "ing", "item": TOMATO},
	{"id": "seat3", "name": "Mais um banco", "desc": "Atenda 3 clientes de uma vez.", "price": 120, "kind": "seat"},
	{"id": "bacon", "name": "Bacon", "desc": "Crocante! Libera X-Bacon.", "price": 140, "kind": "ing", "item": BACON},
	{"id": "fries", "name": "Batata frita", "desc": "Clientes vão pedir batata junto.", "price": 160, "kind": "side", "item": FRIES},
	{"id": "plants", "name": "Plantinhas", "desc": "Lanchonete bonita: clientes 20% mais pacientes.", "price": 180, "kind": "decor"},
	{"id": "egg", "name": "Ovo", "desc": "Novo ingrediente! Libera X-Egg.", "price": 220, "kind": "ing", "item": EGG},
	{"id": "soda", "name": "Refri", "desc": "Clientes vão pedir refri junto.", "price": 240, "kind": "side", "item": SODA},
	{"id": "neon", "name": "Letreiro neon", "desc": "Fama! Lanches 25% mais caros.", "price": 300, "kind": "neon"},
	{"id": "onion", "name": "Cebola", "desc": "Novo ingrediente! Libera X-Cebola.", "price": 280, "kind": "ing", "item": ONION},
	{"id": "seat4", "name": "Balcão gigante", "desc": "Atenda 4 clientes de uma vez.", "price": 420, "kind": "seat", "needs": "seat3"},
	{"id": "pickle", "name": "Picles", "desc": "Novo ingrediente! Libera o Monstrão.", "price": 350, "kind": "ing", "item": PICKLE},
	{"id": "lights", "name": "Luzinhas e música", "desc": "Clima de festa: clientes ainda mais pacientes.", "price": 500, "kind": "decor"},
]


static func upgrade_by_id(id: String) -> Dictionary:
	for u in UPGRADES:
		if u["id"] == id:
			return u
	return {}


static func unlocked_ingredients(owned: Dictionary) -> Array:
	var list := START_INGREDIENTS.duplicate()
	for u in UPGRADES:
		if u["kind"] == "ing" and owned.has(u["id"]):
			list.append(u["item"])
	return list


static func unlocked_sides(owned: Dictionary) -> Array:
	var list := []
	for u in UPGRADES:
		if u["kind"] == "side" and owned.has(u["id"]):
			list.append(u["item"])
	return list


static func seat_count(owned: Dictionary) -> int:
	if owned.has("seat4"):
		return 4
	if owned.has("seat3"):
		return 3
	return 2


static func patience_mult(owned: Dictionary) -> float:
	var m := 1.0
	if owned.has("plants"):
		m += 0.2
	if owned.has("lights"):
		m += 0.2
	return m


static func price_mult(owned: Dictionary) -> float:
	return 1.25 if owned.has("neon") else 1.0


# Lanches que dá para fazer com o que foi comprado, limitados pela dificuldade do dia.
static func available_recipes(owned: Dictionary, day: int) -> Array:
	var have := unlocked_ingredients(owned)
	var max_layers := 4 + day
	var out := []
	for r in MENU:
		var ok: bool = r["layers"].size() <= max_layers
		for l in r["layers"]:
			if not have.has(l):
				ok = false
				break
		if ok:
			out.append(r)
	return out


# Distância de edição entre o lanche pedido e o montado.
static func mistakes(wanted: Array, built: Array) -> int:
	var n := wanted.size()
	var m := built.size()
	var prev := []
	for j in m + 1:
		prev.append(j)
	for i in range(1, n + 1):
		var cur := [i]
		for j in range(1, m + 1):
			var cost := 0 if wanted[i - 1] == built[j - 1] else 1
			cur.append(mini(mini(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + cost))
		prev = cur
	return prev[m]


static func side_mistakes(wanted: Array, built: Array) -> int:
	var count := 0
	for s in [FRIES, SODA]:
		if wanted.has(s) != built.has(s):
			count += 1
	return count


# 3 estrelas = perfeito; cada erro tira uma estrela.
static func grade(wanted: Array, built: Array, wanted_sides: Array, built_sides: Array) -> int:
	var errors := mistakes(wanted, built) + side_mistakes(wanted_sides, built_sides)
	return clampi(3 - errors, 0, 3)


static func order_value(recipe: Dictionary, sides: Array, owned: Dictionary) -> int:
	var v: float = recipe["price"]
	for s in sides:
		v += SIDE_PRICE[s]
	return int(round(v * price_mult(owned)))


static func payout(value: int, stars: int, patience_ratio: float) -> Dictionary:
	var share: float = [0.0, 0.4, 0.7, 1.0][stars]
	var coins := int(round(value * share))
	var tip := 0
	if stars == 3 and patience_ratio > 0.5:
		tip = int(ceil(value * 0.3))
	return {"coins": coins, "tip": tip}


static func day_duration(day: int) -> float:
	return minf(70.0 + day * 6.0, 120.0)


static func spawn_interval(day: int, seats: int) -> float:
	var base := maxf(3.5, 11.0 - day * 0.8)
	return base * sqrt(2.0 / seats)


static func max_patience(recipe: Dictionary, sides: Array, day: int, owned: Dictionary) -> float:
	var p: float = 24.0 + recipe["layers"].size() * 4.5 + sides.size() * 3.0
	p *= maxf(0.55, 1.0 - (day - 1) * 0.05)
	return p * patience_mult(owned)
