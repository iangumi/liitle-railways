extends Node3D
## Procedural, deterministic low-poly railway world. No external assets required.

const RADIUS := 20.0
const SEGMENTS := 128
const STATION_NAMES := ["Sunflower", "Riverbend", "Pine Hill"]

func _ready() -> void:
	_make_lighting()
	_make_ground()
	_make_railway()
	_make_stations()
	_make_scenery()


func _material(color: Color, emission: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	if emission:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.65
	return mat


func make_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = _material(color)
	item.position = pos
	parent.add_child(item)
	return item


func _cylinder(parent: Node3D, pos: Vector3, top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 8
	item.mesh = mesh
	item.material_override = _material(color)
	item.position = pos
	parent.add_child(item)
	return item


func _make_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 35, 0)
	sun.light_energy = 1.15
	add_child(sun)
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = Color("66b9ee")
	sky.sky_horizon_color = Color("d7f4fc")
	var sky_resource := Sky.new()
	sky_resource.sky_material = sky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky_resource
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


func _make_ground() -> void:
	make_box(self, Vector3(0, -0.45, 0), Vector3(120, 0.9, 120), Color("78c66f"))
	# A pond within the railway loop, safely away from the track.
	_cylinder(self, Vector3(-6.5, 0.035, -2), 4.1, 4.1, 0.08, Color("6dc6e7"))
	for i in range(12):
		var a := TAU * float(i) / 12.0
		make_box(self, Vector3(-6.5 + cos(a) * 4.0, 0.06, -2 + sin(a) * 4.0), Vector3(0.5, 0.12, 0.5), Color("d3be87"))


func _make_railway() -> void:
	# Track follows a circle. Sleeper long axes point radially; rails follow the tangent.
	for i in range(SEGMENTS):
		var a := TAU * float(i) / float(SEGMENTS)
		var radial := Vector3(cos(a), 0, sin(a))
		var middle := radial * RADIUS
		var ballast := make_box(self, middle + Vector3.UP * 0.035, Vector3(3.2, 0.08, 1.13), Color("b2a995"))
		ballast.rotation.y = -a
		var sleeper := make_box(self, middle + Vector3.UP * 0.13, Vector3(2.85, 0.17, 0.24), Color("866247"))
		sleeper.rotation.y = -a
		for side in [-0.9, 0.9]:
			var rail_pos: Vector3 = middle + radial * side + Vector3.UP * 0.255
			var rail := make_box(self, rail_pos, Vector3(0.10, 0.14, 1.07), Color("d1d9e3"))
			rail.rotation.y = -a


func _make_stations() -> void:
	var colors := [Color("ffdc75"), Color("f6a5a3"), Color("b7d7f7")]
	for i in range(STATION_NAMES.size()):
		var a := TAU * float(i) / float(STATION_NAMES.size())
		var radial := Vector3(cos(a), 0, sin(a))
		var pivot := Node3D.new()
		pivot.position = radial * (RADIUS + 4.8)
		pivot.rotation.y = -a
		add_child(pivot)
		# Platform is offset toward the circular track (negative local X).
		make_box(pivot, Vector3(-2.8, 0.28, 0), Vector3(2.6, 0.56, 12), Color("d4c9b3"))
		make_box(pivot, Vector3(-2.7, 0.58, 0), Vector3(2.15, 0.08, 11.5), Color("f5e6c9"))
		make_box(pivot, Vector3(0.9, 1.45, 0), Vector3(3.6, 2.9, 6.2), colors[i])
		make_box(pivot, Vector3(0.9, 3.03, 0), Vector3(4.2, 0.45, 7), Color("be5963"))
		for z in [-1.7, 1.7]:
			make_box(pivot, Vector3(-0.96, 1.52, z), Vector3(0.12, 1.2, 1.0), Color("528db5"))
		# Signs are geometry, independent of system fonts and translations.
		make_box(pivot, Vector3(-1.6, 2.45, 4.3), Vector3(0.19, 1.65, 0.17), Color("5d6b7e"))
		make_box(pivot, Vector3(-1.6, 3.25, 4.3), Vector3(0.24, 0.7, 2.6), Color("fef6d9"))
		for z in [-4.7, 4.7]:
			make_box(pivot, Vector3(-2.9, 0.86, z), Vector3(0.3, 0.18, 0.3), Color("e7bd59"))


func _make_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 24022026
	for i in range(75):
		var x := rng.randf_range(-52.0, 52.0)
		var z := rng.randf_range(-52.0, 52.0)
		var radius := Vector2(x, z).length()
		# Keep the railway, station platforms, and lake unobstructed.
		if radius > 16.0 and radius < 31.0:
			continue
		if Vector2(x + 6.5, z + 2).length() < 6.0:
			continue
		var height := rng.randf_range(2.8, 4.4)
		_cylinder(self, Vector3(x, height * 0.22, z), 0.2, 0.24, height * 0.44, Color("87644e"))
		_cylinder(self, Vector3(x, height * 0.66, z), 0.0, height * 0.36, height * 0.9, Color("3c9768") if i % 2 == 0 else Color("58ad63"))
	for i in range(8):
		var a := TAU * float(i) / 8.0 + 0.27
		var p := Vector3(cos(a) * 46, 0, sin(a) * 46)
		_cylinder(self, p + Vector3.UP * 3.7, 0.0, 5.2, 7.4, Color("7dbd97"))
		_cylinder(self, p + Vector3.UP * 7.1, 0.0, 3.5, 5.0, Color("a4c9a9"))
