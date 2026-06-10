extends Area2D

const BUG_RUNNING_STREAM := preload("res://Assets/Audio/bug-running-sound.mp3")

@export var move_speed: float = 220.0
@export var direction: int = -1

@onready var visual: Node2D = $Visual
@onready var body: Polygon2D = $Visual/Body
@onready var shell: Polygon2D = $Visual/Shell
@onready var head: Polygon2D = $Visual/Head
@onready var spot_1: Polygon2D = $Visual/Spot1
@onready var spot_2: Polygon2D = $Visual/Spot2
@onready var eye_white: Polygon2D = $Visual/EyeWhite
@onready var leg_1: Line2D = $Visual/Leg1
@onready var leg_2: Line2D = $Visual/Leg2
@onready var leg_3: Line2D = $Visual/Leg3

var crawl_time: float = 0.0
var cleanup_left: float = -120.0
var cleanup_right: float = 1400.0
var crawl_bob_speed: float = 16.0
var crawl_wiggle_speed: float = 10.0
var running_sound_player: AudioStreamPlayer2D

func _ready():
	add_to_group("bugs")
	body_entered.connect(_on_body_entered)
	apply_random_variant()
	start_running_sound()

	if direction > 0:
		visual.scale.x = -abs(visual.scale.x)
	else:
		visual.scale.x = abs(visual.scale.x)

func _process(delta):
	crawl_time += delta
	position.x += move_speed * direction * delta
	visual.position.y = sin(crawl_time * crawl_bob_speed) * 2.0
	visual.rotation = sin(crawl_time * crawl_wiggle_speed) * 0.06

	if position.x < cleanup_left or position.x > cleanup_right:
		queue_free()

func start_running_sound():
	if BUG_RUNNING_STREAM == null:
		return

	running_sound_player = AudioStreamPlayer2D.new()
	running_sound_player.stream = BUG_RUNNING_STREAM
	running_sound_player.volume_db = -15.0
	running_sound_player.pitch_scale = randf_range(0.92, 1.08)
	running_sound_player.max_distance = 620.0
	running_sound_player.finished.connect(_on_running_sound_finished)
	add_child(running_sound_player)
	running_sound_player.play()

func _on_running_sound_finished():
	if is_inside_tree() == true and running_sound_player != null:
		running_sound_player.play()

func _on_body_entered(body):
	if body.has_method("get_hurt_by_bug"):
		body.get_hurt_by_bug()
		queue_free()

func set_world_bounds(left: float, right: float):
	cleanup_left = left
	cleanup_right = right

func apply_random_variant():
	var variants := [
		{
			"shell": Color(0.72, 0.12, 0.06, 1.0),
			"body": Color(0.16, 0.08, 0.04, 1.0),
			"spot": Color(0.05, 0.02, 0.01, 1.0),
			"scale": Vector2(1.0, 1.0),
			"speed": 1.0,
			"extra": "spots"
		},
		{
			"shell": Color(0.14, 0.54, 0.18, 1.0),
			"body": Color(0.08, 0.24, 0.07, 1.0),
			"spot": Color(0.90, 0.92, 0.20, 1.0),
			"scale": Vector2(0.92, 1.10),
			"speed": 1.18,
			"extra": "antenna"
		},
		{
			"shell": Color(0.18, 0.36, 0.86, 1.0),
			"body": Color(0.06, 0.11, 0.26, 1.0),
			"spot": Color(0.63, 0.88, 1.0, 1.0),
			"scale": Vector2(1.10, 0.88),
			"speed": 1.32,
			"extra": "wings"
		},
		{
			"shell": Color(0.42, 0.18, 0.76, 1.0),
			"body": Color(0.14, 0.06, 0.24, 1.0),
			"spot": Color(1.0, 0.72, 0.24, 1.0),
			"scale": Vector2(0.84, 0.84),
			"speed": 1.48,
			"extra": "small"
		},
		{
			"shell": Color(0.86, 0.48, 0.10, 1.0),
			"body": Color(0.22, 0.10, 0.04, 1.0),
			"spot": Color(0.18, 0.08, 0.03, 1.0),
			"scale": Vector2(1.22, 1.0),
			"speed": 0.88,
			"extra": "stripes"
		},
	]
	var variant: Dictionary = variants.pick_random()

	body.color = variant.body
	shell.color = variant.shell
	head.color = variant.body.darkened(0.15)
	spot_1.color = variant.spot
	spot_2.color = variant.spot
	visual.scale = variant.scale
	move_speed *= variant.speed
	crawl_bob_speed = randf_range(13.0, 19.0) * variant.speed
	crawl_wiggle_speed = randf_range(8.0, 13.0) * variant.speed

	var leg_color: Color = variant.body.darkened(0.35)
	for leg in [leg_1, leg_2, leg_3]:
		leg.default_color = leg_color
		leg.width = randf_range(4.0, 6.5)

	apply_variant_extra(variant.extra)

func apply_variant_extra(extra: String):
	match extra:
		"antenna":
			add_antenna()
		"wings":
			add_wings()
		"small":
			eye_white.scale = Vector2.ONE * 1.18
		"stripes":
			spot_1.polygon = PackedVector2Array([Vector2(-20, -15), Vector2(-12, -17), Vector2(-4, 16), Vector2(-12, 17)])
			spot_2.polygon = PackedVector2Array([Vector2(4, -17), Vector2(12, -15), Vector2(20, 13), Vector2(12, 16)])

func add_antenna():
	for points in [
		PackedVector2Array([Vector2(31, -9), Vector2(43, -22), Vector2(50, -19)]),
		PackedVector2Array([Vector2(37, 3), Vector2(52, -2), Vector2(56, 4)]),
	]:
		var antenna := Line2D.new()
		antenna.points = points
		antenna.width = 3.0
		antenna.default_color = head.color
		visual.add_child(antenna)

func add_wings():
	var wing := Polygon2D.new()
	wing.color = Color(0.78, 0.95, 1.0, 0.42)
	wing.polygon = PackedVector2Array([Vector2(-12, -20), Vector2(8, -32), Vector2(28, -13), Vector2(14, 7)])
	visual.add_child(wing)
	visual.move_child(wing, 2)
