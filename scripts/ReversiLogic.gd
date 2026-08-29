class_name ReversiLogic
extends RefCounted

const BOARD_SIZE: int = 8
const EMPTY: int = 0
const BLACK: int = 1
const WHITE: int = 2

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, 1),   # Down
	Vector2i(0, -1),  # Up
	Vector2i(1, 0),   # Right
	Vector2i(-1, 0),  # Left
	Vector2i(1, 1),   # Down-Right
	Vector2i(1, -1),  # Up-Right
	Vector2i(-1, 1),  # Down-Left
	Vector2i(-1, -1)  # Up-Left
]

# 8x8 Board stored as an array of 64 integers (index = y * 8 + x)
var board: Array[int] = []
var history: Array[Dictionary] = []

func _init() -> void:
	reset()

static func get_opponent(color: int) -> int:
	if color == BLACK:
		return WHITE
	elif color == WHITE:
		return BLACK
	return EMPTY

static func in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE

func get_cell(pos: Vector2i) -> int:
	if not in_bounds(pos):
		return EMPTY
	return board[pos.y * BOARD_SIZE + pos.x]

func set_cell(pos: Vector2i, color: int) -> void:
	if in_bounds(pos):
		board[pos.y * BOARD_SIZE + pos.x] = color

func reset() -> void:
	board.resize(BOARD_SIZE * BOARD_SIZE)
	board.fill(EMPTY)
	history.clear()
	
	# Standard Othello initial setup
	# (3, 3) = White, (3, 4) = Black, (4, 3) = Black, (4, 4) = White
	set_cell(Vector2i(3, 3), WHITE)
	set_cell(Vector2i(3, 4), BLACK)
	set_cell(Vector2i(4, 3), BLACK)
	set_cell(Vector2i(4, 4), WHITE)

func get_flips_in_direction(pos: Vector2i, color: int, dir: Vector2i) -> Array[Vector2i]:
	var opponent: int = get_opponent(color)
	if opponent == EMPTY:
		return []
	
	var flips: Array[Vector2i] = []
	var cur: Vector2i = pos + dir
	
	while in_bounds(cur) and get_cell(cur) == opponent:
		flips.append(cur)
		cur += dir
	
	# Valid flip only if bracketed by current color piece
	if in_bounds(cur) and get_cell(cur) == color and not flips.is_empty():
		return flips
	
	return []

func get_flips(pos: Vector2i, color: int) -> Array[Vector2i]:
	if not in_bounds(pos) or get_cell(pos) != EMPTY:
		return []
	
	var all_flips: Array[Vector2i] = []
	for dir in DIRECTIONS:
		var dir_flips: Array[Vector2i] = get_flips_in_direction(pos, color, dir)
		if not dir_flips.is_empty():
			all_flips.append_array(dir_flips)
	
	return all_flips

func is_valid_move(pos: Vector2i, color: int) -> bool:
	if not in_bounds(pos) or get_cell(pos) != EMPTY:
		return false
	
	for dir in DIRECTIONS:
		if not get_flips_in_direction(pos, color, dir).is_empty():
			return true
	return false

func get_valid_moves(color: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var pos := Vector2i(x, y)
			if is_valid_move(pos, color):
				moves.append(pos)
	return moves

func has_valid_moves(color: int) -> bool:
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			if is_valid_move(Vector2i(x, y), color):
				return true
	return false

func place_piece(pos: Vector2i, color: int) -> Array[Vector2i]:
	var flips: Array[Vector2i] = get_flips(pos, color)
	if flips.is_empty():
		return []
	
	# Push current snapshot before mutating
	history.push_back({
		"board": board.duplicate(),
		"move": pos,
		"color": color,
		"flips": flips.duplicate()
	})
	
	set_cell(pos, color)
	for flip_pos in flips:
		set_cell(flip_pos, color)
	
	return flips

func can_undo() -> bool:
	return not history.is_empty()

func undo() -> Dictionary:
	if history.is_empty():
		return {}
	
	var record: Dictionary = history.pop_back()
	board = record["board"].duplicate()
	return record

func check_game_over() -> bool:
	var score: Dictionary = get_score()
	if score["empty"] == 0:
		return true
	if score["black"] == 0 or score["white"] == 0:
		return true
	return not has_valid_moves(BLACK) and not has_valid_moves(WHITE)

func get_score() -> Dictionary:
	var count_black: int = 0
	var count_white: int = 0
	var count_empty: int = 0
	
	for cell in board:
		if cell == BLACK:
			count_black += 1
		elif cell == WHITE:
			count_white += 1
		else:
			count_empty += 1
	
	return {
		"black": count_black,
		"white": count_white,
		"empty": count_empty
	}

func clone() -> RefCounted:
	var copy: RefCounted = (get_script() as GDScript).new()
	copy.board = self.board.duplicate()
	copy.history = self.history.duplicate(true)
	return copy
