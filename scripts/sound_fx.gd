extends Node
## Synthesized, offline-friendly sounds: no MP3, WAV or third-party assets required.

const SAMPLE_RATE := 22050
var horn_player: AudioStreamPlayer
var motor_player: AudioStreamPlayer
var chime_player: AudioStreamPlayer


func _ready() -> void:
	horn_player = _player(_horn_samples(), false, -8.0)
	motor_player = _player(_motor_samples(), true, -42.0)
	chime_player = _player(_chime_samples(), false, -11.0)
	motor_player.play()


func _player(samples: PackedFloat32Array, loop: bool, volume: float) -> AudioStreamPlayer:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = _encode_pcm(samples)
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	return player


func _encode_pcm(samples: PackedFloat32Array) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		var sample := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 255
		data[i * 2 + 1] = (sample >> 8) & 255
	return data


func _horn_samples() -> PackedFloat32Array:
	var count := int(SAMPLE_RATE * 1.05)
	var result := PackedFloat32Array()
	result.resize(count)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var attack := clampf(t / 0.09, 0.0, 1.0)
		var release := clampf((1.05 - t) / 0.2, 0.0, 1.0)
		var w := attack * release
		var sound := 0.33 * sin(TAU * 220.0 * t) + 0.25 * sin(TAU * 277.2 * t) + 0.14 * sin(TAU * 329.6 * t)
		result[i] = w * sound
	return result


func _motor_samples() -> PackedFloat32Array:
	# One-second seamless loop: frequencies and chug pulses have integer cycles.
	var count := SAMPLE_RATE
	var result := PackedFloat32Array()
	result.resize(count)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var thrum := 0.5 * sin(TAU * 70.0 * t) + 0.23 * sin(TAU * 140.0 * t)
		var chug := 0.65 + 0.35 * sin(TAU * 8.0 * t)
		result[i] = thrum * chug * 0.4
	return result


func _chime_samples() -> PackedFloat32Array:
	var count := int(SAMPLE_RATE * 0.65)
	var result := PackedFloat32Array()
	result.resize(count)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var bell := sin(TAU * 523.25 * t) + 0.5 * sin(TAU * 783.99 * t)
		result[i] = 0.3 * bell * exp(-5.0 * t)
	return result


func horn() -> void:
	horn_player.play()


func arrival() -> void:
	chime_player.play()


func update_motor(speed_ratio: float) -> void:
	var ratio := clampf(speed_ratio, 0.0, 1.0)
	motor_player.volume_db = lerpf(-43.0, -19.0, ratio)
	motor_player.pitch_scale = lerpf(0.75, 1.4, ratio)


func audio_report() -> String:
	var peak := maxf(AudioServer.get_bus_peak_volume_left_db(0, 0), AudioServer.get_bus_peak_volume_right_db(0, 0))
	var muted := AudioServer.is_bus_mute(0)
	return "Output: %s | %.0f dB | muted: %s | horn: %s" % [AudioServer.get_driver_name(), peak, muted, horn_player.playing]
