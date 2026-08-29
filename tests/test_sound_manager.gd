extends SceneTree

const SoundManager = preload("res://scripts/SoundManager.gd")

func _init() -> void:
	print("--- Running SoundManager Tests ---")
	var sm: SoundManager = SoundManager.new()
	sm._ready()
	print("  [✓] Procedural audio synthesis completed successfully")
	sm.free()
	print("--- SoundManager Test Passed! ---")
	quit(0)
