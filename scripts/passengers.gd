extends Node3D
## Simple tiny passengers: wave while waiting and walk toward doors when boarding.

const TRACK_RADIUS := 20.0
const STATION_COUNT := 3
const MAX_PASSENGERS := 5
var avatars: Array = []
var clock := 0.0


func _ready() -> void:
	for station in range(STATION_COUNT):
		var crowd: Array = []
		for passenger in range(MAX_PASSENGERS):
			var traveler := _make_passenger(station, passenger)
			add_child(traveler)
			traveler.visible = false
			crowd.append(traveler)
		avatars.append(crowd)


func _make_passenger(station: int, index: int) -> Node3D:
	var actor := Node3D.new()
	actor.name = "Passenger_%d_%d" % [station, index]
	actor.position = _waiting_position(station, index)
	var body := Node3D.new()
	body.name = "Body"
	actor.add_child(body)
	var outfits := [Color("ee715b"), Color("789cde"), Color("f3b856"), Color("a889d3"), Color("60a78c")]
	_mesh(body, Vector3(0, 0.72, 0), Vector3(0.44, 0.72, 0.32), outfits[index])
	_mesh(body, Vector3(0, 0.22, 0), Vector3(0.18, 0.38, 0.18), Color("4e596d"))
	_mesh(body, Vector3(0.17, 0.22, 0), Vector3(0.18, 0.38, 0.18), Color("4e596d"))
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	head.mesh = sphere
	head.material_override = _paint(Color("ffd6ab"))
	head.position = Vector3(0, 1.27, 0)
	body.add_child(head)
	_mesh(body, Vector3(0, 1.55, 0), Vector3(0.53, 0.13, 0.48), outfits[index].darkened(0.18))
	return actor


func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


func _mesh(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> void:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = _paint(color)
	item.position = position
	parent.add_child(item)


func _waiting_position(station: int, index: int) -> Vector3:
	var angle := TAU * float(station) / float(STATION_COUNT)
	var radial := Vector3(cos(angle), 0, sin(angle))
	var tangent := Vector3(-sin(angle), 0, cos(angle))
	return radial * 22.65 + tangent * (float(index) - 2.0) * 1.1


func show_waiting(station_index: int, passenger_count: int) -> void:
	for station in range(STATION_COUNT):
		for index in range(MAX_PASSENGERS):
			var person: Node3D = avatars[station][index]
			person.visible = station == station_index and index < passenger_count
			person.position = _waiting_position(station, index)


func board(station_index: int) -> void:
	var angle := TAU * float(station_index) / float(STATION_COUNT)
	var radial := Vector3(cos(angle), 0, sin(angle))
	for person in avatars[station_index]:
		if not person.visible:
			continue
		var move := create_tween()
		move.tween_property(person, "position", person.position - radial * 1.45, 0.8)
		move.tween_callback(person.hide)


func _process(delta: float) -> void:
	clock += delta
	for station in range(STATION_COUNT):
		for index in range(MAX_PASSENGERS):
			var person: Node3D = avatars[station][index]
			var body: Node3D = person.get_node("Body")
			body.position.y = 0.055 * sin(clock * 3.0 + float(index) * 1.5)
			body.rotation.y = 0.08 * sin(clock * 2.1 + float(index))
