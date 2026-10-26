extends SceneTree

const SoundScript = preload("res://scripts/sound_fx.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sounds = SoundScript.new()
	root.add_child(sounds)
	for player in [sounds.horn_player, sounds.motor_player, sounds.chime_player]:
		var playback: AudioStreamPlayback = player.stream.instantiate_playback()
		playback.start()
		var frames := playback.mix_audio(1.0, 4096)
		var peak := 0.0
		for frame in frames:
			peak = maxf(peak, absf(frame.x))
		if peak < 0.1:
			push_error("Audio stream produces silent or unexpectedly quiet samples")
			quit(1)
			return
	var capture := AudioEffectCapture.new()
	AudioServer.add_bus_effect(0, capture)
	sounds.horn()
	await create_timer(0.3).timeout
	var frames := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for frame in frames:
		peak = maxf(peak, absf(frame.x))
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	if peak < 0.05:
		push_error("Horn does not reach the Master audio output")
		quit(1)
		return
	var report: String = sounds.audio_report()
	if not report.contains("Output:"):
		push_error("Missing on-device audio output diagnostics")
		quit(1)
		return
	print("PASS: generated sounds decode and horn reaches Master output (peak %.3f); %s" % [peak, report])
	sounds.queue_free()
	await process_frame
	quit(0)
