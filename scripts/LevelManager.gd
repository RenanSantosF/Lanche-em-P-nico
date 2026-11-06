class_name LevelManager
extends RefCounted

const STAGES = [
	{
		"stage_num": 1,
		"name": "Primeiro Dia no Balcão",
		"duration": 120.0,
		"target_score": 150,
		"target_customers": 3,
		"spawn_interval": 8.5,
		"patience_mult": 1.1,
		"coin_reward": 50,
		"star_thresholds": [120, 180, 240]
	},
	{
		"stage_num": 2,
		"name": "Cheeseburger em Dobro",
		"duration": 130.0,
		"target_score": 250,
		"target_customers": 4,
		"spawn_interval": 8.0,
		"patience_mult": 1.05,
		"coin_reward": 75,
		"star_thresholds": [220, 300, 400]
	},
	{
		"stage_num": 3,
		"name": "Salada Fresca e VIPs",
		"duration": 140.0,
		"target_score": 350,
		"target_customers": 5,
		"spawn_interval": 7.5,
		"patience_mult": 1.0,
		"coin_reward": 100,
		"star_thresholds": [320, 420, 550]
	},
	{
		"stage_num": 4,
		"name": "A Chegada dos Combos",
		"duration": 150.0,
		"target_score": 450,
		"target_customers": 6,
		"spawn_interval": 7.0,
		"patience_mult": 0.95,
		"coin_reward": 125,
		"star_thresholds": [400, 520, 680]
	},
	{
		"stage_num": 5,
		"name": "Hora do Rush Almoço",
		"duration": 150.0,
		"target_score": 600,
		"target_customers": 7,
		"spawn_interval": 6.2,
		"patience_mult": 0.9,
		"coin_reward": 160,
		"star_thresholds": [550, 700, 900]
	},
	{
		"stage_num": 6,
		"name": "Desafio do Monstro",
		"duration": 160.0,
		"target_score": 750,
		"target_customers": 8,
		"spawn_interval": 6.0,
		"patience_mult": 0.88,
		"coin_reward": 200,
		"star_thresholds": [700, 900, 1150]
	},
	{
		"stage_num": 7,
		"name": "Combo em Pânico!",
		"duration": 170.0,
		"target_score": 900,
		"target_customers": 8,
		"spawn_interval": 5.5,
		"patience_mult": 0.85,
		"coin_reward": 240,
		"star_thresholds": [850, 1100, 1400]
	},
	{
		"stage_num": 8,
		"name": "Clientes Exigentes",
		"duration": 180.0,
		"target_score": 1100,
		"target_customers": 9,
		"spawn_interval": 5.0,
		"patience_mult": 0.82,
		"coin_reward": 280,
		"star_thresholds": [1050, 1300, 1650]
	},
	{
		"stage_num": 9,
		"name": "Frenesi Gourmet",
		"duration": 180.0,
		"target_score": 1350,
		"target_customers": 10,
		"spawn_interval": 4.8,
		"patience_mult": 0.8,
		"coin_reward": 320,
		"star_thresholds": [1300, 1600, 2000]
	},
	{
		"stage_num": 10,
		"name": "Mestre Supremo da Chapa",
		"duration": 180.0,
		"target_score": 1600,
		"target_customers": 12,
		"spawn_interval": 4.5,
		"patience_mult": 0.75,
		"coin_reward": 500,
		"star_thresholds": [1550, 1900, 2400]
	}
]

static func get_stage_config(stage_num: int) -> Dictionary:
	var idx = clampi(stage_num - 1, 0, STAGES.size() - 1)
	return STAGES[idx]

static func calculate_stars(stage_num: int, final_score: int) -> int:
	var cfg = get_stage_config(stage_num)
	var thresholds: Array = cfg["star_thresholds"]
	if final_score >= thresholds[2]:
		return 3
	elif final_score >= thresholds[1]:
		return 2
	elif final_score >= thresholds[0]:
		return 1
	return 0
