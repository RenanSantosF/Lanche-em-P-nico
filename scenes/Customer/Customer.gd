extends Node3D

signal patience_depleted(customer)
signal customer_served(customer, was_happy)

enum CustomerMood {
	HAPPY,
	WAITING,
	IMPATIENT,
	ANGRY,
	CELEBRATING
}

@export var max_patience: float = 35.0
var current_patience: float = 35.0
var mood: CustomerMood = CustomerMood.HAPPY
var is_active: bool = false
var is_vip: bool = false
var order_data: Dictionary = {}

@onready var body_mesh: MeshInstance3D = $Visual/Body
@onready var head_mesh: MeshInstance3D = $Visual/Head
@onready var hair_hat_mesh: MeshInstance3D = $Visual/HairHat
@onready var left_arm: MeshInstance3D = $Visual/LeftArm
@onready var right_arm: MeshInstance3D = $Visual/RightArm
@onready var speech_bubble: Label3D = $SpeechBubble
@onready var patience_bar: Label3D = $PatienceBar

var anim_time: float = 0.0
var base_position: Vector3 = Vector3.ZERO

const CUSTOMER_PALETTES = [
	{ "body": Color(0.2, 0.45, 0.85), "head": Color(0.95, 0.75, 0.62), "hat": Color(0.15, 0.15, 0.15) },
	{ "body": Color(0.85, 0.25, 0.25), "head": Color(0.65, 0.45, 0.32), "hat": Color(0.9, 0.8, 0.2) },
	{ "body": Color(0.25, 0.75, 0.35), "head": Color(0.92, 0.70, 0.55), "hat": Color(0.45, 0.25, 0.15) },
	{ "body": Color(0.85, 0.55, 0.15), "head": Color(0.95, 0.78, 0.65), "hat": Color(0.2, 0.2, 0.2) },
	{ "body": Color(0.55, 0.25, 0.65), "head": Color(0.50, 0.32, 0.22), "hat": Color(0.8, 0.2, 0.3) }
]

func setup_customer(order: Dictionary, vip: bool = false, patience_multiplier: float = 1.0) -> void:
	order_data = order
	is_vip = vip

	var boost = 1.0
	if has_node("/root/SaveManager"):
		var lvl = get_node("/root/SaveManager").get_upgrade_level("patience_boost")
		boost += (lvl * 0.15)

	max_patience = (25.0 if is_vip else 35.0) * boost * patience_multiplier
	current_patience = max_patience
	mood = CustomerMood.HAPPY
	is_active = true

	_randomize_appearance()
	_update_speech_bubble()

func _randomize_appearance() -> void:
	var pal = CUSTOMER_PALETTES.pick_random()
	if is_vip:
		pal = { "body": Color(0.85, 0.7, 0.1), "head": Color(0.95, 0.78, 0.65), "hat": Color(0.1, 0.1, 0.1) }

	if body_mesh:
		var mat_body = StandardMaterial3D.new()
		mat_body.albedo_color = pal["body"]
		body_mesh.material_override = mat_body

	if head_mesh:
		var mat_head = StandardMaterial3D.new()
		mat_head.albedo_color = pal["head"]
		head_mesh.material_override = mat_head

	if hair_hat_mesh:
		var mat_hat = StandardMaterial3D.new()
		mat_hat.albedo_color = pal["hat"]
		hair_hat_mesh.material_override = mat_hat

func _process(delta: float) -> void:
	if not is_active:
		return

	anim_time += delta
	current_patience = max(0.0, current_patience - delta)
	var patience_pct = current_patience / max_patience

	_update_mood(patience_pct)
	_play_mood_animation(delta)
	_update_speech_bubble()

	if current_patience <= 0.0:
		is_active = false
		mood = CustomerMood.ANGRY
		_play_leave_angry()

func _update_mood(pct: float) -> void:
	if mood == CustomerMood.CELEBRATING:
		return
	if pct > 0.65:
		mood = CustomerMood.HAPPY
	elif pct > 0.35:
		mood = CustomerMood.WAITING
	elif pct > 0.12:
		mood = CustomerMood.IMPATIENT
	else:
		mood = CustomerMood.ANGRY

func _play_mood_animation(_delta: float) -> void:
	var visual = $Visual
	if not visual:
		return

	match mood:
		CustomerMood.HAPPY:
			visual.position.y = sin(anim_time * 4.0) * 0.04
			visual.rotation.z = sin(anim_time * 2.0) * 0.02
			if left_arm: left_arm.rotation.z = 0.0
			if right_arm: right_arm.rotation.z = 0.0
		CustomerMood.WAITING:
			visual.position.y = sin(anim_time * 3.0) * 0.02
			visual.rotation.y = sin(anim_time * 1.5) * 0.15
		CustomerMood.IMPATIENT:
			visual.position.y = abs(sin(anim_time * 8.0)) * 0.05
			visual.rotation.z = sin(anim_time * 6.0) * 0.05
			if left_arm: left_arm.rotation.z = 0.4
			if right_arm: right_arm.rotation.z = -0.4
		CustomerMood.ANGRY:
			visual.position.x = sin(anim_time * 25.0) * 0.03
			visual.position.y = abs(sin(anim_time * 12.0)) * 0.08
		CustomerMood.CELEBRATING:
			visual.position.y = abs(sin(anim_time * 10.0)) * 0.15
			if left_arm: left_arm.rotation.z = 2.4
			if right_arm: right_arm.rotation.z = -2.4

func _update_speech_bubble() -> void:
	if not speech_bubble:
		return

	if patience_bar:
		var pct = clampf(current_patience / max_patience, 0.0, 1.0)
		var bars = int(pct * 10)
		patience_bar.text = "⏱️ " + "■".repeat(bars) + "□".repeat(10 - bars)
		if pct > 0.6:
			patience_bar.modulate = Color(0.2, 0.9, 0.3)
		elif pct > 0.25:
			patience_bar.modulate = Color(0.95, 0.75, 0.1)
		else:
			patience_bar.modulate = Color(0.95, 0.2, 0.2)

	match mood:
		CustomerMood.HAPPY:
			speech_bubble.text = "😋 Quero lanche!" if not is_vip else "⭐ VIP aqui!"
			speech_bubble.modulate = Color(0.2, 0.9, 0.4)
		CustomerMood.WAITING:
			speech_bubble.text = "⏳ Huuum..."
			speech_bubble.modulate = Color(1.0, 0.9, 0.2)
		CustomerMood.IMPATIENT:
			speech_bubble.text = "😤 Vai demorar?!"
			speech_bubble.modulate = Color(1.0, 0.5, 0.1)
		CustomerMood.ANGRY:
			speech_bubble.text = "😡 QUE DEMORA!"
			speech_bubble.modulate = Color(1.0, 0.15, 0.15)
		CustomerMood.CELEBRATING:
			speech_bubble.text = "🎉 DELÍCIA! OBRIGADO!"
			speech_bubble.modulate = Color(0.1, 1.0, 0.5)

func receive_order(is_correct: bool) -> void:
	is_active = false
	if is_correct:
		mood = CustomerMood.CELEBRATING
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("cheer")
		var tw = create_tween()
		tw.tween_interval(0.8)
		tw.tween_property(self, "position:x", position.x + 3.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			customer_served.emit(self, true)
			queue_free()
		)
	else:
		mood = CustomerMood.ANGRY
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("error")
		var tw = create_tween()
		tw.tween_property(self, "position:z", position.z + 0.3, 0.15).set_trans(Tween.TRANS_BOUNCE)
		tw.tween_interval(0.4)
		tw.tween_callback(func():
			is_active = true
		)

func _play_leave_angry() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("error")
	var tw = create_tween()
	tw.tween_property(self, "position:x", position.x - 3.5, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		patience_depleted.emit(self)
		queue_free()
	)
