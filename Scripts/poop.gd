extends Area2D

@export var fall_speed: float = 300.0
@export_enum("normal", "golden") var item_kind: String = "normal"
@export var floor_y: float = 690.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var start_x: float
var fall_time: float = 0.0
var sway_offset: float
var rotation_speed: float
var has_start_position: bool = false
var is_splatting: bool = false

func _ready():
	add_to_group("poop")
	add_to_group("falling_items")
	sway_offset = randf() * TAU
	rotation_speed = randf_range(-5.5, 5.5)
	apply_item_kind()

func _process(delta):
	if is_splatting == true:
		return

	if has_start_position == false:
		start_x = position.x
		has_start_position = true

	fall_time += delta
	position.y += fall_speed * delta
	position.x = start_x + sin(fall_time * 5.0 + sway_offset) * 18.0
	rotation += rotation_speed * delta
	scale = Vector2.ONE * (1.0 + sin(fall_time * 8.0) * 0.05)

	if position.y >= floor_y:
		splat_on_floor()

func apply_item_kind():
	if item_kind == "golden":
		add_to_group("golden_poop")
		sprite.modulate = Color(1.35, 0.95, 0.25, 1.0)
		sprite.scale = Vector2(0.135, 0.135)
	else:
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.scale = Vector2(0.12, 0.12)

func is_instant_game_over() -> bool:
	return item_kind == "golden"

func splat_on_floor():
	is_splatting = true
	collision_shape.set_deferred("disabled", true)
	remove_from_group("falling_items")
	remove_from_group("poop")
	remove_from_group("golden_poop")

	play_sound("poop_splat", 1.0)
	position.y = floor_y
	rotation = 0.0
	scale = Vector2.ONE
	sprite.visible = false

	var splat_pieces := create_splat_pieces()
	var tween := create_tween()
	tween.set_parallel(true)

	for index in splat_pieces.size():
		var piece := splat_pieces[index] as Sprite2D
		var spread := get_splat_spread(index)
		var target_scale := get_splat_scale(index)

		piece.position = Vector2(0, -8)
		piece.rotation = randf_range(-0.25, 0.25)
		piece.scale = target_scale * 0.45
		tween.tween_property(piece, "position", spread, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "scale", target_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "rotation", piece.rotation + randf_range(-0.45, 0.45), 0.14)
		tween.tween_property(piece, "modulate:a", 0.0, 0.35).set_delay(0.45)

	await tween.finished
	queue_free()

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	var sound_manager := get_tree().current_scene.get_node_or_null("SoundManager")

	if sound_manager != null and sound_manager.has_method("play_sfx"):
		sound_manager.play_sfx(sound_name, volume_db, pitch_scale)

func create_splat_pieces() -> Array[Sprite2D]:
	var pieces: Array[Sprite2D] = []
	var piece_count := 7

	for index in piece_count:
		var piece := Sprite2D.new()
		piece.texture = sprite.texture
		piece.region_enabled = sprite.region_enabled
		piece.region_rect = sprite.region_rect
		piece.centered = true
		piece.z_index = sprite.z_index
		piece.modulate = get_splat_color(index)
		add_child(piece)
		pieces.append(piece)

	return pieces

func get_splat_spread(index: int) -> Vector2:
	var spreads := [
		Vector2(0, 4),
		Vector2(-30, 6),
		Vector2(28, 7),
		Vector2(-16, 15),
		Vector2(18, 14),
		Vector2(-42, 18),
		Vector2(42, 17),
	]

	return spreads[index]

func get_splat_scale(index: int) -> Vector2:
	var scales := [
		Vector2(0.11, 0.035),
		Vector2(0.065, 0.024),
		Vector2(0.06, 0.023),
		Vector2(0.048, 0.02),
		Vector2(0.046, 0.019),
		Vector2(0.034, 0.016),
		Vector2(0.032, 0.015),
	]

	return scales[index]

func get_splat_color(index: int) -> Color:
	if item_kind == "golden":
		return Color(1.35, 0.95, 0.25, 1.0)

	var shade := 1.0 - float(index % 3) * 0.08
	return Color(0.34 * shade, 0.18 * shade, 0.08 * shade, 1.0)
