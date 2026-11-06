extends SceneTree

# test_game_logic.gd - Comprehensive automated test suite for headless test verification.

const LM = preload("res://scripts/LevelManager.gd")
const BM = preload("res://scripts/BurgerModels.gd")
const RecipesScript = preload("res://autoload/Recipes.gd")
const SaveManagerScript = preload("res://autoload/SaveManager.gd")
const AdManagerScript = preload("res://autoload/AdManager.gd")

func _init() -> void:
	print("--- INICIANDO TESTES DO LANCHE EM PÂNICO ---")

	test_recipes_and_validation()
	test_level_progression()
	test_save_manager()
	test_ad_manager_rules()
	test_models_instantiation()

	print("--- TODOS OS TESTES PASSARAM COM SUCESSO! ---")
	quit(0)

func test_recipes_and_validation() -> void:
	print("[TEST] Validando Catálogo e Regras de Receitas...")
	var recipes_inst = RecipesScript.new()
	var recipes = recipes_inst.RECIPES
	assert(recipes.size() >= 5, "Deve haver pelo menos 5 receitas configuradas")

	var classic = recipes[0]
	assert(classic["id"] == "classic_burger")

	# Test exact valid burger
	var layers_ok = [
		RecipesScript.IngredientType.BUN_BOTTOM,
		RecipesScript.IngredientType.PATTY,
		RecipesScript.IngredientType.CHEESE,
		RecipesScript.IngredientType.LETTUCE,
		RecipesScript.IngredientType.BUN_TOP
	]
	var res_ok = recipes_inst.validate_order(classic, layers_ok, false, false)
	assert(res_ok["is_perfect"] == true, "Validação de receita clássica correta falhou")

	# Test wrong layer order
	var layers_wrong = [
		RecipesScript.IngredientType.BUN_BOTTOM,
		RecipesScript.IngredientType.CHEESE,
		RecipesScript.IngredientType.PATTY,
		RecipesScript.IngredientType.LETTUCE,
		RecipesScript.IngredientType.BUN_TOP
	]
	var res_wrong = recipes_inst.validate_order(classic, layers_wrong, false, false)
	assert(res_wrong["is_perfect"] == false, "Validação permitiu ingredientes fora de ordem")

	# Test missing side
	var combo = recipes[3] # combo_classic requires fries and soda
	assert(combo["has_fries"] == true and combo["has_soda"] == true)
	var res_no_sides = recipes_inst.validate_order(combo, combo["ingredients"], false, false)
	assert(res_no_sides["is_acceptable"] == false, "Combo foi aceito sem acompanhamentos obrigatórios")

	var res_full_combo = recipes_inst.validate_order(combo, combo["ingredients"], true, true)
	assert(res_full_combo["is_perfect"] == true, "Combo completo falhou")
	recipes_inst.free()
	print("  -> Receitas e Validações OK!")

func test_level_progression() -> void:
	print("[TEST] Validando Progressão de Fases e Metas...")
	assert(LM.STAGES.size() == 10, "Devem existir 10 fases configuradas")

	for i in range(1, 11):
		var cfg = LM.get_stage_config(i)
		assert(cfg["stage_num"] == i)
		assert(cfg["duration"] >= 120.0 and cfg["duration"] <= 180.0, "Fase fora do tempo de 2 a 3 minutos: " + str(cfg["duration"]))
		assert(cfg["target_score"] > 0)
		assert(cfg["target_customers"] > 0)

	# Check stars threshold logic
	assert(LM.calculate_stars(1, 50) == 0)
	assert(LM.calculate_stars(1, 130) == 1)
	assert(LM.calculate_stars(1, 190) == 2)
	assert(LM.calculate_stars(1, 300) == 3)
	print("  -> Fases e Estrelas OK!")

func test_save_manager() -> void:
	print("[TEST] Validando SaveManager e Economia...")
	var sm = SaveManagerScript.new()
	sm.reset_progress()
	assert(sm.get_coins() == 100)

	sm.add_coins(50)
	assert(sm.get_coins() == 150)

	var spent = sm.spend_coins(80)
	assert(spent == true)
	assert(sm.get_coins() == 70)

	var spent_fail = sm.spend_coins(1000)
	assert(spent_fail == false)
	assert(sm.get_coins() == 70)

	sm.set_upgrade_level("fast_grill", 2)
	assert(sm.get_upgrade_level("fast_grill") == 2)

	sm.record_level_result(1, 3, 250)
	assert(sm.get_level_stars(1) == 3)
	assert(sm.player_data["unlocked_level"] == 2)
	sm.free()
	print("  -> SaveManager e Progresso OK!")

func test_ad_manager_rules() -> void:
	print("[TEST] Validando Políticas de Anúncios AdMob...")
	var adm = AdManagerScript.new()
	# Ad must NEVER show during active gameplay
	adm.set_gameplay_active(true)
	assert(adm.can_show_interstitial() == false, "Intersticial não pode ser exibido durante partida ativa!")

	adm.set_gameplay_active(false)
	# Check 3 minute safe cooldown
	adm.last_interstitial_time = Time.get_ticks_msec() / 1000.0 - 50.0 # Only 50s ago
	assert(adm.can_show_interstitial() == false, "Intersticial exibido antes do intervalo de 3 minutos!")

	adm.last_interstitial_time = Time.get_ticks_msec() / 1000.0 - 200.0 # 200s ago (> 180s)
	assert(adm.can_show_interstitial() == true, "Intersticial deveria estar liberado após 3 minutos")
	adm.free()
	print("  -> Regras do AdManager OK!")

func test_models_instantiation() -> void:
	print("[TEST] Validando Instanciação de Modelos 3D...")
	for type in RecipesScript.IngredientType.values():
		var node = BM.create_ingredient_node(type)
		assert(node != null)
		node.free()
	print("  -> Modelos 3D OK!")
