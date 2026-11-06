extends Node

# SaveManager.gd - Handles persistent game progression, settings and coins

const SAVE_PATH = "user://panico_save.json"

var player_data: Dictionary = {
	"coins": 100,
	"high_score": 0,
	"unlocked_level": 1,
	"level_stars": {},
	"upgrades": {
		"fast_grill": 0,
		"fast_fryer": 0,
		"patience_boost": 0,
		"counter_style": 0
	},
	"sound_enabled": true,
	"music_enabled": true
}

signal data_loaded()
signal data_saved()
signal coins_changed(new_amount: int)

func _ready() -> void:
	load_game()

func get_coins() -> int:
	return int(player_data.get("coins", 0))

func add_coins(amount: int) -> void:
	var current = get_coins()
	player_data["coins"] = max(0, current + amount)
	coins_changed.emit(player_data["coins"])
	save_game()

func spend_coins(amount: int) -> bool:
	var current = get_coins()
	if current >= amount:
		player_data["coins"] = current - amount
		coins_changed.emit(player_data["coins"])
		save_game()
		return true
	return false

func get_upgrade_level(upgrade_id: String) -> int:
	var upgrades: Dictionary = player_data.get("upgrades", {})
	return int(upgrades.get(upgrade_id, 0))

func set_upgrade_level(upgrade_id: String, level: int) -> void:
	if not player_data.has("upgrades"):
		player_data["upgrades"] = {}
	player_data["upgrades"][upgrade_id] = level
	save_game()

func get_level_stars(level_num: int) -> int:
	var stars_dict: Dictionary = player_data.get("level_stars", {})
	return int(stars_dict.get(str(level_num), 0))

func record_level_result(level_num: int, stars: int, score: int) -> void:
	var stars_dict: Dictionary = player_data.get("level_stars", {})
	var current_stars = int(stars_dict.get(str(level_num), 0))
	if stars > current_stars:
		stars_dict[str(level_num)] = stars
		player_data["level_stars"] = stars_dict

	if score > int(player_data.get("high_score", 0)):
		player_data["high_score"] = score

	if stars >= 1 and level_num >= int(player_data.get("unlocked_level", 1)):
		player_data["unlocked_level"] = level_num + 1

	save_game()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(player_data, "\t")
		file.store_string(json_str)
		file.close()
		data_saved.emit()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(content)
		if typeof(parsed) == TYPE_DICTIONARY:
			for k in parsed.keys():
				player_data[k] = parsed[k]
			data_loaded.emit()

func reset_progress() -> void:
	player_data = {
		"coins": 100,
		"high_score": 0,
		"unlocked_level": 1,
		"level_stars": {},
		"upgrades": {
			"fast_grill": 0,
			"fast_fryer": 0,
			"patience_boost": 0,
			"counter_style": 0
		},
		"sound_enabled": true,
		"music_enabled": true
	}
	save_game()
