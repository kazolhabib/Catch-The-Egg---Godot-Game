extends CharacterBody2D

signal score_changed(new_score: int)

@export var speed: float = 550.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var basket_area: Area2D = $BasketArea
@onready var score_label: Label = get_tree().current_scene.get_node("UI/ScoreLabel")

var score: int = 0
var can_play: bool = true
var is_reacting: bool = false
var start_position: Vector2
var basket_start_position: Vector2
var basket_start_scale: Vector2

func _ready():
	start_position = position
	basket_start_position = basket_area.position
	basket_start_scale = basket_area.scale
	animated_sprite.play("idle")
	basket_area.area_entered.connect(_on_basket_area_entered)
	update_score_ui()

func _physics_process(_delta):
	if can_play == false:
		return

	var direction := 0.0

	if Input.is_action_pressed("ui_left"):
		direction -= 1.0

	if Input.is_action_pressed("ui_right"):
		direction += 1.0

	velocity.x = direction * speed
	velocity.y = 0

	move_and_slide()

	position.x = clamp(position.x, 80, 1200)

	if direction != 0:
		set_facing_left(direction < 0)

	if is_reacting == true:
		return

	if direction != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

func _on_basket_area_entered(area):
	if can_play == false:
		return

	if area.is_in_group("egg"):
		score += 1
		print("Egg caught! Score: ", score)
		play_reaction_animation("catch_egg")
		area.queue_free()
		update_score_ui()
		score_changed.emit(score)

	elif area.is_in_group("poop"):
		score -= 2
		print("Poop caught! Score: ", score)
		play_reaction_animation("catch_poop")
		area.queue_free()
		update_score_ui()
		score_changed.emit(score)

func update_score_ui():
	score_label.text = "Score: " + str(score)

func reset_player():
	score = 0
	can_play = true
	is_reacting = false
	velocity = Vector2.ZERO
	position = start_position
	set_facing_left(false)
	animated_sprite.play("idle")
	update_score_ui()

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
	velocity = Vector2.ZERO
	animated_sprite.play("win")
	set_physics_process(false)

func play_lose_animation():
	can_play = false
	is_reacting = false
	velocity = Vector2.ZERO
	animated_sprite.play("lose")
	set_physics_process(false)
