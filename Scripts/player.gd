extends CharacterBody2D

signal score_changed(new_score: int)
signal instant_game_over_requested

@export var speed: float = 550.0
@export var jump_velocity: float = -760.0
@export var gravity: float = 2200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var basket_area: Area2D = $BasketArea
@onready var hurt_area: Area2D = $HurtArea
@onready var score_label: Label = get_tree().current_scene.get_node_or_null("UI/ScoreLabel") as Label
@onready var left_button: TextureButton = get_tree().current_scene.get_node_or_null("UI/ControlPad/LeftButton") as TextureButton
@onready var right_button: TextureButton = get_tree().current_scene.get_node_or_null("UI/ControlPad/RightButton") as TextureButton
@onready var jump_button: TextureButton = get_tree().current_scene.get_node_or_null("UI/ControlPad/JumpButton") as TextureButton
@onready var sound_manager: Node = get_tree().current_scene.get_node_or_null("SoundManager")

var score: int = 0
var can_play: bool = true
var is_reacting: bool = false
var is_hurt: bool = false
var start_position: Vector2
var ground_y: float
var play_min_x: float = 80.0
var play_max_x: float = 1200.0
var basket_start_position: Vector2
var basket_start_scale: Vector2
var sprite_start_position: Vector2
var sprite_start_rotation: float
var mobile_left_pressed: bool = false
var mobile_right_pressed: bool = false
var mobile_jump_requested: bool = false
var run_motion_time: float = 0.0
var vertical_velocity: float = 0.0

func _ready():
	start_position = position
	ground_y = start_position.y
	basket_start_position = basket_area.position
	basket_start_scale = basket_area.scale
	sprite_start_position = animated_sprite.position
	sprite_start_rotation = animated_sprite.rotation
	animated_sprite.play("idle")
	basket_area.area_entered.connect(_on_basket_area_entered)
	hurt_area.area_entered.connect(_on_hurt_area_entered)
	connect_mobile_controls()
	update_score_ui()

func _physics_process(delta):
	if can_play == false:
		return

	var direction := get_move_direction()

	if should_jump() == true:
		vertical_velocity = jump_velocity
		play_sound("jump", 0.0)

	vertical_velocity += gravity * delta
	velocity.x = direction * speed
	velocity.y = vertical_velocity

	move_and_slide()

	position.x = clamp(position.x, play_min_x, play_max_x)

	if position.y >= ground_y:
		position.y = ground_y
		vertical_velocity = 0.0

	if direction != 0:
		set_facing_left(direction < 0)

	if is_reacting == true:
		return

	if is_jumping() == true:
		animated_sprite.play("idle")
		reset_run_motion(delta)
	elif direction != 0:
		animated_sprite.play("run")
		animate_run_motion(delta)
	else:
		animated_sprite.play("idle")
		reset_run_motion(delta)

func _on_basket_area_entered(area):
	if can_play == false:
		return

	if area.is_in_group("egg"):
		var score_value := 1

		if area.has_method("get_score_value"):
			score_value = area.get_score_value()

		add_score(score_value)
		print("Egg caught! Score: ", score)
		if area.is_in_group("golden_egg"):
			play_sound("catch_golden", 1.0)
		else:
			play_sound("catch_egg", 1.0)
		play_reaction_animation("catch_egg")
		area.queue_free()

	elif area.is_in_group("poop"):
		if area.has_method("is_instant_game_over") and area.is_instant_game_over() == true:
			print("Golden poop caught! Game over.")
			play_sound("catch_poop", 1.0)
			play_reaction_animation("catch_poop")
			area.queue_free()
			instant_game_over_requested.emit()
			return

		add_score(-2)
		print("Poop caught! Score: ", score)
		play_sound("catch_poop", 1.0)
		play_reaction_animation("catch_poop")
		area.queue_free()

func _on_hurt_area_entered(area):
	if area.is_in_group("bugs") == false:
		return

	get_hurt_by_bug()
	area.queue_free()

func update_score_ui():
	if score_label == null:
		return

	score_label.text = "Score: " + str(score)

func add_score(amount: int):
	score += amount
	update_score_ui()
	score_changed.emit(score)

func reset_player():
	score = 0
	can_play = true
	is_reacting = false
	is_hurt = false
	mobile_left_pressed = false
	mobile_right_pressed = false
	mobile_jump_requested = false
	run_motion_time = 0.0
	vertical_velocity = 0.0
	velocity = Vector2.ZERO
	position = start_position
	animated_sprite.position = sprite_start_position
	animated_sprite.rotation = sprite_start_rotation
	set_facing_left(false)
	animated_sprite.play("idle")
	update_score_ui()

func set_play_area(left: float, right: float, new_ground_y: float, start_x: float):
	play_min_x = left
	play_max_x = right
	ground_y = new_ground_y
	start_position = Vector2(start_x, new_ground_y)
	position.x = clamp(position.x, play_min_x, play_max_x)

	if position.y > ground_y or can_play == false:
		position.y = ground_y

func set_facing_left(facing_left: bool):
	animated_sprite.flip_h = facing_left

	if facing_left == true:
		basket_area.position.x = -basket_start_position.x
		basket_area.scale.x = -basket_start_scale.x
	else:
		basket_area.position.x = basket_start_position.x
		basket_area.scale.x = basket_start_scale.x

func play_reaction_animation(animation_name: String):
	is_reacting = true
	animated_sprite.play(animation_name)

	await get_tree().create_timer(0.35).timeout

	is_reacting = false

func play_win_animation():
	can_play = false
	is_reacting = false
	mobile_left_pressed = false
	mobile_right_pressed = false
	mobile_jump_requested = false
	animated_sprite.position = sprite_start_position
	animated_sprite.rotation = sprite_start_rotation
	velocity = Vector2.ZERO
	animated_sprite.play("win")
	set_physics_process(false)

func play_lose_animation():
	can_play = false
	is_reacting = false
	mobile_left_pressed = false
	mobile_right_pressed = false
	mobile_jump_requested = false
	animated_sprite.position = sprite_start_position
	animated_sprite.rotation = sprite_start_rotation
	velocity = Vector2.ZERO
	animated_sprite.play("lose")
	set_physics_process(false)

func connect_mobile_controls():
	if left_button != null:
		left_button.button_down.connect(_on_left_button_down)
		left_button.button_up.connect(_on_left_button_up)

	if right_button != null:
		right_button.button_down.connect(_on_right_button_down)
		right_button.button_up.connect(_on_right_button_up)

	if jump_button != null:
		jump_button.button_down.connect(_on_jump_button_down)

func get_move_direction() -> float:
	var direction := 0.0

	if Input.is_action_pressed("ui_left") or mobile_left_pressed == true:
		direction -= 1.0

	if Input.is_action_pressed("ui_right") or mobile_right_pressed == true:
		direction += 1.0

	return direction

func should_jump() -> bool:
	var keyboard_jump := Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept")
	var jump_requested := (keyboard_jump == true or mobile_jump_requested == true) and is_on_jump_ground() == true
	mobile_jump_requested = false
	return jump_requested

func is_on_jump_ground() -> bool:
	return position.y >= ground_y - 0.5 and vertical_velocity >= 0.0

func is_jumping() -> bool:
	return is_on_jump_ground() == false

func get_hurt_by_bug():
	if can_play == false or is_hurt == true:
		return

	is_hurt = true
	can_play = false
	is_reacting = false
	mobile_left_pressed = false
	mobile_right_pressed = false
	mobile_jump_requested = false
	vertical_velocity = 0.0
	velocity = Vector2.ZERO
	position.y = ground_y
	play_sound("hurt", 1.0)
	animated_sprite.play("lose")

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(animated_sprite, "rotation", sprite_start_rotation + 1.5708, 0.12)
	tween.tween_property(animated_sprite, "position", sprite_start_position + Vector2(28, 44), 0.12)

	await get_tree().create_timer(1.0).timeout

	if is_game_over_active() == true:
		return

	var recover_tween := create_tween()
	recover_tween.set_parallel(true)
	recover_tween.tween_property(animated_sprite, "rotation", sprite_start_rotation, 0.12)
	recover_tween.tween_property(animated_sprite, "position", sprite_start_position, 0.12)
	await recover_tween.finished

	is_hurt = false
	can_play = true
	animated_sprite.play("idle")

func is_game_over_active() -> bool:
	var game_manager := get_tree().current_scene.get_node_or_null("GameManager")
	return game_manager != null and game_manager.game_over == true

func _on_left_button_down():
	mobile_left_pressed = true

func _on_left_button_up():
	mobile_left_pressed = false

func _on_right_button_down():
	mobile_right_pressed = true

func _on_right_button_up():
	mobile_right_pressed = false

func _on_jump_button_down():
	mobile_jump_requested = true

func animate_run_motion(delta):
	run_motion_time += delta * 14.0
	animated_sprite.position = sprite_start_position + Vector2(0, sin(run_motion_time) * 4.0)
	animated_sprite.rotation = sprite_start_rotation + sin(run_motion_time * 0.5) * 0.035

func reset_run_motion(delta):
	run_motion_time = 0.0
	animated_sprite.position = animated_sprite.position.lerp(sprite_start_position, min(delta * 12.0, 1.0))
	animated_sprite.rotation = lerp(animated_sprite.rotation, sprite_start_rotation, min(delta * 12.0, 1.0))

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if sound_manager != null and sound_manager.has_method("play_sfx"):
		sound_manager.play_sfx(sound_name, volume_db, pitch_scale)
