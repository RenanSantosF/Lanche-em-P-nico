extends Node
# Anúncios AdMob (plugin Poing Studios).
# - Pede consentimento (GDPR/UMP) antes de iniciar o SDK.
# - Intersticial "A cada fase": entre os dias, com limite de frequência.
# - Premiado "Recompensa": o jogador escolhe assistir para ganhar moedas.
# No APK de teste usa os IDs de teste do Google (nunca clique nos seus anúncios reais!).
# Fora do Android tudo vira no-op, então o jogo roda normal no PC e nos testes.

signal rewarded_ready_changed(ready: bool)

const APP_ID := "ca-app-pub-4311255826061303~4157782489"
const INTERSTITIAL_ID := "ca-app-pub-4311255826061303/7993085719"
const REWARDED_ID := "ca-app-pub-4311255826061303/7320353635"
const TEST_INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

const INTERSTITIAL_MIN_GAP_MS := 150000   # no máximo 1 intersticial a cada 2,5 min
const FIRST_INTERSTITIAL_DAY := 3         # não mostra nos primeiros dias

var enabled := false
var initialized := false
var _interstitial = null
var _rewarded = null
var _loading_inter := false
var _loading_reward := false
var _last_inter_ms := -INTERSTITIAL_MIN_GAP_MS
var _last_reward_ms := -INTERSTITIAL_MIN_GAP_MS
var _days_since_ad := 0
var _reward_cb: Callable
var _reward_earned := false
var _after_inter: Callable


func _ready() -> void:
	enabled = OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob")
	if enabled:
		_request_consent()


# APK de teste (feature "test_ads") e builds de debug usam os anúncios de teste do Google.
func use_test_ads() -> bool:
	return OS.is_debug_build() or OS.has_feature("test_ads")


func _inter_id() -> String:
	return TEST_INTERSTITIAL_ID if use_test_ads() else INTERSTITIAL_ID


func _reward_id() -> String:
	return TEST_REWARDED_ID if use_test_ads() else REWARDED_ID


# ------------------------------------------------------------------ consentimento + init
func _request_consent() -> void:
	var params := ConsentRequestParameters.new()
	UserMessagingPlatform.consent_information.update(params, _on_consent_info_ok, _on_consent_info_fail)


func _on_consent_info_ok() -> void:
	if UserMessagingPlatform.consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_on_form_loaded, func(_e): _init_sdk())
	else:
		_init_sdk()


func _on_consent_info_fail(_err) -> void:
	_init_sdk()


func _on_form_loaded(form) -> void:
	var status = UserMessagingPlatform.consent_information.get_consent_status()
	if status == ConsentInformation.ConsentStatus.REQUIRED:
		form.show(func(_e): _init_sdk())
	else:
		_init_sdk()


func privacy_options_required() -> bool:
	if not enabled:
		return false
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	if enabled:
		UserMessagingPlatform.show_privacy_options_form(func(_e): pass)


func _init_sdk() -> void:
	if initialized:
		return
	initialized = true
	var cfg := RequestConfiguration.new()
	# jogo para todas as idades: só anúncios de classificação livre
	cfg.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	MobileAds.set_request_configuration(cfg)
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_s) -> void:
		_load_interstitial()
		_load_rewarded()
	MobileAds.initialize(listener)


# ------------------------------------------------------------------ intersticial
func _load_interstitial() -> void:
	if not initialized or _interstitial != null or _loading_inter:
		return
	_loading_inter = true
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad) -> void:
		_loading_inter = false
		_interstitial = ad
		var fs := FullScreenContentCallback.new()
		fs.on_ad_dismissed_full_screen_content = func() -> void:
			_destroy_inter()
			_finish_inter()
		fs.on_ad_failed_to_show_full_screen_content = func(_e) -> void:
			_destroy_inter()
			_finish_inter()
		ad.full_screen_content_callback = fs
	cb.on_ad_failed_to_load = func(_e) -> void:
		_loading_inter = false
		get_tree().create_timer(30.0).timeout.connect(_load_interstitial)
	InterstitialAdLoader.new().load(_inter_id(), AdRequest.new(), cb)


func _destroy_inter() -> void:
	if _interstitial:
		_interstitial.destroy()
		_interstitial = null
	_load_interstitial()


func _finish_inter() -> void:
	Sfx.set_music(true)
	if _after_inter.is_valid():
		var cb := _after_inter
		_after_inter = Callable()
		cb.call()


# Chamado ao começar um novo dia. Mostra o intersticial só quando faz sentido;
# `then` é sempre chamado (na hora, ou quando o anúncio fechar).
func maybe_interstitial(day: int, then: Callable) -> void:
	_days_since_ad += 1
	var now := Time.get_ticks_msec()
	var ok := enabled and _interstitial != null and day >= FIRST_INTERSTITIAL_DAY \
		and _days_since_ad >= 2 \
		and now - _last_inter_ms >= INTERSTITIAL_MIN_GAP_MS \
		and now - _last_reward_ms >= 60000
	if not ok:
		then.call()
		return
	_days_since_ad = 0
	_last_inter_ms = now
	_after_inter = then
	Sfx.set_music(false)
	_interstitial.show()


# ------------------------------------------------------------------ premiado
func rewarded_ready() -> bool:
	return enabled and _rewarded != null


func _load_rewarded() -> void:
	if not initialized or _rewarded != null or _loading_reward:
		return
	_loading_reward = true
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad) -> void:
		_loading_reward = false
		_rewarded = ad
		var fs := FullScreenContentCallback.new()
		fs.on_ad_dismissed_full_screen_content = func() -> void:
			_end_rewarded()
		fs.on_ad_failed_to_show_full_screen_content = func(_e) -> void:
			_end_rewarded()
		ad.full_screen_content_callback = fs
		rewarded_ready_changed.emit(true)
	cb.on_ad_failed_to_load = func(_e) -> void:
		_loading_reward = false
		get_tree().create_timer(30.0).timeout.connect(_load_rewarded)
	RewardedAdLoader.new().load(_reward_id(), AdRequest.new(), cb)


# Mostra o premiado. on_done(recebeu: bool) é chamado quando o anúncio fecha.
func show_rewarded(on_done: Callable) -> void:
	if not rewarded_ready():
		on_done.call(false)
		return
	_reward_cb = on_done
	_reward_earned = false
	_last_reward_ms = Time.get_ticks_msec()
	Sfx.set_music(false)
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item) -> void:
		_reward_earned = true
	_rewarded.show(listener)


func _end_rewarded() -> void:
	if _rewarded:
		_rewarded.destroy()
		_rewarded = null
	rewarded_ready_changed.emit(false)
	Sfx.set_music(true)
	if _reward_cb.is_valid():
		var cb := _reward_cb
		_reward_cb = Callable()
		cb.call_deferred(_reward_earned)
	_load_rewarded()
