extends SceneTree

const ReversiLogic = preload("res://scripts/ReversiLogic.gd")

func _init() -> void:
	print("--- Running ReversiLogic Tests ---")
	test_initial_state()
	test_valid_moves_opening()
	test_place_piece_and_flips()
	test_undo()
	test_clone()
	test_ai()
	print("--- All ReversiLogic & AI Tests Passed! ---")
	quit(0)

func assert_true(cond: bool, msg: String = "Assertion failed") -> void:
	if not cond:
		push_error("FAIL: " + msg)
		print("FAIL: " + msg)
		quit(1)

func test_initial_state() -> void:
	var logic := ReversiLogic.new()
	var score := logic.get_score()
	assert_true(score["black"] == 2, "Black should start with 2 pieces")
	assert_true(score["white"] == 2, "White should start with 2 pieces")
	assert_true(score["empty"] == 60, "Empty squares should be 60")
	
	assert_true(logic.get_cell(Vector2i(3, 3)) == ReversiLogic.WHITE, "(3,3) should be White")
	assert_true(logic.get_cell(Vector2i(3, 4)) == ReversiLogic.BLACK, "(3,4) should be Black")
	assert_true(logic.get_cell(Vector2i(4, 3)) == ReversiLogic.BLACK, "(4,3) should be Black")
	assert_true(logic.get_cell(Vector2i(4, 4)) == ReversiLogic.WHITE, "(4,4) should be White")
	print("  [✓] test_initial_state passed")

func test_valid_moves_opening() -> void:
	var logic := ReversiLogic.new()
	var black_moves := logic.get_valid_moves(ReversiLogic.BLACK)
	assert_true(black_moves.size() == 4, "Black should have 4 valid opening moves")
	
	var expected_moves := [Vector2i(2, 3), Vector2i(3, 2), Vector2i(4, 5), Vector2i(5, 4)]
	for m in expected_moves:
		assert_true(black_moves.has(m), "Expected opening move %s not found in %s" % [m, black_moves])
	print("  [✓] test_valid_moves_opening passed")

func test_place_piece_and_flips() -> void:
	var logic := ReversiLogic.new()
	# Black plays (2, 3)
	var flipped := logic.place_piece(Vector2i(2, 3), ReversiLogic.BLACK)
	assert_true(flipped.size() == 1, "Should flip exactly 1 piece")
	assert_true(flipped.has(Vector2i(3, 3)), "Should have flipped (3,3)")
	assert_true(logic.get_cell(Vector2i(2, 3)) == ReversiLogic.BLACK, "New piece should be Black")
	assert_true(logic.get_cell(Vector2i(3, 3)) == ReversiLogic.BLACK, "Flipped piece should be Black")
	
	var score := logic.get_score()
	assert_true(score["black"] == 4, "Black score should be 4")
	assert_true(score["white"] == 1, "White score should be 1")
	print("  [✓] test_place_piece_and_flips passed")

func test_undo() -> void:
	var logic := ReversiLogic.new()
	assert_true(not logic.can_undo(), "Cannot undo at initial state")
	
	logic.place_piece(Vector2i(2, 3), ReversiLogic.BLACK)
	assert_true(logic.can_undo(), "Can undo after move")
	
	var res := logic.undo()
	assert_true(not res.is_empty(), "Undo returned valid record")
	var score := logic.get_score()
	assert_true(score["black"] == 2 and score["white"] == 2, "Scores restored after undo")
	assert_true(logic.get_cell(Vector2i(2, 3)) == ReversiLogic.EMPTY, "Cell reverted to empty")
	assert_true(logic.get_cell(Vector2i(3, 3)) == ReversiLogic.WHITE, "Flipped cell reverted to white")
	print("  [✓] test_undo passed")

func test_clone() -> void:
	var logic := ReversiLogic.new()
	logic.place_piece(Vector2i(2, 3), ReversiLogic.BLACK)
	
	var clone_logic: ReversiLogic = logic.clone() as ReversiLogic
	var score_orig: Dictionary = logic.get_score()
	var score_clone: Dictionary = clone_logic.get_score()
	assert_true(score_orig["black"] == score_clone["black"], "Cloned black score matches")
	assert_true(score_orig["white"] == score_clone["white"], "Cloned white score matches")
	
	# Mutate clone and check orig is unaffected
	clone_logic.place_piece(Vector2i(2, 2), ReversiLogic.WHITE)
	assert_true(logic.get_cell(Vector2i(2, 2)) == ReversiLogic.EMPTY, "Original logic was unchanged")
	print("  [✓] test_clone passed")

func test_ai() -> void:
	var logic := ReversiLogic.new()
	var AI = preload("res://scripts/AIController.gd")
	
	# Test Easy
	var easy_move: Vector2i = AI.get_best_move(logic, ReversiLogic.BLACK, AI.DIFFICULTY_EASY)
	assert_true(logic.is_valid_move(easy_move, ReversiLogic.BLACK), "Easy AI picked valid move")
	
	# Test Normal
	var normal_move: Vector2i = AI.get_best_move(logic, ReversiLogic.BLACK, AI.DIFFICULTY_NORMAL)
	assert_true(logic.is_valid_move(normal_move, ReversiLogic.BLACK), "Normal AI picked valid move")
	
	# Test Hard
	var hard_move: Vector2i = AI.get_best_move(logic, ReversiLogic.BLACK, AI.DIFFICULTY_HARD)
	assert_true(logic.is_valid_move(hard_move, ReversiLogic.BLACK), "Hard AI picked valid move")
	
	# Play automated game between Normal AI to verify completion and pass logic
	var sim_logic := ReversiLogic.new()
	var turn: int = ReversiLogic.BLACK
	var move_count: int = 0
	while not sim_logic.check_game_over() and move_count < 100:
		var moves := sim_logic.get_valid_moves(turn)
		if not moves.is_empty():
			var diff: int = AI.DIFFICULTY_NORMAL if move_count % 2 == 0 else AI.DIFFICULTY_EASY
			var chosen: Vector2i = AI.get_best_move(sim_logic, turn, diff)
			assert_true(sim_logic.is_valid_move(chosen, turn), "AI made valid move in simulation")
			sim_logic.place_piece(chosen, turn)
		turn = ReversiLogic.get_opponent(turn)
		move_count += 1
	
	assert_true(sim_logic.check_game_over(), "Simulation completed game successfully")
	var final_score := sim_logic.get_score()
	print("  [✓] test_ai passed (Simulated game result: Black=%d, White=%d, Empty=%d)" % [final_score["black"], final_score["white"], final_score["empty"]])
