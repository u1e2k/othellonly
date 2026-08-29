extends SceneTree

func _init() -> void:
	print("--- Running Main Scene Integration Test ---")
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	if main_scene == null:
		push_error("FAIL: Main.tscn could not be loaded")
		quit(1)
		return
	
	var main_node: Node = main_scene.instantiate()
	root.add_child(main_node)
	
	print("  [✓] Main scene instantiated and added to root")
	
	var game_ctrl := main_node as GameController
	if game_ctrl == null:
		push_error("FAIL: Main node is not GameController")
		quit(1)
		return
	
	# Verify opening move validation
	var valid: bool = game_ctrl.logic.is_valid_move(Vector2i(2, 3), ReversiLogic.BLACK)
	if not valid:
		push_error("FAIL: Opening move (2,3) was not valid")
		quit(1)
		return
	print("  [✓] Move validation verified")
	
	# Test Guide toggle
	game_ctrl._on_guide_toggled()
	print("  [✓] Guide toggle tested")
	
	# Test mode restart
	game_ctrl._on_game_restarted(GameController.MODE_2P_LOCAL, ReversiLogic.BLACK, AIController.DIFFICULTY_NORMAL, true, true)
	print("  [✓] Game restart in 2P mode tested")
	
	main_node.queue_free()
	print("--- Main Scene Integration Test Passed Successfully! ---")
	quit(0)
