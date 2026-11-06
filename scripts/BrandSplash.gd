extends Control

# BrandSplash.gd - Modular, reusable custom brand intro sequence.

@onready var brand_container: VBoxContainer = $CenterContainer/BrandContainer
@onready var logo_label: Label = $CenterContainer/BrandContainer/LogoLabel
@onready var sub_label: Label = $CenterContainer/BrandContainer/SubLabel
@onready var glow_rect: ColorRect = $GlowEffect
@onready var progress_bar: ProgressBar = $CenterContainer/BrandContainer/LoadingBar

var target_scene: String = "res://scenes/MainGame.tscn"

func _ready() -> void:
	brand_container.modulate.a = 0.0
	glow_rect.modulate.a = 0.0
	progress_bar.value = 0.0
	_run_brand_sequence()

func _run_brand_sequence() -> void:
	var tween = create_tween()
	tween.set_parallel(false)

	brand_container.scale = Vector2(0.85, 0.85)
	brand_container.pivot_offset = brand_container.size / 2.0

	tween.tween_property(brand_container, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(brand_container, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(glow_rect, "modulate:a", 0.4, 0.4)
	tween.tween_property(glow_rect, "modulate:a", 0.0, 0.4)

	tween.tween_property(progress_bar, "value", 100.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.3)

	tween.tween_property(brand_container, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_on_intro_finished)

func _on_intro_finished() -> void:
	if ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
	else:
		print("[BrandSplash] Intro completed. Next scene ready: ", target_scene)
