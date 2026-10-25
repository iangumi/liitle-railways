extends Node3D
## Child-friendly, deterministic track-following train and locomotive visuals.

const TRACK_RADIUS := 20.0
const MAX_SPEED_MPS := 14.0
const WHEEL_RADIUS := 0.46

var travel_angle := 0.0
var speed_mps := 0.0
var throttle := 0.0
var brake_held := false
var wheels: Array[Node3D] = []


func _ready() -> void:
	_build_model()
	_place_on_track()


func _paint(color: Color, glow: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.67
	if glow:
		mat.emission_enabled = true
		mat.emission = color
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


func _wheel(pos: Vector3) -> void:
	var spin := Node3D.new()
	spin.position = pos
	add_child(spin)
	wheels.append(spin)
	var wheel := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.height = 0.22
	cylinder.top_radius = WHEEL_RADIUS
	cylinder.bottom_radius = WHEEL_RADIUS
	cylinder.radial_segments = 16
	wheel.mesh = cylinder
	wheel.rotation.z = PI / 2.0
	wheel.material_override = _paint(Color("2f3a4b"))
	spin.add_child(wheel)
	var hub := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.height = 0.245
	disk.top_radius = 0.17
	disk.bottom_radius = 0.17
	disk.radial_segments = 12
	hub.mesh = disk
	hub.rotation.z = PI / 2.0
	hub.material_override = _paint(Color("a6afb9"))
	spin.add_child(hub)


func _build_model() -> void:
	# Local -Z is the front of the train, +Z is its rear.
	_box(self, Vector3(0, 1.15, 0), Vector3(2.28, 1.65, 4.8), Color("e95459"))
	_box(self, Vector3(0, 2.14, 0.75), Vector3(2.12, 0.8, 2.5), Color("fbf1d8"))
	_box(self, Vector3(0, 2.7, 0.7), Vector3(2.3, 0.22, 2.7), Color("d14b57"))
	_box(self, Vector3(0, 0.75, -1.2), Vector3(2.42, 0.15, 2.0), Color("ffe3a5"))
	for side in [-1.0, 1.0]:
		_box(self, Vector3(side * 1.14, 1.4, 0), Vector3(0.09, 0.19, 4.3), Color("ffe8a4"))
		_box(self, Vector3(side * 1.1, 2.20, 0.5), Vector3(0.06, 0.52, 1.28), Color("65b9db"))
		for z in [-1.65, 0.0, 1.65]:
			_wheel(Vector3(side * 1.14, 0.49, z))
	_box(self, Vector3(0, 1.45, -2.44), Vector3(1.65, 0.86, 0.17), Color("ffe7be"))
	for x in [-0.7, 0.7]:
		_box(self, Vector3(x, 0.96, -2.55), Vector3(0.36, 0.27, 0.13), Color("fff3aa"))
	_box(self, Vector3(0, 2.0, -1.87), Vector3(1.8, 0.48, 0.08), Color("74b7d7"))
	_box(self, Vector3(0, 1.0, 2.44), Vector3(1.2, 0.28, 0.22), Color("565f71"))
	_box(self, Vector3(0, 2.8, 0.75), Vector3(0.5, 0.24, 0.9), Color("707b8c"))


func set_throttle(value: float) -> void:
	throttle = clampf(value, 0.0, 1.0)


func stop() -> void:
	throttle = 0.0
	brake_held = true


func advance(delta: float) -> void:
	if brake_held:
		speed_mps = move_toward(speed_mps, 0.0, 10.0 * delta)
	else:
		var target_speed := MAX_SPEED_MPS * throttle
		var acceleration := 3.0 if target_speed > speed_mps else 4.0
		speed_mps = move_toward(speed_mps, target_speed, acceleration * delta)
	travel_angle = fposmod(travel_angle + speed_mps * delta / TRACK_RADIUS, TAU)
	_place_on_track()
	for wheel in wheels:
		wheel.rotate_x(speed_mps * delta / WHEEL_RADIUS)


func _place_on_track() -> void:
	position = Vector3(cos(travel_angle) * TRACK_RADIUS, 0.13, sin(travel_angle) * TRACK_RADIUS)
	# Facing along circle tangent: (-sin(a), 0, cos(a)), while train front is -Z.
	rotation.y = PI - travel_angle


func speed_kmh() -> float:
	return speed_mps * 3.6
