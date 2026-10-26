extends Node3D
## Little Railways v0.3: board, drive, deliver, score, unlock and resume.

const WorldScript = preload("res://scripts/world.gd")
const TrainScript = preload("res://scripts/train.gd")
const SoundScript = preload("res://scripts/sound_fx.gd")
const PassengerScript = preload("res://scripts/passengers.gd")
const MissionScript = preload("res://scripts/mission.gd")
const CAMERA_NAMES := ["Chase", "Driver", "Scenic"]

var world
var train
var sounds
var passengers
var missions
var camera: Camera3D
var camera_mode := 0
var go_held := false
var slow_held := false
var brake_held := false
var speed_label: Label
var power_label: Label
var power_bar: ProgressBar
var mission_label: Label
var tickets_label: Label
var message_label: Label
var doors_button: Button
var camera_button: Button
var train_button: Button
var restart_button: Button
var message_seconds := 0.0
var last_stop_station := -1


func _ready() -> void:
	missions = MissionScript.new()
	missions.load_progress()
	world = WorldScript.new()
	add_child(world)
	passengers = PassengerScript.new()
	add_child(passengers)
	train = TrainScript.new()
	add_child(train)
	train.travel_angle = missions.saved_angle
	train._place_on_track()
	train.select_model(missions.selected_train)
	sounds = SoundScript.new()
	add_child(sounds)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 69.0
	add_child(camera)
	_build_hud()
	_refresh_passengers()
	_refresh_mission_hud()
	if missions.phase == MissionScript.Phase.FINISHED:
		_display_message("All 10 trips complete! Tap REPLAY to begin again.", 7.0)
	else:
		_display_message("Welcome aboard! Stop at the station and tap DOORS.", 6.0)
	_update_camera(1.0)


func _build_hud() -> void:
	var overlay := CanvasLayer.new()
	add_child(overlay)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(root)

	var dashboard := PanelContainer.new()
	dashboard.anchor_left = 0.016
	dashboard.anchor_right = 0.40
	dashboard.anchor_top = 0.018
	dashboard.anchor_bottom = 0.018
	dashboard.offset_bottom = 160
	dashboard.add_theme_stylebox_override("panel", _style(Color("18334de9"), 16))
	root.add_child(dashboard)
	var readouts := VBoxContainer.new()
	readouts.add_theme_constant_override("separation", 4)
	dashboard.add_child(readouts)
	var title := Label.new()
	title.text = "LITTLE RAILWAYS  /  v0.3"
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("fff2c4"))
	readouts.add_child(title)
	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size", 30)
	speed_label.add_theme_color_override("font_color", Color.WHITE)
	readouts.add_child(speed_label)
	power_label = Label.new()
	power_label.add_theme_font_size_override("font_size", 19)
	readouts.add_child(power_label)
	power_bar = ProgressBar.new()
	power_bar.min_value = 0
	power_bar.max_value = 100
	power_bar.show_percentage = false
	power_bar.custom_minimum_size.y = 14
	power_bar.add_theme_stylebox_override("background", _style(Color("40566c"), 6))
	power_bar.add_theme_stylebox_override("fill", _style(Color("81d988"), 6))
	readouts.add_child(power_bar)

	var mission_panel := PanelContainer.new()
	mission_panel.anchor_left = 0.415
	mission_panel.anchor_right = 0.984
	mission_panel.anchor_top = 0.018
	mission_panel.anchor_bottom = 0.018
	mission_panel.offset_bottom = 174
	mission_panel.add_theme_stylebox_override("panel", _style(Color("18334de9"), 16))
	root.add_child(mission_panel)
	var mission_stack := VBoxContainer.new()
	mission_stack.add_theme_constant_override("separation", 5)
	mission_panel.add_child(mission_stack)
	mission_label = Label.new()
	mission_label.add_theme_font_size_override("font_size", 23)
	mission_label.add_theme_color_override("font_color", Color("fff2c4"))
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_stack.add_child(mission_label)
	tickets_label = Label.new()
	tickets_label.add_theme_font_size_override("font_size", 19)
	mission_stack.add_child(tickets_label)
	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color("b8f0e0"))
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_stack.add_child(message_label)

	var control_panel := PanelContainer.new()
	control_panel.anchor_left = 0.016
	control_panel.anchor_right = 0.984
	control_panel.anchor_top = 1.0
	control_panel.anchor_bottom = 1.0
	control_panel.offset_top = -123
	control_panel.offset_bottom = -10
	control_panel.add_theme_stylebox_override("panel", _style(Color("17314be9"), 16))
	root.add_child(control_panel)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	control_panel.add_child(buttons)

	var go := _button(buttons, "GO +", Color("258e5e"))
	go.pressed.connect(func() -> void: _change_power(0.2))
	go.button_down.connect(func() -> void: go_held = true)
	go.button_up.connect(func() -> void: go_held = false)
	var slow := _button(buttons, "SLOW -", Color("37759c"))
	slow.pressed.connect(func() -> void: _change_power(-0.2))
	slow.button_down.connect(func() -> void: slow_held = true)
	slow.button_up.connect(func() -> void: slow_held = false)
	var brake := _button(buttons, "BRAKE", Color("b9504f"))
	brake.button_down.connect(func() -> void:
		brake_held = true
		train.stop()
		train.speed_mps = maxf(0.0, train.speed_mps - 2.0)
	)
	brake.button_up.connect(func() -> void: brake_held = false)
	doors_button = _button(buttons, "DOORS", Color("a26c36"))
	doors_button.pressed.connect(_toggle_doors)
	var horn := _button(buttons, "HORN", Color("a87739"))
	horn.pressed.connect(func() -> void:
		sounds.horn()
		_display_message("TOOT TOOT!", 1.3)
	)
	camera_button = _button(buttons, "CAMERA", Color("6857a7"))
	camera_button.pressed.connect(_next_camera)
	train_button = _button(buttons, "TRAINS", Color("417b81"))
	train_button.pressed.connect(_next_train)
	restart_button = _button(buttons, "REPLAY", Color("8b637e"))
	restart_button.pressed.connect(_replay)
	restart_button.visible = missions.phase == MissionScript.Phase.FINISHED


func _style(color: Color, corner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(corner)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


func _button(parent: HBoxContainer, caption: String, color: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(100, 80)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(color, 13))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.1), 13))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.2), 13))
	parent.add_child(button)
	return button


func _change_power(delta: float) -> void:
	if train.doors_open:
		_display_message("Close the doors before moving!", 2.3)
		return
	train.set_throttle(train.throttle + delta)


func _station_nearby() -> int:
	if train.speed_mps > 0.4:
		return -1
	var closest_station := -1
	var closest_distance := 3.15
	for index in range(3):
		var center := TAU * float(index) / 3.0
		var metres := absf(wrapf(train.travel_angle - center, -PI, PI)) * train.TRACK_RADIUS
		if metres <= closest_distance:
			closest_distance = metres
			closest_station = index
	return closest_station


func _toggle_doors() -> void:
	if train.doors_open:
		train.set_doors(false)
		doors_button.text = "DOORS"
		_display_message("Doors closed! Safe to drive.", 2.0)
		_save_game()
		return
	var station := _station_nearby()
	if station == -1:
		_display_message("Stop beside a station before opening the doors.", 3.5)
		return
	if not train.set_doors(true):
		return
	doors_button.text = "CLOSE"
	sounds.arrival()
	if missions.phase == MissionScript.Phase.PICKUP:
		if missions.board_at(station):
			passengers.board(station)
			_display_message("Passengers aboard! Close doors and drive to %s." % MissionScript.STATIONS[missions.destination_station()], 5.0)
		else:
			_display_message("Passengers are waiting at %s Station." % MissionScript.STATIONS[missions.source_station()], 4.0)
	elif missions.phase == MissionScript.Phase.DELIVERY:
		var target_angle := TAU * float(station) / 3.0
		var stop_distance := absf(wrapf(train.travel_angle - target_angle, -PI, PI)) * train.TRACK_RADIUS
		var before_unlocks := missions.total_deliveries
		var reward: Dictionary = missions.deliver_at(station, stop_distance)
		if reward.get("success", false):
			var stars_text := "★".repeat(int(reward["stars"]))
			_display_message("Great stop! %s  +%d tickets!" % [stars_text, int(reward["tickets"])], 5.0)
			if missions.phase == MissionScript.Phase.FINISHED:
				restart_button.visible = true
				_display_message("Amazing! 10 trips finished. Tap REPLAY for more!", 9.0)
			else:
				_refresh_passengers()
				# The following route starts here: board while doors are already open.
				missions.board_at(station)
				passengers.board(station)
			if missions.total_deliveries > before_unlocks:
				for index in range(1, MissionScript.TRAIN_NAMES.size()):
					if missions.total_deliveries == MissionScript.UNLOCK_TRIPS[index]:
						_display_message("New train unlocked: %s! Tap TRAINS." % MissionScript.TRAIN_NAMES[index], 7.0)
		else:
			_display_message("Deliver your passengers to %s Station." % MissionScript.STATIONS[missions.destination_station()], 4.0)
	else:
		_display_message("All routes complete. Explore or tap REPLAY!", 4.0)
	_refresh_mission_hud()
	_save_game()


func _refresh_passengers() -> void:
	if missions.phase == MissionScript.Phase.PICKUP:
		passengers.show_waiting(missions.source_station(), missions.passenger_count())
	else:
		passengers.show_waiting(-1, 0)


func _refresh_mission_hud() -> void:
	if missions.phase == MissionScript.Phase.FINISHED:
		mission_label.text = "ALL 10 TRIPS COMPLETED!"
	elif missions.phase == MissionScript.Phase.PICKUP:
		mission_label.text = "TRIP %d/10: Pick up at %s" % [missions.trip_index + 1, MissionScript.STATIONS[missions.source_station()]]
	else:
		mission_label.text = "TRIP %d/10: Deliver to %s" % [missions.trip_index + 1, MissionScript.STATIONS[missions.destination_station()]]
	tickets_label.text = "TICKETS: %d    FINISHED: %d    %s" % [missions.tickets, missions.total_deliveries, missions.next_unlock_description()]


func _next_train() -> void:
	var next_index := missions.selected_train
	for attempt in range(1, 4):
		var candidate := (missions.selected_train + attempt) % MissionScript.TRAIN_NAMES.size()
		if missions.is_train_unlocked(candidate):
			next_index = candidate
			break
	if next_index == missions.selected_train:
		_display_message("Keep driving! Unlock Forest Steam after 3 trips.", 4.0)
		return
	missions.selected_train = next_index
	train.select_model(next_index)
	_display_message("Now driving: %s!" % MissionScript.TRAIN_NAMES[next_index], 3.0)
	_save_game()


func _replay() -> void:
	if missions.phase != MissionScript.Phase.FINISHED:
		return
	missions.restart_campaign()
	train.set_doors(false)
	train.throttle = 0.0
	train.speed_mps = 0.0
	train.travel_angle = 0.0
	train._place_on_track()
	doors_button.text = "DOORS"
	restart_button.visible = false
	_refresh_passengers()
	_refresh_mission_hud()
	_display_message("New adventure! Board at Sunflower Station.", 5.0)
	_save_game()


func _next_camera() -> void:
	camera_mode = (camera_mode + 1) % CAMERA_NAMES.size()
	camera_button.text = "VIEW: " + CAMERA_NAMES[camera_mode].to_upper()
	_display_message("%s camera" % CAMERA_NAMES[camera_mode], 1.7)


func _display_message(text: String, duration: float) -> void:
	message_label.text = text
	message_seconds = duration


func _check_station() -> void:
	var station := _station_nearby()
	if station != -1 and station != last_stop_station:
		last_stop_station = station
		sounds.arrival()
		if missions.phase != MissionScript.Phase.FINISHED:
			_display_message("Welcome to %s! Tap DOORS to board or drop off." % MissionScript.STATIONS[station], 4.2)
	if station == -1:
		last_stop_station = -1


func _physics_process(delta: float) -> void:
	if go_held and not brake_held and not train.doors_open:
		train.set_throttle(train.throttle + 0.6 * delta)
	if slow_held:
		train.set_throttle(train.throttle - 0.75 * delta)
	train.brake_held = brake_held
	train.advance(delta)
	sounds.update_motor(train.speed_mps / train.MAX_SPEED_MPS)
	_check_station()


func _process(delta: float) -> void:
	_update_camera(delta)
	speed_label.text = "SPEED: %02d km/h" % roundi(train.speed_kmh())
	power_label.text = "Power %d%%   |   %s" % [roundi(train.throttle * 100), "DOORS OPEN" if train.doors_open else "Ready"]
	power_bar.value = train.throttle * 100.0
	if message_seconds > 0:
		message_seconds -= delta
		if message_seconds <= 0:
			message_label.text = "Stop at your station, then tap DOORS!"


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


func _save_game() -> void:
	if missions.save_progress(train.travel_angle) != OK:
		push_warning("Unable to save local game progress")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if missions != null and train != null:
			_save_game()
