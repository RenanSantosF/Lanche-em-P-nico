extends RefCounted
# Regras puras do jogo (sem nós): ingredientes, cardápio, loja, níveis, metas,
# notas e pagamento. Tudo aqui é testável sem abrir a tela.

enum { BUN_BOTTOM, PATTY, CHEESE, LETTUCE, TOMATO, BACON, EGG, ONION, PICKLE, BUN_TOP }

const FRIES := 100
const SODA := 101
const BUN := -1  # botão único de pão: base quando vazio, tampa quando já tem algo

const NAMES := {
	BUN_BOTTOM: "Pão", PATTY: "Carne", CHEESE: "Cheddar", LETTUCE: "Alface",
	TOMATO: "Tomate", BACON: "Bacon", EGG: "Ovo", ONION: "Cebola", PICKLE: "Picles",
	BUN_TOP: "Pão", FRIES: "Batata", SODA: "Refri", BUN: "Pão",
}

const TILE_COLORS := {
	BUN: Color("ffcf7a"), PATTY: Color("d9906a"), CHEESE: Color("ffe680"),
	LETTUCE: Color("a8e68a"), TOMATO: Color("ff9a94"), BACON: Color("f5a3a0"),
	EGG: Color("fff4c2"), ONION: Color("dcb6f0"), PICKLE: Color("c9e88a"),
	FRIES: Color("ffd86b"), SODA: Color("8fd3ff"),
}

const B := BUN_BOTTOM
const T := BUN_TOP

const MENU := [
	{"name": "Hambúrguer", "layers": [B, PATTY, T], "price": 8},
	{"name": "X-Burger", "layers": [B, PATTY, CHEESE, T], "price": 10},
	{"name": "X-Alface", "layers": [B, LETTUCE, PATTY, CHEESE, T], "price": 12},
	{"name": "Duplo", "layers": [B, PATTY, CHEESE, PATTY, CHEESE, T], "price": 17},
	{"name": "X-Salada", "layers": [B, LETTUCE, TOMATO, PATTY, CHEESE, T], "price": 15},
	{"name": "Tomatinho", "layers": [B, PATTY, TOMATO, T], "price": 11},
	{"name": "X-Bacon", "layers": [B, PATTY, CHEESE, BACON, T], "price": 15},
	{"name": "Bacon Duplo", "layers": [B, PATTY, BACON, PATTY, CHEESE, BACON, T], "price": 23},
	{"name": "X-Egg", "layers": [B, PATTY, CHEESE, EGG, T], "price": 15},
	{"name": "Café da Manhã", "layers": [B, PATTY, CHEESE, BACON, EGG, T], "price": 19},
	{"name": "X-Cebola", "layers": [B, PATTY, CHEESE, ONION, T], "price": 14},
	{"name": "Picles Show", "layers": [B, PICKLE, PATTY, CHEESE, PICKLE, T], "price": 16},
	{"name": "Salada Fresca", "layers": [B, LETTUCE, PATTY, TOMATO, ONION, T], "price": 16},
	{"name": "Egg Bacon", "layers": [B, PATTY, EGG, BACON, T], "price": 17},
	{"name": "X-Tudo", "layers": [B, LETTUCE, TOMATO, PATTY, CHEESE, BACON, EGG, ONION, T], "price": 30},
	{"name": "Monstrão", "layers": [B, PATTY, CHEESE, BACON, PATTY, CHEESE, EGG, PICKLE, T], "price": 32},
]

const SIDE_PRICE := {FRIES: 5, SODA: 4}
const START_INGREDIENTS := [BUN_BOTTOM, PATTY, CHEESE, LETTUCE, BUN_TOP]

# Loja. Cada item pode ter vários níveis (tiers): prices[i] e levels[i] (nível de chef exigido).
const UPGRADES := [
	{"id": "tomato", "name": "Tomate", "desc": "Novo ingrediente! Libera X-Salada.", "kind": "ing", "item": TOMATO, "prices": [70], "levels": [2]},
	{"id": "grill", "name": "Chapa maior", "desc": "+1 carne na chapa ao mesmo tempo.", "kind": "grill", "prices": [60, 240, 520], "levels": [1, 3, 6]},
	{"id": "exhaust", "name": "Exaustor", "desc": "A carne demora mais pra queimar (+3s).", "kind": "exhaust", "prices": [150, 380], "levels": [2, 5]},
	{"id": "decor", "name": "Decoração", "desc": "Lanchonete linda: clientes +15% pacientes.", "kind": "decor", "prices": [140, 320, 600], "levels": [2, 4, 7]},
	{"id": "bacon", "name": "Bacon", "desc": "Crocante! Libera X-Bacon.", "kind": "ing", "item": BACON, "prices": [160], "levels": [3]},
	{"id": "seat", "name": "Mais bancos", "desc": "Atenda +1 cliente de uma vez (mais dinheiro, mais correria).", "kind": "seat", "prices": [220, 560], "levels": [3, 7]},
	{"id": "speed", "name": "Chapa turbo", "desc": "A carne fica pronta mais rápido.", "kind": "speed", "prices": [180, 380, 650], "levels": [3, 5, 8]},
	{"id": "fries", "name": "Fritadeira", "desc": "Clientes pedem batata frita junto.", "kind": "side", "item": FRIES, "prices": [230], "levels": [4]},
	{"id": "tips", "name": "Pote de gorjeta", "desc": "Gorjetas 50% maiores.", "kind": "tips", "prices": [260], "levels": [4]},
	{"id": "egg", "name": "Ovo", "desc": "Novo ingrediente! Libera X-Egg.", "kind": "ing", "item": EGG, "prices": [280], "levels": [5]},
	{"id": "soda", "name": "Máquina de refri", "desc": "Clientes pedem refri junto.", "kind": "side", "item": SODA, "prices": [300], "levels": [5]},
	{"id": "tv", "name": "TV na parede", "desc": "Clientes distraídos: +10% de paciência.", "kind": "tv", "prices": [260], "levels": [4]},
	{"id": "calm", "name": "Chá de camomila", "desc": "Você fica menos nervoso quando os clientes gritam.", "kind": "calm", "prices": [220], "levels": [3]},
	{"id": "marketing", "name": "Panfletos", "desc": "Mais fama: lanches 10% mais caros.", "kind": "marketing", "prices": [200, 450], "levels": [3, 6]},
	{"id": "helper", "name": "Ajudante de chapa", "desc": "Coloca carne na chapa sozinho quando tem espaço livre.", "kind": "helper", "prices": [480], "levels": [5]},
	{"id": "neon", "name": "Letreiro neon", "desc": "Fama! Lanches 20% mais caros.", "kind": "neon", "prices": [450], "levels": [6]},
	{"id": "onion", "name": "Cebola", "desc": "Novo ingrediente! Libera X-Cebola.", "kind": "ing", "item": ONION, "prices": [340], "levels": [6]},
	{"id": "pickle", "name": "Picles", "desc": "Novo ingrediente! Libera o Monstrão.", "kind": "ing", "item": PICKLE, "prices": [420], "levels": [7]},
]

const TITLES := ["Aprendiz", "Ajudante", "Chapeiro", "Cozinheiro", "Chef", "Chef Estrela",
	"Mestre do Lanche", "Grão-Mestre", "Lenda do Lanche"]

# Chapa
const BASE_COOK := 12.0
const MELT_TIME := 2.0  # cheddar derretendo em cima da carne, na chapa
const BURN_AFTER := 6.0
const FRY_TIME := 5.0
const POUR_TIME := 1.6

const CUSTOM_NAME := "Do Meu Jeito"


static func upgrade_by_id(id: String) -> Dictionary:
	for u in UPGRADES:
		if u["id"] == id:
			return u
	return {}


static func tier(owned: Dictionary, id: String) -> int:
	return int(owned.get(id, 0))


static func max_tier(u: Dictionary) -> int:
	return u["prices"].size()


# Próximo nível à venda: {"price", "level"} ou {} se já está no máximo.
static func next_tier(owned: Dictionary, u: Dictionary) -> Dictionary:
	var t := tier(owned, u["id"])
	if t >= max_tier(u):
		return {}
	return {"tier": t + 1, "price": u["prices"][t], "level": u["levels"][t]}


static func unlocked_ingredients(owned: Dictionary) -> Array:
	var list := START_INGREDIENTS.duplicate()
	for u in UPGRADES:
		if u["kind"] == "ing" and tier(owned, u["id"]) > 0:
			list.append(u["item"])
	return list


static func unlocked_sides(owned: Dictionary) -> Array:
	var list := []
	for u in UPGRADES:
		if u["kind"] == "side" and tier(owned, u["id"]) > 0:
			list.append(u["item"])
	return list


static func seat_count(owned: Dictionary) -> int:
	return 2 + tier(owned, "seat")


# Começa com UMA chapa; compra mais na loja (até 4).
static func grill_slots(owned: Dictionary) -> int:
	return 1 + tier(owned, "grill")


static func burn_after(owned: Dictionary) -> float:
	return BURN_AFTER + 3.0 * tier(owned, "exhaust")


# Quanto o nervosismo sobe a cada grito (o chá de camomila acalma).
static func nerve_per_yell(owned: Dictionary) -> float:
	return 0.5 if tier(owned, "calm") > 0 else 1.0


static func cook_time(owned: Dictionary) -> float:
	return BASE_COOK / [1.0, 1.3, 1.65, 2.1][tier(owned, "speed")]


static func patience_mult(owned: Dictionary) -> float:
	return 1.0 + 0.15 * tier(owned, "decor") + 0.1 * tier(owned, "tv")


static func price_mult(owned: Dictionary) -> float:
	var m := 1.2 if tier(owned, "neon") > 0 else 1.0
	return m * (1.0 + 0.1 * tier(owned, "marketing"))


static func tip_mult(owned: Dictionary) -> float:
	return 1.5 if tier(owned, "tips") > 0 else 1.0


# Quantos tiers foram comprados no total (usado para o visual da lanchonete evoluir).
static func total_tiers(owned: Dictionary) -> int:
	var n := 0
	for k in owned:
		n += int(owned[k])
	return n


# ------------------------------------------------------------------ níveis
static func xp_for_level(level: int) -> int:
	# XP total necessário para chegar ao nível `level` (nível 1 = 0)
	return 5 * (level - 1) * level


static func level_for_xp(xp: int) -> int:
	var lv := 1
	while xp >= xp_for_level(lv + 1):
		lv += 1
	return lv


static func title_for_level(level: int) -> String:
	return TITLES[clampi(level - 1, 0, TITLES.size() - 1)]


static func unlocks_at_level(level: int) -> Array:
	var names := []
	for u in UPGRADES:
		for i in u["levels"].size():
			if u["levels"][i] == level:
				names.append(u["name"] + ("" if i == 0 else " %d" % (i + 1)))
	return names


# ------------------------------------------------------------------ dias
static func day_duration(day: int) -> float:
	return minf(80.0 + day * 4.0, 120.0)


static func spawn_interval(day: int, seats: int) -> float:
	var base := maxf(3.6, 10.0 - day * 0.55)
	return base * sqrt(2.0 / seats)


# Meta de moedas do dia (1 estrela). 2 estrelas = 1.5x, 3 estrelas = 2x.
static func day_goal(day: int, owned: Dictionary) -> int:
	var g := 28.0 + (day - 1) * 13.0 + pow(day - 1, 1.35) * 2.0
	g *= 1.0 + 0.12 * (seat_count(owned) - 2)
	g *= price_mult(owned)
	return int(round(g / 5.0) * 5)


static func day_stars(earned: int, goal: int) -> int:
	if earned >= goal * 2:
		return 3
	if earned >= int(goal * 1.5):
		return 2
	if earned >= goal:
		return 1
	return 0


static func rush_window(day: int) -> Array:
	# [início, fim] em segundos decorridos; dia 1 não tem rush
	if day < 2:
		return []
	var dur := day_duration(day)
	return [dur * 0.45, dur * 0.45 + minf(12.0 + day, 22.0)]


# ------------------------------------------------------------------ pedidos
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


static func custom_recipe(owned: Dictionary, day: int, rnd: RandomNumberGenerator) -> Dictionary:
	var have := unlocked_ingredients(owned)
	for x in [BUN_BOTTOM, BUN_TOP, CHEESE, PATTY]:
		have.erase(x)
	var n := rnd.randi_range(1, mini(2 + day / 3, 5))
	var layers := [B]
	var patties := 1 if rnd.randf() < 0.75 else 2
	var middle := []
	for i in n:
		middle.append(have[rnd.randi_range(0, have.size() - 1)])
	for p in patties:
		var at := rnd.randi_range(0, middle.size())
		while at < middle.size() and middle[at] == CHEESE:
			at += 1
		if rnd.randf() < 0.6:
			middle.insert(at, CHEESE)  # o cheddar sempre vai em cima da carne
		middle.insert(at, PATTY)
	layers.append_array(middle)
	layers.append(T)
	return {"name": CUSTOM_NAME, "layers": layers, "price": 4 + layers.size() * 2, "custom": true}


# O cheddar só pode vir logo depois de uma carne (ele derrete em cima dela, na chapa).
static func cheese_ok(layers: Array) -> bool:
	for i in layers.size():
		if layers[i] == CHEESE and (i == 0 or layers[i - 1] != PATTY):
			return false
	return true


# Tipos de cliente: normal, kid, vip, critic
static func pick_customer_kind(day: int, rnd: RandomNumberGenerator) -> String:
	var r := rnd.randf()
	if day >= 5 and r < 0.08:
		return "critic"
	if day >= 3 and r < 0.2:
		return "vip"
	if r < 0.45:
		return "kid"
	return "normal"


static func kind_pay_mult(kind: String) -> float:
	match kind:
		"vip": return 2.0
		"critic": return 3.0
		"kid": return 0.8
	return 1.0


static func kind_patience_mult(kind: String) -> float:
	match kind:
		"vip": return 0.7
		"critic": return 0.85
		"kid": return 1.25
	return 1.0


static func max_patience(recipe: Dictionary, sides: Array, day: int, owned: Dictionary, kind: String = "normal") -> float:
	var patties: int = recipe["layers"].count(PATTY)
	var p: float = 18.0 + recipe["layers"].size() * 3.8 + patties * cook_time(owned) * 0.8 + sides.size() * 4.0
	p *= maxf(0.5, 1.0 - (day - 1) * 0.045)
	return p * patience_mult(owned) * kind_patience_mult(kind)


# ------------------------------------------------------------------ notas
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
# Dá para entregar de qualquer jeito, mas lanche aberto (sem o pão de cima) ou sem o pão
# de baixo é falha grave: custa 2 estrelas em vez de 1. Prato vazio = 0 estrelas.
static func grade(wanted: Array, built: Array, wanted_sides: Array, built_sides: Array) -> int:
	if built.is_empty():
		return 0
	var errors := mistakes(wanted, built) + side_mistakes(wanted_sides, built_sides)
	if built[-1] != BUN_TOP:
		errors += 1
	if built[0] != BUN_BOTTOM:
		errors += 1
	return clampi(3 - errors, 0, 3)


static func order_value(recipe: Dictionary, sides: Array, owned: Dictionary, kind: String = "normal") -> int:
	var v: float = recipe["price"]
	for s in sides:
		v += SIDE_PRICE[s]
	return int(round(v * price_mult(owned) * kind_pay_mult(kind)))


static func combo_mult(combo: int) -> float:
	return 1.0 + 0.1 * mini(combo, 10)


# Crítico só paga se estiver perfeito.
static func payout(value: int, stars: int, patience_ratio: float, combo: int = 0,
		owned: Dictionary = {}, kind: String = "normal") -> Dictionary:
	var share: float = [0.0, 0.35, 0.65, 1.0][stars]
	if kind == "critic" and stars < 3:
		share = 0.0
	var coins := int(round(value * share * combo_mult(combo)))
	var tip := 0
	if stars == 3 and patience_ratio > 0.5:
		tip = int(ceil(value * 0.25 * (patience_ratio - 0.3) * 2.0 * tip_mult(owned)))
	return {"coins": coins, "tip": tip}


static func xp_for_order(stars: int, kind: String) -> int:
	var xp := stars
	if stars == 3 and (kind == "vip" or kind == "critic"):
		xp += 3
	return xp
