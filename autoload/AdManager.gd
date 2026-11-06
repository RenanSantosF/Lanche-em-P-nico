extends Node

# AdManager.gd - Centralized Google AdMob management
# Supports Android mobile AdMob and test mode.
# Implements strict non-intrusive ad policy:
# - Minimum interval between interstitials (~3 minutes / 180s)
# - Never interrupts gameplay or burger preparation
# - Rewarded ads for bonus coins or revival

signal rewarded_ad_completed(reward_type: String, amount: int)
signal interstitial_closed()

const MIN_INTERSTITIAL_INTERVAL: float = 180.0
const TEST_BANNER_ID: String = "ca-app-pub-3940256099942544/6300978111"
const TEST_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"

var last_interstitial_time: float = -9999.0
var is_gameplay_active: bool = false
var admob_plugin = null
var test_mode: bool = true

func _ready() -> void:
	if Engine.has_singleton("PoingGodotAdMob"):
		admob_plugin = Engine.get_singleton("PoingGodotAdMob")
		print("[AdManager] Native AdMob plugin detected.")
	else:
		print("[AdManager] Native AdMob plugin not found; using mock/test mode.")

func set_gameplay_active(active: bool) -> void:
	is_gameplay_active = active

func can_show_interstitial() -> bool:
	if is_gameplay_active:
		return false
	var current_time = Time.get_ticks_msec() / 1000.0
	return (current_time - last_interstitial_time) >= MIN_INTERSTITIAL_INTERVAL

func show_interstitial() -> bool:
	if not can_show_interstitial():
		print("[AdManager] Interstitial skipped: cooldown active or gameplay running.")
		return false

	last_interstitial_time = Time.get_ticks_msec() / 1000.0
	print("[AdManager] Displaying Interstitial Ad (Safe interval respected).")

	if admob_plugin and admob_plugin.has_method("show_interstitial"):
		admob_plugin.show_interstitial()
	else:
		_simulate_ad_display("Interstitial")

	interstitial_closed.emit()
	return true

func show_rewarded_ad(reward_type: String = "coins", amount: int = 50) -> void:
	print("[AdManager] User requested Rewarded Ad for: ", reward_type)
	if admob_plugin and admob_plugin.has_method("show_rewarded_video"):
		admob_plugin.show_rewarded_video()
	else:
		_simulate_ad_display("Rewarded (" + reward_type + ")")
		rewarded_ad_completed.emit(reward_type, amount)

func _simulate_ad_display(ad_type: String) -> void:
	print("[AdManager MOCK] Simulating Ad display: ", ad_type)
