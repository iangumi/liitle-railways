extends Node3D

const TRACK_RADIUS := 19.0
var progress := 0.0
var speed := 0.0
var throttle := 0.0
var braking := false
var train: Node3D
var camera: Camera3D
var speed_label: Label
var camera_inside := false

func _ready() -> void:
	_build_world()
	_build_controls()

func box(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	item.material_override = mat
	item.position = position
	parent.add_child(item)
	return item

func _build_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = Color("77c8f8")
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = Sky.new()
	e.sky.sky_material = sky
	env.environment = e
	add_child(env)
	box(self, Vector3(0,-0.55,0), Vector3(65,1,65), Color("77bb67"))
	for i in range(128):
		var a := TAU * i / 128.0
		var p := Vector3(cos(a)*TRACK_RADIUS, 0, sin(a)*TRACK_RADIUS)
		var sleeper := box(self, p, Vector3(2.8,0.18,0.36), Color("80553d"))
		sleeper.rotation.y = -a
		for offset in [-0.85, 0.85]:
			var rail := box(self, p + Vector3(cos(a)*offset,0.17,sin(a)*offset), Vector3(0.12,0.12,1.03), Color("c5cbd1"))
			rail.rotation.y = -a
	for i in range(3):
		var a := TAU*i/3.0
		var p := Vector3(cos(a)*25,0,sin(a)*25)
		box(self,p+Vector3(0,1.1,0),Vector3(6,2.2,3),Color("f8df9a"))
		box(self,p+Vector3(0,2.5,0),Vector3(7,0.5,4),Color("d95757"))
	train = Node3D.new()
	add_child(train)
	box(train,Vector3(0,1.25,0),Vector3(2.2,1.7,4.3),Color("e94e4e"))
	box(train,Vector3(0,2.3,-0.4),Vector3(2,0.55,2.6),Color("f9e6a3"))
	box(train,Vector3(0,1.8,-2.25),Vector3(1.6,1.2,0.25),Color("ffe4a1"))
	for z in [-1.4,1.4]:
		for x in [-1.05,1.05]:
			box(train,Vector3(x,0.45,z),Vector3(0.25,0.8,0.8),Color("313943"))
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)

func _build_controls() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(panel)
	var title := Label.new()
	title.text = "LITTLE RAILWAYS  •  Free Drive"
	title.position = Vector2(22,16)
	panel.add_child(title)
	speed_label = Label.new()
	speed_label.position = Vector2(22,45)
	panel.add_child(speed_label)
	var buttons := HBoxContainer.new()
	buttons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	buttons.offset_top = -88
	buttons.offset_bottom = -12
	buttons.add_theme_constant_override("separation",12)
	panel.add_child(buttons)
	_add_button(buttons,"SLOW",func(): throttle = maxf(0.0,throttle-0.25))
	_add_button(buttons,"GO",func(): throttle = minf(1.0,throttle+0.25))
	_add_button(buttons,"BRAKE",func(): speed = maxf(0.0,speed-5.0); throttle = 0.0)
	_add_button(buttons,"HORN!",func(): speed_label.text = "TOOT TOOT! 🚂")
	_add_button(buttons,"CAMERA",func(): camera_inside = not camera_inside)

func _add_button(row: HBoxContainer, caption: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = caption
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	row.add_child(b)

func _process(delta: float) -> void:
	speed = move_toward(speed, throttle * 12.0, delta * (3.0 if throttle > 0.0 else 4.0))
	progress += speed * delta / TRACK_RADIUS
	var a := progress
	train.position = Vector3(cos(a)*TRACK_RADIUS,0.1,sin(a)*TRACK_RADIUS)
	train.rotation.y = -a
	var follow := train.global_position + Vector3(cos(a)*7,6,sin(a)*7)
	if camera_inside:
		follow = train.global_position + Vector3(0,2.5,0)
	camera.global_position = camera.global_position.lerp(follow,minf(1.0,delta*4.0))
	camera.look_at(train.global_position + Vector3(-sin(a)*4,1.3,cos(a)*4),Vector3.UP)
	speed_label.text = "Speed: %d km/h  |  Power: %d%%" % [roundi(speed*5),roundi(throttle*100)]
