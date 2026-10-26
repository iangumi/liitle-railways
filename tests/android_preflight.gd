extends SceneTree

# Read the effective setting with Godot's parser, not a permissive INI parser.
func _initialize() -> void:
	var key := "rendering/textures/vram_compression/import_etc2_astc"
	if not ProjectSettings.get_setting(key, false):
		push_error("Android export requires %s=true. Check project.godot syntax; comments must start with ';'." % key)
		quit(1)
		return
	print("PASS: Godot loaded Android ETC2/ASTC configuration")
	quit(0)
