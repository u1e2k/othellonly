class_name AIController
extends RefCounted

const DIFFICULTY_EASY: int = 0
const DIFFICULTY_NORMAL: int = 1
const DIFFICULTY_HARD: int = 2

# Standard 8x8 Positional evaluation weights for Reversi
const POSITIONAL_WEIGHTS: Array[int] = [
	 100, -20,  10,   5,   5,  10, -20,  100,
	 -20, -50,  -2,  -2,  -2,  -2, -50,  -20,
	  10,  -2,  -1,  -1,  -1,  -1,  -2,   10,
	   5,  -2,  -1,   0,   0,  -1,  -2,    5,
	   5,  -2,  -1,   0,   0,  -1,  -2,    5,
	  10,  -2,  -1,  -1,  -1,  -1,  -2,   10,
	 -20, -50,  -2,  -2,  -2,  -2, -50,  -20,
	 100, -20,  10,   5,   5,  10, -20,  100
]

const CORNERS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(7, 0),
	Vector2i(0, 7),
	Vector2i(7, 7)
]

const CORNER_NEIGHBORS: Dictionary = {
	Vector2i(0, 0): [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	Vector2i(7, 0): [Vector2i(6, 0), Vector2i(7, 1), Vector2i(6, 1)],
	Vector2i(0, 7): [Vector2i(0, 6), Vector2i(1, 7), Vector2i(1, 6)],
	Vector2i(7, 7): [Vector2i(6, 7), Vector2i(7, 6), Vector2i(6, 6)]
}

static func get_best_move(logic: ReversiLogic, color: int, difficulty: int) -> Vector2i:
	var valid_moves: Array[Vector2i] = logic.get_valid_moves(color)
	if valid_moves.is_empty():
		return Vector2i(-1, -1)
	
	if valid_moves.size() == 1:
		return valid_moves[0]
	
	match difficulty:
		DIFFICULTY_EASY:
			return _get_easy_move(valid_moves)
		DIFFICULTY_NORMAL:
			return _get_normal_move(logic, valid_moves, color)
		DIFFICULTY_HARD:
			return _get_hard_move(logic, valid_moves, color)
		_:
			return valid_moves[0]

static func _get_easy_move(valid_moves: Array[Vector2i]) -> Vector2i:
	var idx: int = randi() % valid_moves.size()
	return valid_moves[idx]

static func _get_normal_move(logic: ReversiLogic, valid_moves: Array[Vector2i], color: int) -> Vector2i:
	var best_score: int = -1
	var best_candidates: Array[Vector2i] = []
	
	for move in valid_moves:
		var flips: Array[Vector2i] = logic.get_flips(move, color)
		var flip_count: int = flips.size()
		if flip_count > best_score:
			best_score = flip_count
			best_candidates = [move]
		elif flip_count == best_score:
			best_candidates.append(move)
	
	return best_candidates[randi() % best_candidates.size()]

static func _get_hard_move(logic: ReversiLogic, valid_moves: Array[Vector2i], color: int) -> Vector2i:
	# Clone logic once so search runs on isolated sandbox with place_piece/undo
	var sim: ReversiLogic = logic.clone() as ReversiLogic
	
	var search_depth: int = 3
	var empty_count: int = logic.get_score()["empty"]
	if empty_count <= 6:
		search_depth = 4
	
	var best_move: Vector2i = valid_moves[0]
	var best_val: float = -INF
	var opponent: int = ReversiLogic.get_opponent(color)
	
	var shuffled: Array[Vector2i] = valid_moves.duplicate()
	shuffled.shuffle()
	
	for move in shuffled:
		sim.place_piece(move, color)
		var val: float = _minimax(sim, search_depth - 1, -INF, INF, false, color, opponent)
		sim.undo()
		
		if val > best_val:
			best_val = val
			best_move = move
	
	return best_move

static func _minimax(logic: ReversiLogic, depth: int, alpha: float, beta: float, is_max: bool, my_color: int, opp_color: int) -> float:
	if depth <= 0 or logic.check_game_over():
		return _evaluate_board(logic, my_color, opp_color)
	
	var current_color: int = my_color if is_max else opp_color
	var next_color: int = opp_color if is_max else my_color
	var moves: Array[Vector2i] = logic.get_valid_moves(current_color)
	
	if moves.is_empty():
		var opp_moves: Array[Vector2i] = logic.get_valid_moves(next_color)
		if opp_moves.is_empty():
			return _evaluate_board(logic, my_color, opp_color)
		return _minimax(logic, depth - 1, alpha, beta, not is_max, my_color, opp_color)
	
	if is_max:
		var max_eval: float = -INF
		for move in moves:
			logic.place_piece(move, current_color)
			var eval_score: float = _minimax(logic, depth - 1, alpha, beta, false, my_color, opp_color)
			logic.undo()
			max_eval = maxf(max_eval, eval_score)
			alpha = maxf(alpha, eval_score)
			if beta <= alpha:
				break
		return max_eval
	else:
		var min_eval: float = INF
		for move in moves:
			logic.place_piece(move, current_color)
			var eval_score: float = _minimax(logic, depth - 1, alpha, beta, true, my_color, opp_color)
			logic.undo()
			min_eval = minf(min_eval, eval_score)
			beta = minf(beta, eval_score)
			if beta <= alpha:
				break
		return min_eval

static func _evaluate_board(logic: ReversiLogic, my_color: int, opp_color: int) -> float:
	var score_dict: Dictionary = logic.get_score()
	var my_pieces: int = score_dict["black"] if my_color == ReversiLogic.BLACK else score_dict["white"]
	var opp_pieces: int = score_dict["white"] if my_color == ReversiLogic.BLACK else score_dict["black"]
	var empty_count: int = score_dict["empty"]
	
	if empty_count == 0 or (not logic.has_valid_moves(my_color) and not logic.has_valid_moves(opp_color)):
		if my_pieces > opp_pieces:
			return 10000.0 + (my_pieces - opp_pieces) * 10.0
		elif my_pieces < opp_pieces:
			return -10000.0 - (opp_pieces - my_pieces) * 10.0
		else:
			return 0.0
	
	var positional_score: float = 0.0
	
	for y in range(8):
		for x in range(8):
			var pos := Vector2i(x, y)
			var cell: int = logic.get_cell(pos)
			if cell == ReversiLogic.EMPTY:
				continue
			
			var weight: int = POSITIONAL_WEIGHTS[y * 8 + x]
			for corner_pos in CORNERS:
				var neighbors: Array = CORNER_NEIGHBORS.get(corner_pos, [])
				if neighbors.has(pos):
					var corner_owner: int = logic.get_cell(corner_pos)
					if corner_owner == cell:
						weight = 25
					elif corner_owner != ReversiLogic.EMPTY and corner_owner != cell:
						weight = -10
			
			if cell == my_color:
				positional_score += weight
			elif cell == opp_color:
				positional_score -= weight
	
	var my_moves_count: int = logic.get_valid_moves(my_color).size()
	var opp_moves_count: int = logic.get_valid_moves(opp_color).size()
	var mobility_score: float = 0.0
	if my_moves_count + opp_moves_count > 0:
		mobility_score = 100.0 * (my_moves_count - opp_moves_count) / float(my_moves_count + opp_moves_count)
	
	var my_corners: int = 0
	var opp_corners: int = 0
	for corner in CORNERS:
		var c_owner: int = logic.get_cell(corner)
		if c_owner == my_color:
			my_corners += 1
		elif c_owner == opp_color:
			opp_corners += 1
	var corner_score: float = 25.0 * (my_corners - opp_corners)
	
	var parity_weight: float = (64.0 - empty_count) / 64.0
	var piece_parity: float = 100.0 * (my_pieces - opp_pieces) / float(my_pieces + opp_pieces)
	
	return positional_score + (mobility_score * 2.0) + (corner_score * 4.0) + (piece_parity * parity_weight * 5.0)
