extends RefCounted
## Ten tiny station-to-station trips. All progress is stored on the device.

const SAVE_PATH := "user://little_railways_v03.cfg"
const TRIP_COUNT := 10
const STATIONS := ["Sunflower", "Riverbend", "Pine Hill"]
const TRAIN_NAMES := ["Ruby Commuter", "Forest Steam", "Sky Bullet"]
const UNLOCK_TRIPS := [0, 3, 7]

enum Phase { PICKUP, DELIVERY, FINISHED }

var trip_index := 0
var total_deliveries := 0
var tickets := 0
var phase: Phase = Phase.PICKUP
var selected_train := 0
var saved_angle := 0.0
var stars: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]


func source_station() -> int:
	return trip_index % 3


func destination_station() -> int:
	return (trip_index + 1) % 3


func passenger_count() -> int:
	return 2 + trip_index % 4


func is_train_unlocked(train_index: int) -> bool:
	return train_index >= 0 and train_index < TRAIN_NAMES.size() and total_deliveries >= UNLOCK_TRIPS[train_index]


func next_unlock_description() -> String:
	for train_index in range(1, TRAIN_NAMES.size()):
		if not is_train_unlocked(train_index):
			return "%s in %d trips" % [TRAIN_NAMES[train_index], UNLOCK_TRIPS[train_index] - total_deliveries]
	return "All trains unlocked!"


func board_at(station_index: int) -> bool:
	if phase != Phase.PICKUP or station_index != source_station():
		return false
	phase = Phase.DELIVERY
	return true


func deliver_at(station_index: int, distance_metres: float) -> Dictionary:
	if phase != Phase.DELIVERY or station_index != destination_station():
		return {"success": false}
	var award_stars := 1
	if distance_metres <= 1.8:
		award_stars = 2
	if distance_metres <= 0.65:
		award_stars = 3
	var award_tickets := 10 + (award_stars - 1) * 5
	tickets += award_tickets
	stars[trip_index] = maxi(stars[trip_index], award_stars)
	trip_index += 1
	total_deliveries += 1
	phase = Phase.FINISHED if trip_index >= TRIP_COUNT else Phase.PICKUP
	return {"success": true, "stars": award_stars, "tickets": award_tickets, "finished": phase == Phase.FINISHED}


func restart_campaign() -> void:
	trip_index = 0
	phase = Phase.PICKUP
	saved_angle = 0.0
	# Lifetime tickets, delivered-trip unlocks, and best scores are retained.


func load_progress() -> void:
	var save := ConfigFile.new()
	if save.load(SAVE_PATH) != OK:
		return
	trip_index = clampi(int(save.get_value("progress", "trip_index", 0)), 0, TRIP_COUNT)
	total_deliveries = maxi(0, int(save.get_value("progress", "total_deliveries", 0)))
	tickets = maxi(0, int(save.get_value("progress", "tickets", 0)))
	var raw_phase := clampi(int(save.get_value("progress", "phase", Phase.PICKUP)), Phase.PICKUP, Phase.FINISHED)
	phase = raw_phase
	if trip_index == TRIP_COUNT:
		phase = Phase.FINISHED
	selected_train = clampi(int(save.get_value("progress", "selected_train", 0)), 0, TRAIN_NAMES.size() - 1)
	if not is_train_unlocked(selected_train):
		selected_train = 0
	saved_angle = fposmod(float(save.get_value("progress", "angle", 0.0)), TAU)
	var stored_scores: Array = save.get_value("progress", "stars", [])
	if stored_scores.size() == TRIP_COUNT:
		for i in range(TRIP_COUNT):
			stars[i] = clampi(int(stored_scores[i]), 0, 3)


func save_progress(angle: float) -> int:
	saved_angle = fposmod(angle, TAU)
	var save := ConfigFile.new()
	save.set_value("progress", "trip_index", trip_index)
	save.set_value("progress", "total_deliveries", total_deliveries)
	save.set_value("progress", "tickets", tickets)
	save.set_value("progress", "phase", int(phase))
	save.set_value("progress", "selected_train", selected_train)
	save.set_value("progress", "angle", saved_angle)
	save.set_value("progress", "stars", stars)
	return save.save(SAVE_PATH)
