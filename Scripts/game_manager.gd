extends Node

@export var egg_scene: PackedScene
@export var poop_scene: PackedScene
@export var bug_scene: PackedScene

@export var spawn_time: float = 1.2
@export var min_spawn_time: float = 0.35
@export var bug_spawn_time: float = 10.0
@export var spawn_acceleration: float = 0.025
@export var egg_speed_acceleration: float = 6.0
@export var poop_speed_acceleration: float = 7.0
@export var bug_speed_acceleration: float = 4.0
@export var normal_egg_chance: int = 67
@export var golden_egg_chance: int = 8
@export var golden_poop_chance: int = 3

@onready var high_score_label: Label = $"../UI/HighScoreLabel"
@onready var result_label: Label = $"../UI/ResultLabel"
@onready var start_button: TextureButton = $"../UI/StartButton"
@onready var restart_button: TextureButton = $"../UI/RestartButton"
@onready var logo_image: TextureRect = $"../UI/LogoImage"
@onready var control_pad: Control = $"../UI/ControlPad"
@onready var player = $"../Player"
@onready var sound_manager: Node = $"../SoundManager"

@onready var birds = [
	$"../Bird1",
	$"../Bird2",
	$"../Bird3",
	$"../Bird4"
]

var high_score: int = 0
var game_elapsed_time: float = 0.0
var game_started: bool = false
var game_over: bool = false
var world_left: float = 80.0
var world_right: float = 1200.0
var floor_y: float = 690.0

func _ready():
	randomize()

	high_score = load_high_score()
	update_high_score_ui()
	result_label.text = ""

	restart_button.visible = false
	start_button.visible = true
	logo_image.visible = true
	control_pad.visible = false

	player.can_play = false
	player.score_changed.connect(_on_player_score_changed)
	player.instant_game_over_requested.connect(_on_instant_game_over_requested)

	start_button.pressed.connect(start_game)
	restart_button.pressed.connect(restart_game)

func start_game():
	play_sound("button_tap")
	game_started = true
	game_over = false
	game_elapsed_time = 0.0

	result_label.text = ""
	start_button.visible = false
	restart_button.visible = false
	logo_image.visible = false
	control_pad.visible = true

	player.can_play = true
	player.set_physics_process(true)
	player.reset_player()

	spawn_loop()
	bug_spawn_loop()

func _process(delta):
	if game_started == true and game_over == false:
		game_elapsed_time += delta

func spawn_loop():
	while game_started == true and game_over == false:
		await get_tree().create_timer(get_current_spawn_time()).timeout

		if game_started == true and game_over == false:
			await spawn_random_item()

func bug_spawn_loop():
	while game_started == true and game_over == false:
		await get_tree().create_timer(get_current_bug_spawn_time()).timeout

		if game_started == true and game_over == false:
			spawn_bug()

func spawn_random_item():
	var selected_bird = birds.pick_random()

	if selected_bird.has_method("play_drop_animation"):
		await selected_bird.play_drop_animation()

	var item
	var random_number = randi_range(1, 100)
	var golden_poop_limit := golden_poop_chance
	var golden_egg_limit := golden_poop_limit + golden_egg_chance
	var normal_egg_limit := golden_egg_limit + normal_egg_chance

	if random_number <= golden_poop_limit:
		item = poop_scene.instantiate()
		item.item_kind = "golden"
		item.fall_speed = 300.0 + game_elapsed_time * poop_speed_acceleration
	elif random_number <= golden_egg_limit:
		item = egg_scene.instantiate()
		item.item_kind = "golden"
		item.fall_speed = 250.0 + game_elapsed_time * egg_speed_acceleration
	elif random_number <= normal_egg_limit:
		item = egg_scene.instantiate()
		item.item_kind = "normal"
		item.fall_speed = 250.0 + game_elapsed_time * egg_speed_acceleration
	else:
		item = poop_scene.instantiate()
		item.item_kind = "normal"
		item.fall_speed = 300.0 + game_elapsed_time * poop_speed_acceleration

	get_tree().current_scene.add_child(item)
	item.global_position = selected_bird.get_node("DropPoint").global_position

	item.set("floor_y", floor_y)

func get_current_spawn_time() -> float:
	return max(min_spawn_time, spawn_time - game_elapsed_time * spawn_acceleration)

func get_current_bug_spawn_time() -> float:
	return bug_spawn_time

func spawn_bug():
	if bug_scene == null:
		return

	var bug = bug_scene.instantiate()
	var from_left := randf() < 0.5
	var bug_ground_y: float = player.ground_y + 36.0
	var bug_margin := 90.0

	if from_left == true:
		bug.position = Vector2(world_left - bug_margin, bug_ground_y)
		bug.direction = 1
	else:
		bug.position = Vector2(world_right + bug_margin, bug_ground_y)
		bug.direction = -1

	bug.move_speed = 210.0 + game_elapsed_time * bug_speed_acceleration + randf_range(-25.0, 35.0)
	if bug.has_method("set_world_bounds"):
		bug.set_world_bounds(world_left - bug_margin, world_right + bug_margin)
	get_tree().current_scene.add_child(bug)

func set_world_bounds(left: float, right: float, new_floor_y: float):
	world_left = left
	world_right = right
	floor_y = new_floor_y

func end_game():
	game_over = true
	game_started = false

	get_tree().call_group("falling_items", "queue_free")
	get_tree().call_group("bugs", "queue_free")

	result_label.text = "Your Best: " + str(high_score) + "\nGAME OVER!"
	play_sound("game_over")
	player.play_lose_animation()

	restart_button.visible = true
	control_pad.visible = false

func _on_player_score_changed(new_score: int):
	if new_score > high_score:
		high_score = new_score
		save_high_score()
		update_high_score_ui()

	if game_started == true and game_over == false and new_score < 0:
		end_game()

func _on_instant_game_over_requested():
	if game_started == true and game_over == false:
		end_game()

func restart_game():
	play_sound("button_tap")
	get_tree().reload_current_scene()

func update_high_score_ui():
	high_score_label.text = "Best: " + str(high_score)

func load_high_score() -> int:
	if FileAccess.file_exists("user://high_score.save") == false:
		return 0

	var file := FileAccess.open("user://high_score.save", FileAccess.READ)
	return file.get_as_text().to_int()

func save_high_score():
	var file := FileAccess.open("user://high_score.save", FileAccess.WRITE)
	file.store_string(str(high_score))

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if sound_manager != null and sound_manager.has_method("play_sfx"):
		sound_manager.play_sfx(sound_name, volume_db, pitch_scale)
