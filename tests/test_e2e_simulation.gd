extends SceneTree

func _init() -> void:
	print("--- Running End-to-End Simulation Test ---")
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main_node: Node = main_scene.instantiate()
	root.add_child(main_node)
	
	# Allow node to enter tree and call _ready
	var timer := create_timer(0.1)
	timer.timeout.connect(func():
		var gc := main_node as GameController
		print("  [✓] GameController state after startup: %s" % gc.state)
		
		# Set to Watch Mode (CPU vs CPU) to simulate full game
		gc._on_game_restarted(GameController.MODE_WATCH, ReversiLogic.BLACK, AIController.DIFFICULTY_EASY, false, false)
		print("  [✓] Watch mode started")
		
		# Let it run for 1.5 seconds of simulated moves
		var sim_timer := create_timer(1.5)
		sim_timer.timeout.connect(func():
			var score: Dictionary = gc.logic.get_score()
			print("  [✓] Active game score: Black=%d, White=%d, Empty=%d" % [score["black"], score["white"], score["empty"]])
			main_node.queue_free()
			print("--- End-to-End Simulation Test Succeeded! ---")
			quit(0)
		)
	)
