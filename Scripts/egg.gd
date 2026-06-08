extends Area2D

@export var fall_speed: float = 250.0
@export_enum("normal", "golden") var item_kind: String = "normal"
@export var floor_y: float = 690.0

const NORMAL_EGG_REGION := Rect2(260, 80, 500, 600)
const GOLDEN_EGG_REGION := Rect2(840, 80, 500, 600)
const BROKEN_EGG_TEXTURE := preload("res://Assets/Effects/broken_egg.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var start_x: float
var fall_time: float = 0.0
var sway_offset: float
var rotation_speed: float
var has_start_position: bool = false
var is_breaking: bool = false

func _ready():
	add_to_group("egg")
	add_to_group("falling_items")
	sway_offset = randf() * TAU
	rotation_speed = randf_range(-3.5, 3.5)
	apply_item_kind()

func _process(delta):
	if is_breaking == true:
		return

	if has_start_position == false:
		start_x = position.x
		has_start_position = true

	fall_time += delta
	position.y += fall_speed * delta
	position.x = start_x + sin(fall_time * 4.0 + sway_offset) * 14.0
	rotation += rotation_speed * delta
	scale = Vector2.ONE * (1.0 + sin(fall_time * 7.0) * 0.04)

	if position.y >= floor_y:
		break_on_floor()

func apply_item_kind():
	if item_kind == "golden":
		add_to_group("golden_egg")
		sprite.region_rect = GOLDEN_EGG_REGION
	else:
		sprite.region_rect = NORMAL_EGG_REGION

func get_score_value() -> int:
	if item_kind == "golden":
		return 5

	return 1

func break_on_floor():
	is_breaking = true
	collision_shape.set_deferred("disabled", true)
	remove_from_group("falling_items")

	var player := get_tree().current_scene.get_node_or_null("Player")

	if player != null and player.has_method("add_score"):
		player.add_score(-1)

	play_sound("egg_break", 1.0)
	position.y = floor_y
	rotation = 0.0
	scale = Vector2.ONE
	sprite.texture = BROKEN_EGG_TEXTURE
	sprite.region_enabled = false
	sprite.scale = Vector2(0.06, 0.06)
	sprite.modulate = Color(1, 1, 1, 1)

	if item_kind == "golden":
		sprite.modulate = Color(1.15, 0.95, 0.45, 1)

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.075, 0.045), 0.08)
	tween.tween_property(sprite, "scale", Vector2(0.06, 0.06), 0.1)
	tween.tween_interval(0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)

	await tween.finished
	queue_free()

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	var sound_manager := get_tree().current_scene.get_node_or_null("SoundManager")

	if sound_manager != null and sound_manager.has_method("play_sfx"):
		sound_manager.play_sfx(sound_name, volume_db, pitch_scale)
