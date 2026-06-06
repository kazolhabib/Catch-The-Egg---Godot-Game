extends Node

@export var egg_scene: PackedScene
@export var poop_scene: PackedScene

@export var spawn_time: float = 1.2
@export var game_time: int = 60
@export var win_score: int = 20

@onready var timer_label: Label = $"../UI/TimerLabel"
@onready var result_label: Label = $"../UI/ResultLabel"
@onready var start_button: TextureButton = $"../UI/StartButton"
@onready var restart_button: TextureButton = $"../UI/RestartButton"
@onready var logo_image: TextureRect = $"../UI/LogoImage"
@onready var player = $"../Player"

@onready var birds = [
	$"../Bird1",
	$"../Bird2",
	$"../Bird3",
	$"../Bird4"
]

var time_left: int
var game_started: bool = false
var game_over: bool = false

func _ready():
	randomize()

	time_left = game_time

	timer_label.text = "" + str(game_time)
	result_label.text = ""

	restart_button.visible = false
	start_button.visible = true
	logo_image.visible = true

	player.can_play = false
	player.score_changed.connect(_on_player_score_changed)

	start_button.pressed.connect(start_game)
	restart_button.pressed.connect(restart_game)

func start_game():
	game_started = true
	game_over = false
	time_left = game_time

	result_label.text = ""
	start_button.visible = false
	restart_button.visible = false
	logo_image.visible = false

	player.can_play = true
	player.set_physics_process(true)
	player.reset_player()

	update_timer_ui()

	spawn_loop()
	timer_loop()

func spawn_loop():
	while game_started == true and game_over == false:
		await get_tree().create_timer(spawn_time).timeout

		if game_started == true and game_over == false:
			spawn_random_item()

func timer_loop():
	while time_left > 0 and game_over == false:
		await get_tree().create_timer(1.0).timeout
		time_left -= 1
		update_timer_ui()

	if game_over == false:
		end_game()

func spawn_random_item():
	var selected_bird = birds.pick_random()

	var item
	var random_number = randi_range(1, 100)

	if random_number <= 75:
		item = egg_scene.instantiate()
	else:
		item = poop_scene.instantiate()

	get_tree().current_scene.add_child(item)
	item.global_position = selected_bird.global_position + Vector2(0, 55)

func update_timer_ui():
	timer_label.text = "" + str(time_left)

func end_game():
	game_over = true
	game_started = false

	get_tree().call_group("falling_items", "queue_free")

	if player.score >= win_score:
		result_label.text = "YOU WIN!"
		player.play_win_animation()
	else:
		result_label.text = "YOU LOSE!"
		player.play_lose_animation()

	restart_button.visible = true

func _on_player_score_changed(new_score: int):
	if game_started == true and game_over == false and new_score < 0:
		end_game()

func restart_game():
	get_tree().reload_current_scene()
