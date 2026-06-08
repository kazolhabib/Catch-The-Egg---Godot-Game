extends Node

@export var cloud_speed: float = 22.0
@export var cloud_wrap_left: float = -260.0
@export var cloud_wrap_right: float = 1540.0
@export var grass_sway_amount: float = 0.08

@onready var flora: Node2D = get_node_or_null("../Flora") as Node2D
@onready var clouds: Array[Sprite2D] = get_clouds()

var time_passed: float = 0.0

func _process(delta):
	time_passed += delta
	animate_grass()
	move_clouds(delta)

func get_clouds() -> Array[Sprite2D]:
	var cloud_nodes: Array[Sprite2D] = []
	var cloud_parent := get_node_or_null("../Clouds")

	if cloud_parent == null:
		return cloud_nodes

	for child in cloud_parent.get_children():
		var cloud := child as Sprite2D

		if cloud != null:
			cloud_nodes.append(cloud)

	return cloud_nodes

func animate_grass():
	if flora == null:
		return

	for child in flora.get_children():
		var sway_phase: float = float(child.get_meta("sway_phase", 0.0))
		var sway_speed: float = float(child.get_meta("sway_speed", 1.0))
		child.rotation = sin(time_passed * sway_speed + sway_phase) * grass_sway_amount
		child.scale.x = 1.0 + sin(time_passed * sway_speed + sway_phase) * 0.025

func move_clouds(delta):
	for cloud in clouds:
		var speed_scale: float = float(cloud.get_meta("speed_scale", 1.0))
		cloud.position.x -= cloud_speed * delta * speed_scale

		if cloud.position.x < cloud_wrap_left:
			cloud.position.x = cloud_wrap_right
