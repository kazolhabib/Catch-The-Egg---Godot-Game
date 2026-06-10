extends Node

const SAMPLE_RATE := 44100
const MAX_PLAYERS_DESKTOP := 12
const MAX_PLAYERS_ANDROID := 4
const MASTER_GAIN := 1.0
const MUSIC_VOLUME_DB := -10.0
const SFX_VOLUME_OFFSET_DB := -5.0
const MUSIC_DURATION := 6.4
const EXTERNAL_SFX_PATHS := {
	"egg_break": "res://Assets/Audio/egg-crack.mp3",
	"poop_splat": "res://Assets/Audio/poop-plop.mp3",
}

var sfx: Dictionary = {}
var music_player: AudioStreamPlayer
var loading_layer: CanvasLayer
var loading_bar: ProgressBar
var loading_percent_label: Label
var audio_ready := false

func _ready():
	if DisplayServer.get_name() == "headless":
		create_headless_audio()
		return

	create_loading_overlay()
	call_deferred("warm_up_audio")

func create_headless_audio():
	for item in get_sfx_plan():
		sfx[item.name] = load_sfx_stream(item.name, item.duration)

	audio_ready = true

func warm_up_audio():
	var plan := get_sfx_plan()
	var total_steps: int = plan.size() + 1
	var completed_steps := 0

	update_loading_progress(0.0)
	await get_tree().process_frame

	for item in plan:
		sfx[item.name] = load_sfx_stream(item.name, item.duration)
		completed_steps += 1
		update_loading_progress(float(completed_steps) / float(total_steps))
		await get_tree().process_frame

	start_background_music()
	completed_steps += 1
	update_loading_progress(float(completed_steps) / float(total_steps))
	await get_tree().process_frame

	audio_ready = true
	hide_loading_overlay()

func get_sfx_plan() -> Array[Dictionary]:
	return [
		{"name": "button_tap", "duration": 0.08},
		{"name": "catch_egg", "duration": 0.22},
		{"name": "catch_golden", "duration": 0.42},
		{"name": "catch_poop", "duration": 0.26},
		{"name": "egg_break", "duration": 0.46},
		{"name": "poop_splat", "duration": 0.66},
		{"name": "jump", "duration": 0.18},
		{"name": "bird_drop", "duration": 0.12},
		{"name": "hurt", "duration": 0.34},
		{"name": "game_over", "duration": 0.58},
	]

func create_loading_overlay():
	loading_layer = CanvasLayer.new()
	loading_layer.layer = 100
	loading_layer.name = "LoadingLayer"
	add_child(loading_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.78)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_layer.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 260)
	panel.offset_left = -280
	panel.offset_top = -130
	panel.offset_right = 280
	panel.offset_bottom = 130
	panel.add_theme_stylebox_override("panel", create_panel_style(Color(1.0, 0.93, 0.56, 0.97), Color(0.42, 0.22, 0.08, 1.0), 6, 20))
	loading_layer.add_child(panel)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 34
	content.offset_top = 24
	content.offset_right = -34
	content.offset_bottom = -26
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var logo := TextureRect.new()
	logo.texture = load("res://Assets/UI/logo.png")
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(420, 92)
	content.add_child(logo)

	var label := Label.new()
	label.text = "Loading..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load("res://Assets/Fonts/LuckiestGuy-Regular.ttf"))
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.98, 0.49, 0.12, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.23, 0.10, 0.02, 1.0))
	label.add_theme_constant_override("outline_size", 7)
	content.add_child(label)

	loading_bar = ProgressBar.new()
	loading_bar.min_value = 0.0
	loading_bar.max_value = 100.0
	loading_bar.value = 0.0
	loading_bar.show_percentage = false
	loading_bar.custom_minimum_size = Vector2(480, 34)
	loading_bar.add_theme_stylebox_override("background", create_panel_style(Color(0.38, 0.19, 0.07, 1.0), Color(0.22, 0.09, 0.02, 1.0), 4, 16))
	loading_bar.add_theme_stylebox_override("fill", create_panel_style(Color(0.46, 0.86, 0.21, 1.0), Color(0.18, 0.45, 0.12, 1.0), 3, 16))
	content.add_child(loading_bar)

	loading_percent_label = Label.new()
	loading_percent_label.text = "0%"
	loading_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_percent_label.add_theme_font_override("font", load("res://Assets/Fonts/LuckiestGuy-Regular.ttf"))
	loading_percent_label.add_theme_font_size_override("font_size", 22)
	loading_percent_label.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05, 1.0))
	content.add_child(loading_percent_label)

func update_loading_progress(progress: float):
	if loading_bar != null:
		var progress_percent: float = clamp(progress, 0.0, 1.0) * 100.0
		loading_bar.value = progress_percent

		if loading_percent_label != null:
			loading_percent_label.text = str(roundi(progress_percent)) + "%"

func hide_loading_overlay():
	if loading_layer != null:
		loading_layer.queue_free()
		loading_layer = null
		loading_bar = null
		loading_percent_label = null

func create_panel_style(fill_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func start_background_music():
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.stream = create_music_stream()
	music_player.volume_db = MUSIC_VOLUME_DB
	add_child(music_player)
	music_player.play()

func _exit_tree():
	if music_player != null:
		music_player.stop()
		music_player.stream = null

	for child in get_children():
		var player := child as AudioStreamPlayer

		if player != null:
			player.stop()
			player.stream = null

	sfx.clear()

func play_sfx(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if audio_ready == false:
		return

	if sfx.has(sound_name) == false:
		return

	trim_finished_players()

	if get_sfx_player_count() >= get_max_sfx_players():
		queue_oldest_sfx_player()

	var player := AudioStreamPlayer.new()
	player.stream = sfx[sound_name]
	player.volume_db = get_sfx_volume_db(volume_db)
	player.pitch_scale = pitch_scale
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func trim_finished_players():
	for child in get_children():
		var player := child as AudioStreamPlayer

		if player != null and player != music_player and player.playing == false:
			player.queue_free()

func get_sfx_player_count() -> int:
	var count := 0

	for child in get_children():
		if child is AudioStreamPlayer and child != music_player:
			count += 1

	return count

func queue_oldest_sfx_player():
	for child in get_children():
		if child is AudioStreamPlayer and child != music_player:
			child.stop()
			child.queue_free()
			return

func get_max_sfx_players() -> int:
	if OS.has_feature("android") == true:
		return MAX_PLAYERS_ANDROID

	return MAX_PLAYERS_DESKTOP

func get_sfx_volume_db(volume_db: float) -> float:
	return clamp(volume_db + SFX_VOLUME_OFFSET_DB, -18.0, 0.0)

func create_stream(sound_name: String, duration: float) -> AudioStreamWAV:
	return create_wav_stream(duration, func(time: float, index: int) -> float:
		return get_sample(sound_name, time, duration, index) * MASTER_GAIN
	)

func load_sfx_stream(sound_name: String, duration: float) -> AudioStream:
	if EXTERNAL_SFX_PATHS.has(sound_name) == true:
		var stream := load(EXTERNAL_SFX_PATHS[sound_name]) as AudioStream

		if stream != null:
			return stream

	return create_stream(sound_name, duration)

func create_music_stream() -> AudioStreamWAV:
	var frame_count: int = int(float(SAMPLE_RATE) * MUSIC_DURATION)
	return create_wav_stream(MUSIC_DURATION, func(time: float, _index: int) -> float:
		return get_music_sample(time) * 0.82
	, true, frame_count)

func create_wav_stream(duration: float, sample_callback: Callable, loop_enabled: bool = false, loop_end_frame: int = 0) -> AudioStreamWAV:
	var frame_count: int = int(float(SAMPLE_RATE) * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)

	for index in frame_count:
		var time: float = float(index) / float(SAMPLE_RATE)
		var sample: float = clamp(sample_callback.call(time, index), -1.0, 1.0)
		var sample_int: int = int(sample * 32767.0)

		if sample_int < 0:
			sample_int += 65536

		data[index * 2] = sample_int & 0xff
		data[index * 2 + 1] = (sample_int >> 8) & 0xff

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data

	if loop_enabled == true:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = loop_end_frame

	return stream

func get_music_sample(time: float) -> float:
	var loop_time: float = fposmod(time, MUSIC_DURATION)
	var beat_duration := 0.32
	var beat_position: float = loop_time / beat_duration
	var beat_index: int = int(floor(beat_position))
	var beat_phase: float = beat_position - float(beat_index)
	var bar_index: int = int(floor(float(beat_index) / 4.0))

	var chord_roots := [60, 67, 69, 65, 60]
	var melody := [72, 76, 79, 76, 74, 72, 67, 0, 72, 74, 76, 79, 76, 72, 67, 0]
	var root_note: int = chord_roots[bar_index % chord_roots.size()]
	var melody_note: int = melody[beat_index % melody.size()]

	var bass: float = soft_triangle(note_frequency(root_note - 24), time) * pluck(beat_phase, 0.72) * 0.16
	var chord_phase: float = fposmod(beat_position, 2.0) / 2.0
	var chord_envelope: float = pluck(chord_phase, 0.95)
	var chord := 0.0
	chord += tone(note_frequency(root_note), time) * 0.09
	chord += tone(note_frequency(root_note + 4), time) * 0.07
	chord += tone(note_frequency(root_note + 7), time) * 0.07
	chord *= chord_envelope

	var melody_voice := 0.0

	if melody_note > 0:
		var melody_frequency: float = note_frequency(melody_note)
		melody_voice = soft_triangle(melody_frequency, time) * pluck(beat_phase, 0.85) * 0.16

	var shaker: float = smooth_noise(beat_index * 41 + int(beat_phase * 24.0)) * pulse(beat_phase, 0.50, 0.16) * 0.026
	var breeze: float = tone(1320.0 + sin(time * 2.0) * 18.0, time) * 0.014
	var loop_fade: float = min(1.0, min(loop_time / 0.05, (MUSIC_DURATION - loop_time) / 0.05))

	return (bass + chord + melody_voice + shaker + breeze) * loop_fade

func get_sample(sound_name: String, time: float, duration: float, index: int) -> float:
	match sound_name:
		"button_tap":
			var click := hit_noise(index, time, 0.022, 0.42)
			var tap_body := low_thump(320.0, 140.0, time, duration, 0.10)
			return click + tap_body
		"catch_egg":
			var basket_cloth := cloth_hit(index, time, 0.095, 0.34)
			var shell_tap := hit_noise(index + 43, time - 0.018, 0.035, 0.16)
			var soft_body := low_thump(190.0, 115.0, time, duration, 0.17)
			var tiny_bounce := cloth_hit(index + 77, time - 0.080, 0.090, 0.13)
			return basket_cloth + shell_tap + soft_body + tiny_bounce
		"catch_golden":
			var catch_body := get_sample("catch_egg", time, 0.22, index) * 0.85
			var coin_one := metal_ping(920.0, time - 0.025, 0.11, 0.16)
			var coin_two := metal_ping(1210.0, time - 0.105, 0.13, 0.13)
			var coin_three := metal_ping(1540.0, time - 0.205, 0.14, 0.10)
			return catch_body + coin_one + coin_two + coin_three
		"catch_poop":
			var wet_hit := wet_noise(index, time, 0.16, 0.42)
			var low_squish := low_thump(92.0, 42.0, time, duration, 0.26)
			var soft_smear := wet_noise(index + 91, time - 0.065, 0.17, 0.24)
			var basket_rub := cloth_hit(index + 17, time - 0.025, 0.11, 0.12)
			return wet_hit + low_squish + soft_smear + basket_rub
		"egg_break":
			var first_crack := crack_noise(index, time, 0.035, 0.82)
			var second_crack := crack_noise(index + 117, time - 0.040, 0.070, 0.48)
			var shell_scatter := shell_scatter_noise(index + 251, time - 0.075, 0.25, 0.36)
			var hollow_tap := low_thump(210.0, 96.0, time, 0.18, 0.14)
			var final_chip := hit_noise(index + 397, time - 0.225, 0.09, 0.16)
			return first_crack + second_crack + shell_scatter + hollow_tap + final_chip
		"poop_splat":
			var first_poot := fart_buzz(index, time, 0.30, 0.92)
			var second_poot := fart_buzz(index + 613, time - 0.22, 0.28, 0.62)
			var floor_thump := low_thump(82.0, 36.0, time, 0.24, 0.22)
			var tiny_pop := wet_noise(index + 301, time - 0.48, 0.09, 0.20)
			return first_poot + second_poot + floor_thump + tiny_pop
		"jump":
			var foot := cloth_hit(index, time, 0.050, 0.18)
			var whoosh := filtered_noise(index + int(time * 1800.0), 12) * get_envelope(time, duration, 0.012, 0.090) * 0.18
			whoosh += low_thump(170.0, 245.0, time, duration, 0.09)
			return foot + whoosh
		"bird_drop":
			var wing := cloth_hit(index + int(time * 1800.0), time, duration, 0.22)
			var chirp := metal_ping(760.0, time, duration, 0.045)
			return wing + chirp
		"hurt":
			var impact := hit_noise(index, time, 0.075, 0.48)
			var thud := low_thump(130.0, 52.0, time, duration, 0.42)
			var body_rustle := cloth_hit(index + 119, time - 0.050, 0.16, 0.16)
			var dizzy := low_thump(260.0, 180.0, time - 0.11, 0.16, 0.08)
			return impact + thud + body_rustle + dizzy
		"game_over":
			var frequency: float = 330.0

			if time >= 0.39:
				frequency = 147.0
			elif time >= 0.20:
				frequency = 220.0

			var jingle := soft_triangle(frequency, time) * get_envelope(time, duration, 0.012, 0.24) * 0.26
			var soft_thud := low_thump(110.0, 48.0, time - 0.36, 0.22, 0.22)
			var tail := soft_triangle(73.0, time) * get_envelope(time - 0.38, 0.20, 0.02, 0.16) * 0.11
			return jingle + soft_thud + tail

	return 0.0

func get_envelope(time: float, duration: float, attack: float = 0.01, release: float = 0.10) -> float:
	if time < 0.0 or time > duration:
		return 0.0

	var attack_amount: float = min(1.0, time / attack)
	var release_amount: float = min(1.0, (duration - time) / release)
	return max(0.0, min(attack_amount, release_amount))

func tone(frequency: float, time: float) -> float:
	return sin(TAU * frequency * time)

func soft_triangle(frequency: float, time: float) -> float:
	return asin(sin(TAU * frequency * time)) * 0.63662

func note_frequency(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)

func pitch_sweep(start_frequency: float, end_frequency: float, time: float, duration: float) -> float:
	var progress: float = clamp(time / duration, 0.0, 1.0)
	var frequency: float = lerp(start_frequency, end_frequency, progress)
	return soft_triangle(frequency, time)

func pulse(time: float, start_time: float, duration: float) -> float:
	return get_envelope(time - start_time, duration, 0.004, duration * 0.65)

func pluck(phase: float, decay: float) -> float:
	if phase < 0.0 or phase > 1.0:
		return 0.0

	var attack: float = min(1.0, phase / 0.035)
	var release: float = pow(max(0.0, 1.0 - phase), decay * 2.4)
	return attack * release

func get_noise(index: int) -> float:
	var value: float = sin(float(index) * 12.9898 + 78.233) * 43758.5453
	return (value - floor(value)) * 2.0 - 1.0

func smooth_noise(index: int) -> float:
	return (get_noise(index) + get_noise(index + 1) + get_noise(index + 2)) / 3.0

func filtered_noise(index: int, width: int) -> float:
	var total := 0.0

	for offset in width:
		total += get_noise(index + offset)

	return total / float(width)

func hit_noise(index: int, time: float, duration: float, amount: float) -> float:
	return filtered_noise(index + int(time * 9000.0), 3) * get_envelope(time, duration, 0.001, duration * 0.82) * amount

func crack_noise(index: int, time: float, duration: float, amount: float) -> float:
	if time < 0.0:
		return 0.0

	var brittle: float = get_noise(index + int(time * 18000.0)) * 0.70 + filtered_noise(index + int(time * 6000.0), 2) * 0.30
	return brittle * get_envelope(time, duration, 0.0005, duration * 0.74) * amount

func shell_scatter_noise(index: int, time: float, duration: float, amount: float) -> float:
	if time < 0.0:
		return 0.0

	var brittle: float = crack_noise(index, time, duration, 0.55)
	var chips: float = hit_noise(index + 83, time - 0.04, duration * 0.65, 0.26)
	var dry_tap: float = tone(980.0 + smooth_noise(index) * 160.0, time) * get_envelope(time, duration, 0.001, duration * 0.62) * 0.08
	return (brittle + chips + dry_tap) * amount

func cloth_hit(index: int, time: float, duration: float, amount: float) -> float:
	if time < 0.0:
		return 0.0

	var brush: float = filtered_noise(index + int(time * 3400.0), 13) * 0.68 + filtered_noise(index + int(time * 8800.0), 7) * 0.32
	return brush * get_envelope(time, duration, 0.002, duration * 0.86) * amount

func wet_noise(index: int, time: float, duration: float, amount: float) -> float:
	if time < 0.0:
		return 0.0

	var slow_noise: float = filtered_noise(index + int(time * 2600.0), 11)
	var fast_noise: float = filtered_noise(index + int(time * 12000.0), 5)
	var bubbling: float = tone(42.0 + abs(slow_noise) * 36.0, time) * 0.08
	return (slow_noise * 0.64 + fast_noise * 0.28 + bubbling) * get_envelope(time, duration, 0.004, duration * 0.88) * amount

func fart_buzz(index: int, time: float, duration: float, amount: float) -> float:
	if time < 0.0:
		return 0.0

	var wobble: float = sin(time * 34.0 + float(index % 17)) * 24.0
	var base_frequency: float = 62.0 + wobble
	var buzz: float = soft_triangle(base_frequency, time) * 0.68
	buzz += soft_triangle(base_frequency * 1.86, time) * 0.30
	buzz += filtered_noise(index + int(time * 1300.0), 7) * 0.34
	return buzz * get_envelope(time, duration, 0.012, duration * 0.88) * amount

func low_thump(start_frequency: float, end_frequency: float, time: float, duration: float, amount: float) -> float:
	if time < 0.0:
		return 0.0

	return pitch_sweep(start_frequency, end_frequency, time, duration) * get_envelope(time, duration, 0.004, duration * 0.70) * amount

func metal_ping(frequency: float, time: float, duration: float, amount: float) -> float:
	if time < 0.0:
		return 0.0

	var envelope: float = get_envelope(time, duration, 0.002, duration * 0.82)
	var overtone: float = tone(frequency * 2.01, time) * 0.35 + tone(frequency * 3.02, time) * 0.15
	return (tone(frequency, time) + overtone) * envelope * amount
