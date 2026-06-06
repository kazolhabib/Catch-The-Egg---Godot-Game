extends Area2D

@export var fall_speed: float = 300.0

func _ready():
	add_to_group("poop")
	add_to_group("falling_items")

func _process(delta):
	position.y += fall_speed * delta

	if position.y > 800:
		queue_free()
