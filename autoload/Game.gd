extends Node
# Estado do jogador (moedas, dia, compras) + salvamento + fontes.

const R = preload("res://scripts/Rules.gd")
const SAVE_PATH := "user://lanche_save.cfg"

signal coins_changed(value: int)

var coins: int = 0
var day: int = 1
var owned: Dictionary = {}
var best_day_coins: int = 0
var total_stars: int = 0
var hints: bool = true
var sound: bool = true
var tutorial_done: bool = false

var font: FontVariation


func _ready() -> void:
	font = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 0.9
	load_game()


func add_coins(v: int) -> void:
	coins = max(0, coins + v)
	coins_changed.emit(coins)


func can_buy(u: Dictionary) -> bool:
	if owned.has(u["id"]):
		return false
	if u.has("needs") and not owned.has(u["needs"]):
		return false
	return coins >= u["price"]


func buy(id: String) -> bool:
	var u := R.upgrade_by_id(id)
	if u.is_empty() or not can_buy(u):
		return false
	add_coins(-int(u["price"]))
	owned[id] = true
	save_game()
	return true


func reset_progress() -> void:
	coins = 0
	day = 1
	owned = {}
	best_day_coins = 0
	total_stars = 0
	tutorial_done = false
	save_game()
	coins_changed.emit(coins)


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("p", "coins", coins)
	cfg.set_value("p", "day", day)
	cfg.set_value("p", "owned", owned.keys())
	cfg.set_value("p", "best_day_coins", best_day_coins)
	cfg.set_value("p", "total_stars", total_stars)
	cfg.set_value("p", "hints", hints)
	cfg.set_value("p", "sound", sound)
	cfg.set_value("p", "tutorial_done", tutorial_done)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	coins = cfg.get_value("p", "coins", 0)
	day = cfg.get_value("p", "day", 1)
	owned = {}
	for k in cfg.get_value("p", "owned", []):
		owned[str(k)] = true
	best_day_coins = cfg.get_value("p", "best_day_coins", 0)
	total_stars = cfg.get_value("p", "total_stars", 0)
	hints = cfg.get_value("p", "hints", true)
	sound = cfg.get_value("p", "sound", true)
	tutorial_done = cfg.get_value("p", "tutorial_done", false)
