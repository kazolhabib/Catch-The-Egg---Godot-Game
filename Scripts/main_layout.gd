extends Node2D

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const SAFE_MARGIN := 28.0
const PLAYER_EDGE_PADDING := 92.0
const PLAYER_BOTTOM_OFFSET := 140.0
const FLOOR_OFFSET_FROM_GROUND := 110.0
const MAX_BIRD_BAND_WIDTH := 820.0
const LEFT_BIRD_EXTRA_SHIFT := 42.0
const TOUCH_HIT_PADDING := 46.0

@onready var sky: Sprite2D = $Sky
@onready var background: Sprite2D = $Background
@onready var tree: Sprite2D = $Tree
@onready var player = $Player
@onready var birds: Array[Node2D] = [$Bird1, $Bird2, $Bird3, $Bird4]
@onready var game_manager = $GameManager
@onready var score_board: TextureRect = $UI/ScoreBoard
@onready var score_label: Label = $UI/ScoreLabel
@onready var high_score_board: TextureRect = $UI/HighScoreBoard
@onready var high_score_label: Label = $UI/HighScoreLabel
@onready var logo_image: TextureRect = $UI/LogoImage
@onready var start_button: TextureButton = $UI/StartButton
@onready var restart_button: TextureButton = $UI/RestartButton
@onready var result_label: Label = $UI/ResultLabel
@onready var control_pad: Control = $UI/ControlPad
@onready var left_button: TextureButton = $UI/ControlPad/LeftButton
@onready var right_button: TextureButton = $UI/ControlPad/RightButton
@onready var jump_button: TextureButton = $UI/ControlPad/JumpButton

var last_viewport_size := Vector2.ZERO
var active_touch_zones: Dictionary = {}

func _ready():
	get_viewport().size_changed.connect(apply_responsive_layout)
	call_deferred("apply_responsive_layout")

func apply_responsive_layout():
	var viewport_size := get_viewport_rect().size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	last_viewport_size = viewport_size

	layout_world(viewport_size)
	layout_ui(viewport_size)

func layout_world(viewport_size: Vector2):
	var center := viewport_size * 0.5
	fit_sprite_to_cover(sky, viewport_size)
	fit_sprite_to_cover(background, viewport_size)

	tree.position = Vector2(center.x + viewport_size.x * 0.06, viewport_size.y * 0.26)
	tree.scale = Vector2.ONE * clamp(viewport_size.y / DESIGN_SIZE.y * 0.82, 0.72, 1.05)

	var ground_y := viewport_size.y - PLAYER_BOTTOM_OFFSET
	var play_min_x := SAFE_MARGIN + PLAYER_EDGE_PADDING
	var play_max_x := viewport_size.x - SAFE_MARGIN - PLAYER_EDGE_PADDING
	var player_start_x := center.x

	if player != null and player.has_method("set_play_area"):
		player.set_play_area(play_min_x, play_max_x, ground_y, player_start_x)

	if game_manager != null and game_manager.has_method("set_world_bounds"):
		game_manager.set_world_bounds(play_min_x, play_max_x, ground_y + FLOOR_OFFSET_FROM_GROUND)

	layout_birds(viewport_size)

func fit_sprite_to_cover(sprite: Sprite2D, viewport_size: Vector2):
	if sprite == null or sprite.texture == null:
		return

	var texture_size: Vector2 = sprite.texture.get_size()

	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var cover_scale: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	sprite.position = viewport_size * 0.5
	sprite.scale = Vector2.ONE * cover_scale

func layout_birds(viewport_size: Vector2):
	var top_y: float = clamp(viewport_size.y * 0.15, 84.0, 130.0)
	var usable_width: float = max(viewport_size.x - SAFE_MARGIN * 2.0, 1.0)
	var bird_band_width: float = min(usable_width, clamp(viewport_size.x * 0.62, 560.0, MAX_BIRD_BAND_WIDTH))
	var band_left: float = (viewport_size.x - bird_band_width) * 0.5

	for index in birds.size():
		var bird: Node2D = birds[index]
		var spacing: float = bird_band_width / float(birds.size() + 1)
		var bird_x: float = band_left + spacing * float(index + 1)

		if index == 0:
			bird_x -= min(LEFT_BIRD_EXTRA_SHIFT, max(band_left - SAFE_MARGIN, 0.0))

		bird.position = Vector2(bird_x, top_y + sin(float(index) * 1.7) * 8.0)
		bird.scale = Vector2.ONE * clamp(viewport_size.y / DESIGN_SIZE.y * 0.85, 0.72, 0.95)

func layout_ui(viewport_size: Vector2):
	control_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	control_pad.offset_left = 0.0
	control_pad.offset_top = 0.0
	control_pad.offset_right = 0.0
	control_pad.offset_bottom = 0.0

	var safe: Vector2 = get_safe_margin(viewport_size)
	var score_size := Vector2(clamp(viewport_size.x * 0.22, 220.0, 290.0), 96.0)
	var score_x: float = viewport_size.x - safe.x - score_size.x

	place_control(high_score_board, Vector2(score_x, safe.y - 12.0), score_size)
	place_control(high_score_label, Vector2(score_x + 4.0, safe.y - 14.0), score_size + Vector2(-8.0, 28.0))
	place_control(score_board, Vector2(score_x, safe.y + 74.0), score_size)
	place_control(score_label, Vector2(score_x + 4.0, safe.y + 72.0), score_size + Vector2(-8.0, 28.0))

	high_score_label.add_theme_font_size_override("font_size", int(clamp(viewport_size.x * 0.025, 25.0, 32.0)))
	score_label.add_theme_font_size_override("font_size", int(clamp(viewport_size.x * 0.027, 27.0, 35.0)))

	var logo_width: float = clamp(viewport_size.x * 0.42, 360.0, 500.0)
	var logo_size := Vector2(logo_width, logo_width * 0.46)
	place_control(logo_image, Vector2((viewport_size.x - logo_size.x) * 0.5, viewport_size.y * 0.2), logo_size)

	var action_size: Vector2 = Vector2.ONE * clamp(viewport_size.y * 0.25, 170.0, 220.0)
	var action_pos := Vector2((viewport_size.x - action_size.x) * 0.5, viewport_size.y * 0.50)
	place_button(start_button, action_pos, action_size, 0.0)
	place_button(restart_button, action_pos, action_size, 0.0)

	var result_size := Vector2(min(viewport_size.x - safe.x * 2.0, 620.0), 150.0)
	place_control(result_label, Vector2((viewport_size.x - result_size.x) * 0.5, viewport_size.y * 0.34), result_size)
	result_label.add_theme_font_size_override("font_size", int(clamp(viewport_size.x * 0.038, 34.0, 52.0)))

	var move_size: Vector2 = Vector2.ONE * clamp(viewport_size.y * 0.25, 170.0, 230.0)
	var move_gap: float = clamp(viewport_size.x * 0.024, 28.0, 44.0)
	var move_y: float = viewport_size.y - safe.y - move_size.y
	place_button(left_button, Vector2(safe.x + 12.0, move_y), move_size, PI)
	place_button(right_button, Vector2(safe.x + 12.0 + move_size.x + move_gap, move_y), move_size, 0.0)

	var jump_size: Vector2 = Vector2.ONE * clamp(viewport_size.y * 0.30, 210.0, 280.0)
	place_button(jump_button, Vector2(viewport_size.x - safe.x - jump_size.x - 12.0, viewport_size.y - safe.y - jump_size.y), jump_size, -PI * 0.5)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed == true:
			active_touch_zones[event.index] = get_touch_zone(event.position)
		else:
			active_touch_zones.erase(event.index)

		update_player_mobile_controls()
	elif event is InputEventScreenDrag:
		active_touch_zones[event.index] = get_touch_zone(event.position)
		update_player_mobile_controls()

func get_touch_zone(screen_position: Vector2) -> String:
	if control_pad.visible == false:
		return ""

	var zone: String = get_button_zone(screen_position)

	if zone != "":
		return zone

	return get_fallback_touch_zone(screen_position)

func get_button_zone(screen_position: Vector2) -> String:
	if get_button_hit_rect(left_button).has_point(screen_position) == true:
		return "left"

	if get_button_hit_rect(right_button).has_point(screen_position) == true:
		return "right"

	if get_button_hit_rect(jump_button).has_point(screen_position) == true:
		return "jump"

	return ""

func get_button_hit_rect(button: TextureButton) -> Rect2:
	return Rect2(button.position, button.size).grow(TOUCH_HIT_PADDING)

func get_fallback_touch_zone(screen_position: Vector2) -> String:
	var viewport_size := last_viewport_size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size

	if screen_position.y < viewport_size.y * 0.58:
		return ""

	if screen_position.x <= viewport_size.x * 0.20:
		return "left"

	if screen_position.x <= viewport_size.x * 0.42:
		return "right"

	if screen_position.x >= viewport_size.x * 0.66:
		return "jump"

	return ""

func update_player_mobile_controls():
	if player == null or player.has_method("set_mobile_controls") == false:
		return

	var left_pressed := false
	var right_pressed := false
	var jump_pressed := false

	for zone in active_touch_zones.values():
		if zone == "left":
			left_pressed = true
		elif zone == "right":
			right_pressed = true
		elif zone == "jump":
			jump_pressed = true

	player.set_mobile_controls(left_pressed, right_pressed, jump_pressed)

func place_control(control: Control, top_left: Vector2, size: Vector2):
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = top_left
	control.size = size

func place_button(button: TextureButton, top_left: Vector2, size: Vector2, angle: float):
	place_control(button, top_left, size)
	button.rotation = angle
	button.pivot_offset = size * 0.5

func get_safe_margin(viewport_size: Vector2) -> Vector2:
	var side_margin: float = clamp(viewport_size.x * 0.035, 24.0, 52.0)
	var vertical_margin: float = clamp(viewport_size.y * 0.045, 22.0, 42.0)
	return Vector2(side_margin, vertical_margin)
