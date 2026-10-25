extends SceneTree
## Non-interactive Godot regression smoke test. Run with:
## godot --headless --path . --script res://tests/smoke_test.gd


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var packed_scene := load("res://main.tscn")
	if packed_scene == null:
		_fail("main scene cannot be loaded")
		return
	var app := packed_scene.instantiate()
	root.add_child(app)
	await process_frame
	var locomotive = app.train
	if locomotive == null:
		_fail("locomotive is missing")
		return
	if locomotive.wheels.size() != 6:
		_fail("train must have six animated wheels")
		return
	if app.sounds.horn_player == null or app.sounds.motor_player == null:
		_fail("audio players were not created")
		return
	locomotive.set_throttle(1.0)
	for i in range(60):
		locomotive.advance(1.0 / 60.0)
	if locomotive.speed_mps <= 0.0:
		_fail("GO should accelerate the train")
		return
	if locomotive.speed_kmh() <= 0.0:
		_fail("speedometer should reflect movement")
		return
	locomotive.stop()
	var previous_speed: float = locomotive.speed_mps
	locomotive.advance(0.3)
	if locomotive.speed_mps >= previous_speed:
		_fail("BRAKE should decelerate the train")
		return
	print("PASS: scene, six wheels, audio players, acceleration, braking")
	quit(0)


func _fail(message: String) -> void:
	push_error("SMOKE TEST FAILED: " + message)
	quit(1)
