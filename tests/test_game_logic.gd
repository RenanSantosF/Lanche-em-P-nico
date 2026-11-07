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

	check(R.grade(xb, xb, [], []) == 3, "lanche perfeito = 3 estrelas")
	check(R.grade(xb, [R.BUN_BOTTOM, R.PATTY, R.BUN_TOP], [], []) == 2, "faltou 1 ingrediente = 2 estrelas")
	check(R.grade(xb, [R.BUN_BOTTOM, R.CHEESE, R.PATTY, R.BUN_TOP], [], []) == 1, "ordem trocada = 1 estrela")
	check(R.grade(xb, [R.BUN_BOTTOM, R.LETTUCE, R.LETTUCE, R.LETTUCE, R.LETTUCE], [], []) == 0, "tudo errado = 0 estrelas")
	check(R.grade(xb, xb, [R.FRIES], []) == 2, "esqueceu a batata = 2 estrelas")
	check(R.grade(xb, xb, [R.FRIES, R.SODA], [R.SODA, R.FRIES]) == 3, "acompanhamentos certos = 3 estrelas")
	check(R.mistakes([], []) == 0, "distância vazia")

	var start := R.available_recipes({}, 1)
	check(start.size() >= 2, "dia 1 tem lanches disponíveis")
	for r in start:
		for l in r["layers"]:
			check(R.START_INGREDIENTS.has(l), "%s usa só ingredientes iniciais" % r["name"])
	for r in R.MENU:
		check(r["layers"][0] == R.BUN_BOTTOM and r["layers"][-1] == R.BUN_TOP, "%s começa e termina com pão" % r["name"])

	var all_owned := {}
	for u in R.UPGRADES:
		all_owned[u["id"]] = true
	check(R.available_recipes(all_owned, 20).size() == R.MENU.size(), "tudo comprado libera o cardápio inteiro")
	check(R.seat_count({}) == 2 and R.seat_count(all_owned) == 4, "bancos 2 -> 4")
	check(R.unlocked_sides(all_owned).size() == 2, "batata e refri liberados")

	var p3 := R.payout(10, 3, 0.9)
	var p1 := R.payout(10, 1, 0.9)
	check(p3["coins"] == 10 and p3["tip"] > 0, "3 estrelas paga tudo + gorjeta")
	check(p1["coins"] < p3["coins"] and p1["tip"] == 0, "1 estrela paga menos")
	check(R.payout(10, 0, 1.0)["coins"] == 0, "0 estrelas não paga")
	check(R.spawn_interval(10, 2) < R.spawn_interval(1, 2), "fila acelera com os dias")

	for u in R.UPGRADES:
		check(not R.upgrade_by_id(u["id"]).is_empty(), "upgrade %s encontrado" % u["id"])

	if failures == 0:
		print("--- TODOS OS TESTES PASSARAM ---")
		quit(0)
	else:
		printerr("--- %d TESTE(S) FALHARAM ---" % failures)
		quit(1)
