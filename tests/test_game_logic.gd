extends SceneTree
# Testes headless das regras do jogo: godot --headless -s tests/test_game_logic.gd

const R = preload("res://scripts/Rules.gd")

var failures := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  - ", msg)
	else:
		failures += 1
		printerr("  FALHOU - ", msg)


func _init() -> void:
	print("--- Testes Lanche em Pânico ---")
	var xb := [R.BUN_BOTTOM, R.PATTY, R.CHEESE, R.BUN_TOP]

	# notas
	check(R.grade(xb, xb, [], []) == 3, "lanche perfeito = 3 estrelas")
	check(R.grade(xb, [R.BUN_BOTTOM, R.PATTY, R.BUN_TOP], [], []) == 2, "faltou 1 ingrediente = 2 estrelas")
	check(R.grade(xb, [R.BUN_BOTTOM, R.CHEESE, R.PATTY, R.BUN_TOP], [], []) == 1, "ordem trocada = 1 estrela")
	check(R.grade(xb, [R.BUN_BOTTOM, R.LETTUCE, R.LETTUCE, R.LETTUCE, R.LETTUCE], [], []) == 0, "tudo errado = 0")
	check(R.grade(xb, xb, [R.FRIES], []) == 2, "esqueceu a batata = 2 estrelas")
	check(R.grade(xb, xb, [R.FRIES, R.SODA], [R.SODA, R.FRIES]) == 3, "acompanhamentos certos = 3 estrelas")

	# cardápio e loja
	var start := R.available_recipes({}, 1)
	check(start.size() >= 2, "dia 1 tem lanches disponíveis")
	for r in start:
		for l in r["layers"]:
			check(R.START_INGREDIENTS.has(l), "%s usa só ingredientes iniciais" % r["name"])
	for r in R.MENU:
		check(R.cheese_ok(r["layers"]), "%s: cheddar sempre em cima da carne" % r["name"])
		check(r["layers"][0] == R.BUN_BOTTOM and r["layers"][-1] == R.BUN_TOP, "%s começa e termina com pão" % r["name"])
	var maxed := {}
	for u in R.UPGRADES:
		check(u["prices"].size() == u["levels"].size(), "%s: preços e níveis batem" % u["id"])
		maxed[u["id"]] = R.max_tier(u)
	check(R.available_recipes(maxed, 20).size() == R.MENU.size(), "tudo comprado libera o cardápio inteiro")
	check(R.seat_count({}) == 2 and R.seat_count(maxed) == 4, "bancos 2 -> 4")
	check(R.grill_slots({}) == 2 and R.grill_slots(maxed) == 4, "chapa 2 -> 4")
	check(R.cook_time(maxed) < R.cook_time({}), "chapa turbo cozinha mais rápido")
	check(R.cook_time({}) > 7.0 and R.BURN_AFTER == 6.0, "carne demora um pouco mais; tempo de queimar igual")
	check(not R.cheese_ok([R.BUN_BOTTOM, R.CHEESE, R.PATTY, R.BUN_TOP]), "cheddar sem carne embaixo é inválido")
	check(R.next_tier(maxed, R.upgrade_by_id("speed")).is_empty(), "upgrade no máximo não vende mais")
	check(R.next_tier({}, R.upgrade_by_id("speed"))["level"] == 3, "chapa turbo exige nível 3")

	# níveis
	check(R.level_for_xp(0) == 1, "começa no nível 1")
	check(R.level_for_xp(R.xp_for_level(5)) == 5, "xp exato sobe de nível")
	check(R.level_for_xp(R.xp_for_level(5) - 1) == 4, "1 xp a menos não sobe")
	check(R.title_for_level(1) == "Aprendiz", "título inicial")

	# metas
	var g1 := R.day_goal(1, {})
	check(R.day_goal(10, {}) > g1, "meta cresce com os dias")
	check(R.day_stars(g1 - 1, g1) == 0, "abaixo da meta = 0 estrelas")
	check(R.day_stars(g1, g1) == 1 and R.day_stars(g1 * 2, g1) == 3, "estrelas do dia")
	check(R.rush_window(1).is_empty() and R.rush_window(3).size() == 2, "rush a partir do dia 2")

	# pagamento
	var p3 := R.payout(10, 3, 0.9)
	var p1 := R.payout(10, 1, 0.9)
	check(p3["coins"] == 10 and p3["tip"] > 0, "3 estrelas paga tudo + gorjeta")
	check(p1["coins"] < p3["coins"] and p1["tip"] == 0, "1 estrela paga menos")
	check(R.payout(10, 0, 1.0)["coins"] == 0, "0 estrelas não paga")
	check(R.payout(10, 3, 0.2, 5)["coins"] > 10, "combo aumenta o pagamento")
	check(R.payout(30, 2, 1.0, 0, {}, "critic")["coins"] == 0, "crítico não paga lanche imperfeito")
	check(R.order_value(R.MENU[1], [], {}, "vip") == 2 * R.order_value(R.MENU[1], [], {}), "VIP paga em dobro")

	# pedidos "do meu jeito"
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 30:
		var c := R.custom_recipe(maxed, 9, rng)
		var ls: Array = c["layers"]
		check(ls[0] == R.BUN_BOTTOM and ls[-1] == R.BUN_TOP and ls.count(R.PATTY) <= 3 and R.cheese_ok(ls), "do meu jeito válido #%d" % i)

	check(R.spawn_interval(10, 2) < R.spawn_interval(1, 2), "fila acelera com os dias")

	if failures == 0:
		print("--- TODOS OS TESTES PASSARAM ---")
		quit(0)
	else:
		printerr("--- %d TESTE(S) FALHARAM ---" % failures)
		quit(1)
