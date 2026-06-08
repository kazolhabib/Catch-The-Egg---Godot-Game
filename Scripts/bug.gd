extends Area2D

@export var move_speed: float = 220.0
@export var direction: int = -1

@onready var visual: Node2D = $Visual

var crawl_time: float = 0.0
var cleanup_left: float = -120.0
var cleanup_right: float = 1400.0

func _ready():
	add_to_group("bugs")
	body_entered.connect(_on_body_entered)

	if direction > 0:
		visual.scale.x = -abs(visual.scale.x)
	else:
		visual.scale.x = abs(visual.scale.x)

func _process(delta):
	crawl_time += delta
	position.x += move_speed * direction * delta
	visual.position.y = sin(crawl_time * 16.0) * 2.0
	visual.rotation = sin(crawl_time * 10.0) * 0.06

	if position.x < cleanup_left or position.x > cleanup_right:
		queue_free()

func _on_body_entered(body):
	if body.has_method("get_hurt_by_bug"):
		body.get_hurt_by_bug()
		queue_free()

func set_world_bounds(left: float, right: float):
	cleanup_left = left
	cleanup_right = right
