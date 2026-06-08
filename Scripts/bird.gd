extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var start_position: Vector2
var start_rotation: float
var idle_time: float = 0.0
var is_tossing: bool = false

func _ready():
	start_position = position
	start_rotation = rotation
	idle_time = randf() * TAU
	set_process(true)

func _process(delta):
	if is_tossing == true:
		return

	idle_time += delta
	position.y = start_position.y + sin(idle_time * 2.0) * 2.0
	rotation = start_rotation + sin(idle_time * 1.4) * 0.025

	if randf() < delta * 0.45:
		chirp()

func chirp():
	if is_tossing == true:
		return

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.32, 0.28), 0.08)
	tween.tween_property(sprite, "scale", Vector2(0.3, 0.3), 0.1)

func play_drop_animation():
	is_tossing = true
	sprite.flip_h = true
	play_sound("bird_drop", -2.0, randf_range(0.92, 1.08))

	var tween := create_tween()
	tween.tween_property(self, "rotation", start_rotation - 0.18, 0.12)
	tween.parallel().tween_property(self, "position:y", start_position.y + 6.0, 0.12)
	tween.tween_property(self, "rotation", start_rotation, 0.14)
	tween.parallel().tween_property(self, "position:y", start_position.y, 0.14)

	await tween.finished
	sprite.flip_h = false
	is_tossing = false

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	var sound_manager := get_tree().current_scene.get_node_or_null("SoundManager")

	if sound_manager != null and sound_manager.has_method("play_sfx"):
		sound_manager.play_sfx(sound_name, volume_db, pitch_scale)
