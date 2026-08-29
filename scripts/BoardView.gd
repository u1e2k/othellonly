class_name BoardView
extends Control

signal cell_pressed(pos: Vector2i)

const CELL_VIEW_SCENE: PackedScene = preload("res://scenes/CellView.tscn")

@onready var board_frame: PanelContainer = $BoardFrame
@onready var grid_container: GridContainer = $BoardFrame/GridContainer

var cells: Array[CellView] = []
var cursor_pos: Vector2i = Vector2i(2, 3)
var cursor_visible: bool = true

var _sound_manager: SoundManager

func _ready() -> void:
	custom_minimum_size = Vector2(560, 560)
	_setup_grid()

func set_sound_manager(sm: SoundManager) -> void:
	_sound_manager = sm

func _setup_grid() -> void:
	if not cells.is_empty():
		return
	
	for child in grid_container.get_children():
		child.queue_free()
	cells.clear()
	
	for y in range(8):
		for x in range(8):
			var cell_node: CellView = CELL_VIEW_SCENE.instantiate() as CellView
			var pos := Vector2i(x, y)
			grid_container.add_child(cell_node)
			cell_node.setup(pos)
			cell_node.cell_clicked.connect(_on_cell_clicked)
			cells.append(cell_node)
	
	_refresh_cursors()

func get_cell_view(pos: Vector2i) -> CellView:
	if not ReversiLogic.in_bounds(pos) or cells.is_empty():
		return null
	return cells[pos.y * 8 + pos.x]

func update_board(logic: ReversiLogic, last_move: Vector2i = Vector2i(-1, -1)) -> void:
	for y in range(8):
		for x in range(8):
			var pos := Vector2i(x, y)
			var cell: CellView = get_cell_view(pos)
			if cell:
				cell.set_piece(logic.get_cell(pos), false)
				cell.set_last_move(pos == last_move)
	_refresh_cursors()

func show_valid_moves(valid_moves: Array[Vector2i]) -> void:
	for y in range(8):
		for x in range(8):
			var pos := Vector2i(x, y)
			var cell: CellView = get_cell_view(pos)
			if cell:
				cell.set_guide(valid_moves.has(pos))

func clear_guides() -> void:
	for cell in cells:
		cell.set_guide(false)

func animate_move(pos: Vector2i, color: int, flips: Array[Vector2i]) -> float:
	var placed_cell: CellView = get_cell_view(pos)
	if placed_cell:
		placed_cell.set_piece(color, true)
		if _sound_manager:
			_sound_manager.play_place()
	
	var flip_delay_step: float = 0.06
	var max_anim_time: float = 0.28
	
	for i in range(flips.size()):
		var flip_pos: Vector2i = flips[i]
		var flip_cell: CellView = get_cell_view(flip_pos)
		if flip_cell:
			var delay: float = float(i) * flip_delay_step
			flip_cell.play_flip(color, delay)
			
			if _sound_manager:
				get_tree().create_timer(delay + 0.05).timeout.connect(func():
					_sound_manager.play_flip(i)
				)
			
			max_anim_time = maxf(max_anim_time, delay + 0.28)
	
	for cell in cells:
		cell.set_last_move(cell.grid_pos == pos)
	
	_refresh_cursors()
	return max_anim_time

func move_cursor(delta_pos: Vector2i) -> void:
	cursor_pos.x = clampi(cursor_pos.x + delta_pos.x, 0, 7)
	cursor_pos.y = clampi(cursor_pos.y + delta_pos.y, 0, 7)
	cursor_visible = true
	_refresh_cursors()

func set_cursor_pos(pos: Vector2i) -> void:
	if ReversiLogic.in_bounds(pos):
		cursor_pos = pos
		_refresh_cursors()

func set_cursor_visible(visible: bool) -> void:
	cursor_visible = visible
	_refresh_cursors()

func get_cursor_pos() -> Vector2i:
	return cursor_pos

func _refresh_cursors() -> void:
	for cell in cells:
		cell.set_cursor(cursor_visible and cell.grid_pos == cursor_pos)

func _on_cell_clicked(pos: Vector2i) -> void:
	cursor_pos = pos
	cursor_visible = true
	_refresh_cursors()
	cell_pressed.emit(pos)
