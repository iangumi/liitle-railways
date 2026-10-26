extends Node3D
## Three local-only train models; safe movement while the doors are open.

const TRACK_RADIUS := 20.0
const MAX_SPEED_MPS := 14.0
const WHEEL_RADIUS := 0.46

var travel_angle := 0.0
var speed_mps := 0.0
var throttle := 0.0
var brake_held := false
var doors_open := false
var door_progress := 0.0
var model_index := 0
var wheels: Array[Node3D] = []
var models: Array[Node3D] = []
var door_panels: Array[Node3D] = []
var door_initial_positions: Array[Vector3] = []


func _ready() -> void:
	_build_wheels()
	_build_variants()
	select_model(model_index)
	_place_on_track()


func _paint(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.67
	return mat


func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _paint(color)
	instance.position = pos
	parent.add_child(instance)
	return instance


func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	item.mesh = mesh
	item.material_override = _paint(color)
	item.position = pos
	parent.add_child(item)
	return item


func _build_wheels() -> void:
	for side in [-1.0, 1.0]:
		for z in [-1.65, 0.0, 1.65]:
			var spin := Node3D.new()
			spin.position = Vector3(side * 1.14, 0.49, z)
			add_child(spin)
			wheels.append(spin)
			var wheel := _cylinder(spin, Vector3.ZERO, WHEEL_RADIUS, 0.22, Color("2f3a4b"))
			wheel.rotation.z = PI / 2.0
			var hub := _cylinder(spin, Vector3.ZERO, 0.16, 0.245, Color("b7c4cd"))
			hub.rotation.z = PI / 2.0


func _build_variants() -> void:
	var colors := [Color("e95459"), Color("4b9862"), Color("4b92d5")]
	var trims := [Color("ffe5a4"), Color("f8ca70"), Color("d2f4fc")]
	for model_id in range(3):
		var parent := Node3D.new()
		parent.name = "Model%d" % model_id
		add_child(parent)
		models.append(parent)
		var body_length := 4.8
		_box(parent, Vector3(0, 1.24, 0), Vector3(2.28, 1.65, body_length), colors[model_id])
		_box(parent, Vector3(0, 2.15, 0.64), Vector3(2.13, 0.72, 2.62), Color("f3eee0"))
		_box(parent, Vector3(0, 2.6, 0.64), Vector3(2.32, 0.21, 2.88), trims[model_id])
		for side in [-1.0, 1.0]:
			_box(parent, Vector3(side * 1.13, 1.35, 0), Vector3(0.09, 0.17, 4.35), trims[model_id])
			_box(parent, Vector3(side * 1.09, 2.18, 1.04), Vector3(0.07, 0.54, 1.05), Color("74c4e3"))
			# Two doors per side slide apart along the train length.
			for door_half in [-1.0, 1.0]:
				var panel := _box(parent, Vector3(side * 1.185, 1.25, -0.58 + door_half * 0.43), Vector3(0.08, 1.18, 0.82), trims[model_id])
				_box(panel, Vector3(side * 0.05, 0.19, 0), Vector3(0.04, 0.36, 0.45), Color("87cde5"))
				# Panels are only animated for the visible model.
				panel.set_meta("door_initial", panel.position)
				panel.set_meta("door_direction", door_half)
				if model_id == 0:
					door_panels.append(panel)
					door_initial_positions.append(panel.position)
		_box(parent, Vector3(0, 1.4, -2.44), Vector3(1.83, 0.88, 0.17), trims[model_id])
		for x in [-0.72, 0.72]:
			_box(parent, Vector3(x, 0.99, -2.57), Vector3(0.3, 0.26, 0.14), Color("fff2bb"))
		_box(parent, Vector3(0, 2.03, -1.89), Vector3(1.75, 0.43, 0.12), Color("76c2de"))
		if model_id == 1:
			# Forest Steam: chimney and coal-colored roof.
			_cylinder(parent, Vector3(0, 3.02, -1.55), 0.29, 0.98, Color("303943"))
			_cylinder(parent, Vector3(0, 3.56, -1.55), 0.38, 0.19, Color("525662"))
			_box(parent, Vector3(0, 2.86, 0.66), Vector3(2.2, 0.24, 2.8), Color("324c4a"))
		elif model_id == 2:
			# Sky Bullet: bright streamlined nose stripe and roof fin.
			_box(parent, Vector3(0, 1.22, -2.62), Vector3(1.22, 0.38, 0.50), Color("e7f5fd"))
			_box(parent, Vector3(0, 2.82, 0.35), Vector3(0.64, 0.22, 3.25), Color("2c6397"))


func select_model(index: int) -> void:
	model_index = clampi(index, 0, models.size() - 1)
	for i in range(models.size()):
		models[i].visible = i == model_index
	_set_door_geometry(door_progress)


func set_throttle(value: float) -> void:
	if doors_open:
		throttle = 0.0
		return
	throttle = clampf(value, 0.0, 1.0)


func stop() -> void:
	throttle = 0.0
	brake_held = true


func set_doors(open: bool) -> bool:
	if open and speed_mps > 0.3:
		return false
	doors_open = open
	if open:
		throttle = 0.0
		speed_mps = 0.0
	return true


func _set_door_geometry(amount: float) -> void:
	for parent in models:
		for child in parent.get_children():
			var panel := child as MeshInstance3D
			if panel != null and panel.has_meta("door_initial"):
				var original: Vector3 = panel.get_meta("door_initial")
				var direction: float = panel.get_meta("door_direction")
				panel.position = original + Vector3(0, 0, direction * amount * 0.67)


func advance(delta: float) -> void:
	if doors_open:
		throttle = 0.0
		speed_mps = 0.0
	else:
		var target_speed := MAX_SPEED_MPS * throttle
		var acceleration := 10.0 if brake_held else (3.0 if target_speed > speed_mps else 4.0)
		speed_mps = move_toward(speed_mps, 0.0 if brake_held else target_speed, acceleration * delta)
	travel_angle = fposmod(travel_angle + speed_mps * delta / TRACK_RADIUS, TAU)
	_place_on_track()
	for wheel in wheels:
		wheel.rotate_x(speed_mps * delta / WHEEL_RADIUS)
	door_progress = move_toward(door_progress, 1.0 if doors_open else 0.0, delta * 1.8)
	_set_door_geometry(door_progress)


func _place_on_track() -> void:
	position = Vector3(cos(travel_angle) * TRACK_RADIUS, 0.13, sin(travel_angle) * TRACK_RADIUS)
	rotation.y = PI - travel_angle


func speed_kmh() -> float:
	return speed_mps * 3.6
