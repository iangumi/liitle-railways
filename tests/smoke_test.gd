extends SceneTree
## Godot headless checks for v0.3 mission flow, save, train safety, scenery and UI.

const MissionScript = preload("res://scripts/mission.gd")


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var packed_scene: PackedScene = load("res://main.tscn")
	if packed_scene == null:
		_fail("main scene cannot load")
		return
	print("SMOKE: Instantiating main scene")
	var app = packed_scene.instantiate()
	root.add_child(app)
	# A parse error may leave this as a bare Node3D instead of the game script.
	# Fail immediately, rather than accessing app.train and hanging until timeout.
	if app.get_script() == null:
		_fail("main.gd failed to load (check import logs for parser errors)")
		return
	print("SMOKE: Main scene ready; checking train and sounds")
	if app.train == null or app.passengers == null or app.missions == null:
		_fail("gameplay components missing")
		return
	if app.train.wheels.size() != 6 or app.train.models.size() != 3:
		_fail("train models or wheel animation missing")
		return
	if app.sounds.horn_player == null or app.sounds.motor_player == null:
		_fail("audio players missing")
		return
	print("SMOKE: Checking acceleration, braking and door safety")
	app.train.set_throttle(1.0)
	for i in range(30):
		app.train.advance(1.0 / 60.0)
	if app.train.speed_mps <= 0.0:
		_fail("GO should accelerate")
		return
	app.train.stop()
	app.train.advance(0.6)
	if app.train.speed_mps > 0.3:
		_fail("BRAKE should decelerate")
		return
	app.train.set_doors(true)
	app.train.set_throttle(1.0)
	app.train.advance(0.2)
	if app.train.speed_mps > 0 or app.train.throttle > 0:
		_fail("open doors must lock movement")
		return
	app.train.set_doors(false)
	# Mission tests use a fresh object so no persistent device state can interfere.
	print("SMOKE: Checking mission progression")
	var mission = MissionScript.new()
	if not mission.board_at(0) or mission.board_at(0):
		_fail("pickup state transition failed")
		return
	if mission.deliver_at(0, 0.2)["success"]:
		_fail("wrong station must not pay tickets")
		return
	var earned: Dictionary = mission.deliver_at(1, 0.4)
	if not earned["success"] or earned["stars"] != 3 or mission.tickets != 20:
		_fail("delivery scoring and reward incorrect")
		return
	for trip in range(1, 10):
		if not mission.board_at(trip % 3):
			_fail("pickup failed at trip %d" % trip)
			return
		if not mission.deliver_at((trip + 1) % 3, 2.5)["success"]:
			_fail("delivery failed at trip %d" % trip)
			return
	if mission.phase != MissionScript.Phase.FINISHED or mission.trip_index != 10:
		_fail("campaign must finish after 10 trips")
		return
	if not mission.is_train_unlocked(1) or not mission.is_train_unlocked(2):
		_fail("trains should unlock after 3/7 trips")
		return
	# Verify local persistence of campaign data and best stars.
	print("SMOKE: Checking save and replay")
	if mission.save_progress(2.1) != OK:
		_fail("save should succeed")
		return
	var loaded = MissionScript.new()
	loaded.load_progress()
	if loaded.trip_index != 10 or loaded.phase != MissionScript.Phase.FINISHED or loaded.tickets != mission.tickets:
		_fail("save/load lost campaign progress")
		return
	if absf(loaded.saved_angle - 2.1) > 0.001 or loaded.stars[0] != 3:
		_fail("save/load lost position or best stars")
		return
	var old_tickets: int = mission.tickets
	mission.restart_campaign()
	if mission.phase != MissionScript.Phase.PICKUP or mission.tickets != old_tickets:
		_fail("replay should preserve lifetime rewards")
		return
	print("PASS v0.3: scene, train, sound, door safety, 10 trips, rewards, unlocks, save/load, replay")
	quit(0)


func _fail(message: String) -> void:
	push_error("SMOKE TEST FAILED: " + message)
	quit(1)
