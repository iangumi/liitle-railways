extends Node3D
## Little Railways v0.2 — accessible touch driving experience.

const WorldScript = preload("res://scripts/world.gd")
const TrainScript = preload("res://scripts/train.gd")
const SoundScript = preload("res://scripts/sound_fx.gd")
const CAMERA_NAMES := ["Chase", "Driver", "Scenic"]

var world
var train
var sounds
var camera: Camera3D
var camera_mode := 0
var go_held := false
var slow_held := false
var brake_held := false
var speed_label: Label
var throttle_label: Label
var throttle_bar: ProgressBar
var message_label: Label
var camera_button: Button
var message_seconds := 0.0
var last_arrived_station := -1


func _ready() -> void:
	world = WorldScript.new()
	add_child(world)
	train = TrainScript.new()
	add_child(train)
	sounds = SoundScript.new()
	add_child(sounds)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 69.0
	add_child(camera)
	_build_hud()
	_display_message("Welcome aboard! Tap GO to start driving.", 5.0)
	_update_camera(1.0)


func _build_hud() -> void:
	var overlay := CanvasLayer.new()
	add_child(overlay)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.anchor_left = 0.015
	top_panel.anchor_top = 0.018
	top_panel.anchor_right = 0.38
	top_panel.anchor_bottom = 0.018
	top_panel.offset_bottom = 156.0
	top_panel.add_theme_stylebox_override("panel", _style(Color("172f45db"), 16))
	root.add_child(top_panel)
	var readouts := VBoxContainer.new()
	readouts.add_theme_constant_override("separation", 3)
	top_panel.add_child(readouts)
	var heading := Label.new()
	heading.text = "LITTLE RAILWAYS   |   FREE DRIVE"
	heading.add_theme_font_size_override("font_size", 21)
	heading.add_theme_color_override("font_color", Color("fff0c2"))
	readouts.add_child(heading)
	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size", 30)
	speed_label.add_theme_color_override("font_color", Color.WHITE)
	readouts.add_child(speed_label)
	throttle_label = Label.new()
	throttle_label.add_theme_font_size_override("font_size", 19)
	readouts.add_child(throttle_label)
	throttle_bar = ProgressBar.new()
	throttle_bar.min_value = 0
	throttle_bar.max_value = 100
	throttle_bar.show_percentage = false
	throttle_bar.custom_minimum_size.y = 17
	throttle_bar.add_theme_stylebox_override("background", _style(Color("40556b"), 7))
	throttle_bar.add_theme_stylebox_override("fill", _style(Color("7ee18a"), 7))
	readouts.add_child(throttle_bar)

	var message_panel := PanelContainer.new()
	message_panel.anchor_left = 0.39
	message_panel.anchor_right = 0.985
	message_panel.anchor_top = 0.018
	message_panel.anchor_bottom = 0.018
	message_panel.offset_bottom = 61
	message_panel.add_theme_stylebox_override("panel", _style(Color("172f45cf"), 14))
	root.add_child(message_panel)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color("fff3dd"))
	message_panel.add_child(message_label)

	var control_panel := PanelContainer.new()
	control_panel.anchor_left = 0.018
	control_panel.anchor_right = 0.982
	control_panel.anchor_top = 1.0
	control_panel.anchor_bottom = 1.0
	control_panel.offset_top = -122
	control_panel.offset_bottom = -12
	control_panel.add_theme_stylebox_override("panel", _style(Color("18344be6"), 18))
	root.add_child(control_panel)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	control_panel.add_child(buttons)

	var go_button := _button(buttons, "GO  +", Color("268b57"))
	go_button.pressed.connect(func() -> void: train.set_throttle(train.throttle + 0.2))
	go_button.button_down.connect(func() -> void: go_held = true)
	go_button.button_up.connect(func() -> void: go_held = false)

	var slow_button := _button(buttons, "SLOW  -", Color("376d94"))
	slow_button.pressed.connect(func() -> void: train.set_throttle(train.throttle - 0.2))
	slow_button.button_down.connect(func() -> void: slow_held = true)
	slow_button.button_up.connect(func() -> void: slow_held = false)

	var brake_button := _button(buttons, "BRAKE", Color("c3574f"))
	brake_button.button_down.connect(func() -> void:
		brake_held = true
		train.stop()
		train.speed_mps = maxf(0.0, train.speed_mps - 3.0)
	)
	brake_button.button_up.connect(func() -> void: brake_held = false)

	var horn_button := _button(buttons, "HORN", Color("b47b30"))
	horn_button.pressed.connect(func() -> void:
		sounds.horn()
		_display_message("TOOT TOOT!", 1.4)
	)

	camera_button = _button(buttons, "CAMERA", Color("6855a0"))
	camera_button.pressed.connect(_next_camera)


func _style(color: Color, corner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(corner)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _button(parent: HBoxContainer, label_text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(116, 83)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(color, 15))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.15), 15))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.22), 15))
	parent.add_child(button)
	return button


func _next_camera() -> void:
	camera_mode = (camera_mode + 1) % CAMERA_NAMES.size()
	camera_button.text = "VIEW: " + CAMERA_NAMES[camera_mode].to_upper()
	_display_message(CAMERA_NAMES[camera_mode] + " camera", 1.6)


func _display_message(text: String, duration: float) -> void:
	message_label.text = text
	message_seconds = duration


func _physics_process(delta: float) -> void:
	if go_held and not brake_held:
		train.set_throttle(train.throttle + 0.60 * delta)
	if slow_held:
		train.set_throttle(train.throttle - 0.75 * delta)
	train.brake_held = brake_held
	train.advance(delta)
	sounds.update_motor(train.speed_mps / train.MAX_SPEED_MPS)
	_check_stations()


func _check_stations() -> void:
	for i in range(world.STATION_NAMES.size()):
		var angle := TAU * float(i) / float(world.STATION_NAMES.size())
		var distance := absf(wrapf(train.travel_angle - angle, -PI, PI))
		if distance > 0.23 and last_arrived_station == i:
			last_arrived_station = -1
		if distance < 0.115 and train.speed_mps < 0.65 and last_arrived_station != i:
			last_arrived_station = i
			sounds.arrival()
			_display_message("Arrived at " + world.STATION_NAMES[i] + " Station!", 5.0)


func _process(delta: float) -> void:
	_update_camera(delta)
	speed_label.text = "SPEED: %02d km/h" % roundi(train.speed_kmh())
	throttle_label.text = "Power: %d%%" % roundi(train.throttle * 100.0)
	throttle_bar.value = train.throttle * 100.0
	if message_seconds > 0:
		message_seconds -= delta
		if message_seconds <= 0:
			message_label.text = "Explore the railway. Stop at the stations!"


func _update_camera(delta: float) -> void:
	var offset := Vector3(0, 4.4, 9.7)
	var aim := Vector3(0, 1.7, -5.0)
	match camera_mode:
		1:
			offset = Vector3(0, 3.0, 0.55)
			aim = Vector3(0, 1.8, -15.0)
		2:
			offset = Vector3(9.5, 6.5, 7.5)
			aim = Vector3(0, 1.6, -2.0)
	var destination := train.to_global(offset)
	camera.global_position = camera.global_position.lerp(destination, clampf(delta * 4.5, 0.0, 1.0))
	camera.look_at(train.to_global(aim), Vector3.UP)
