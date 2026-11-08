extends Node
# Estado do jogador (moedas, dia, nível, compras) + salvamento + fonte.

const R = preload("res://scripts/Rules.gd")
const SAVE_PATH := "user://lanche_save_v3.cfg"

signal coins_changed(value: int)

var coins: int = 0
var day: int = 1
var xp: int = 0
var owned: Dictionary = {}       # id -> tier comprado
var day_best: Dictionary = {}    # dia -> melhor nota (estrelas)
var best_combo: int = 0
var total_served: int = 0
var easy: bool = true            # modo Fácil = dicas ligadas
var mode_chosen: bool = false
var sfx_on: bool = true
var music_on: bool = true
var tutorial_done: bool = false

var font: FontVariation


func _ready() -> void:
	font = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 0.9
	load_game()


func level() -> int:
	return R.level_for_xp(xp)


func add_coins(v: int) -> void:
	coins = max(0, coins + v)
	coins_changed.emit(coins)


func buy_state(u: Dictionary) -> String:
	var nt := R.next_tier(owned, u)
	if nt.is_empty():
		return "max"
	if level() < nt["level"]:
		return "locked"
	if coins < nt["price"]:
		return "poor"
	return "ok"


func buy(id: String) -> bool:
	var u := R.upgrade_by_id(id)
	if u.is_empty() or buy_state(u) != "ok":
		return false
	var nt := R.next_tier(owned, u)
	add_coins(-int(nt["price"]))
	owned[id] = int(nt["tier"])
	save_game()
	return true


func reset_progress() -> void:
	coins = 0
	day = 1
	xp = 0
	owned = {}
	day_best = {}
	best_combo = 0
	total_served = 0
	tutorial_done = false
	save_game()
	coins_changed.emit(coins)


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("p", "coins", coins)
	cfg.set_value("p", "day", day)
	cfg.set_value("p", "xp", xp)
	cfg.set_value("p", "owned", owned)
	cfg.set_value("p", "day_best", day_best)
	cfg.set_value("p", "best_combo", best_combo)
	cfg.set_value("p", "total_served", total_served)
	cfg.set_value("p", "easy", easy)
	cfg.set_value("p", "mode_chosen", mode_chosen)
	cfg.set_value("p", "sfx_on", sfx_on)
	cfg.set_value("p", "music_on", music_on)
	cfg.set_value("p", "tutorial_done", tutorial_done)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	coins = cfg.get_value("p", "coins", 0)
	day = cfg.get_value("p", "day", 1)
	xp = cfg.get_value("p", "xp", 0)
	owned = cfg.get_value("p", "owned", {})
	day_best = cfg.get_value("p", "day_best", {})
	best_combo = cfg.get_value("p", "best_combo", 0)
	total_served = cfg.get_value("p", "total_served", 0)
	easy = cfg.get_value("p", "easy", true)
	mode_chosen = cfg.get_value("p", "mode_chosen", false)
	sfx_on = cfg.get_value("p", "sfx_on", true)
	music_on = cfg.get_value("p", "music_on", true)
	tutorial_done = cfg.get_value("p", "tutorial_done", false)
