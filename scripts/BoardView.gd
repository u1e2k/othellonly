class_name BoardView
extends Control

signal cell_pressed(pos: Vector2i)

const CELL_VIEW_SCENE: PackedScene = preload("res://scenes/CellView.tscn")

@onready var grid_container: GridContainer = $BoardFrame/GridContainer
@onready var board_frame: PanelContainer = $BoardFrame

var cells: Array[CellView] = []
var cursor_pos: Vector2i = Vector2i(3, 3)
var cursor_visible: bool = false
var cursor_pulse: float = 0.0

var _sound_manager: SoundManager

# Cursor aesthetic colors
const COLOR_CURSOR: Color = Color(0.20, 0.85, 1.0, 0.95)         # Neon cyan highlight
const COLOR_CURSOR_GLOW: Color = Color(0.20, 0.85, 1.0, 0.30)
const COLOR_STAR_DOT: Color = Color(0.05, 0.12, 0.09, 0.9)

func _ready() -> void:
	custom_minimum_size = Vector2(560, 560)
	_setup_grid()

func set_sound_manager(sm: SoundManager) -> void:
	_sound_manager = sm

func _process(delta: float) -> void:
	if cursor_visible:
		cursor_pulse = wrapf(cursor_pulse + delta * 3.5, 0.0, TAU)
		queue_redraw()

func _setup_grid() -> void:
	if not cells.is_empty():
		return
	
	# Clear existing children in grid_container if any
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
	# 1. Place stone with pop animation
	var placed_cell: CellView = get_cell_view(pos)
	if placed_cell:
		placed_cell.set_piece(color, true)
		if _sound_manager:
			_sound_manager.play_place()
	
	# 2. Sequential cascaded flips
	var flip_delay_step: float = 0.06
	var max_anim_time: float = 0.28
	
	for i in range(flips.size()):
		var flip_pos: Vector2i = flips[i]
		var flip_cell: CellView = get_cell_view(flip_pos)
		if flip_cell:
			var delay: float = float(i) * flip_delay_step
			flip_cell.play_flip(color, delay)
			
			# Schedule flip sound with slight cascade pitch
			if _sound_manager:
				get_tree().create_timer(delay + 0.05).timeout.connect(func():
					_sound_manager.play_flip(i)
				)
			
			max_anim_time = maxf(max_anim_time, delay + 0.28)
	
	# Mark last move
	for cell in cells:
		cell.set_last_move(cell.grid_pos == pos)
	
	return max_anim_time

func move_cursor(delta_pos: Vector2i) -> void:
	cursor_pos.x = clampi(cursor_pos.x + delta_pos.x, 0, 7)
	cursor_pos.y = clampi(cursor_pos.y + delta_pos.y, 0, 7)
	cursor_visible = true
	queue_redraw()

func set_cursor_pos(pos: Vector2i) -> void:
	if ReversiLogic.in_bounds(pos):
		cursor_pos = pos
		queue_redraw()

func set_cursor_visible(visible: bool) -> void:
	if cursor_visible != visible:
		cursor_visible = visible
		queue_redraw()

func get_cursor_pos() -> Vector2i:
	return cursor_pos

func _on_cell_clicked(pos: Vector2i) -> void:
	cursor_pos = pos
	# In touch mode, clicking a cell targets it directly
	cell_pressed.emit(pos)

func _draw() -> void:
	if not cursor_visible or cells.is_empty():
		return
	
	var cell: CellView = get_cell_view(cursor_pos)
	if not cell or not is_instance_valid(cell):
		return
	
	# Calculate global rect of target cell relative to this BoardView
	var cell_rect: Rect2 = cell.get_global_rect()
	var my_global_pos: Vector2 = get_global_position()
	var local_rect := Rect2(cell_rect.position - my_global_pos, cell_rect.size)
	
	# Draw animated futuristic corner brackets & pulsing border
	var pulse_sin: float = (sin(cursor_pulse) + 1.0) * 0.5 # 0.0 to 1.0
	var border_width: float = 3.0 + pulse_sin * 1.5
	var expand: float = 2.0 + pulse_sin * 2.0
	var outer_rect: Rect2 = local_rect.grow(expand)
	
	# Soft outer glow
	draw_rect(outer_rect.grow(2.0), COLOR_CURSOR_GLOW, false, 3.0)
	
	# Corner bracket lines (top-left, top-right, bottom-left, bottom-right)
	var corner_len: float = outer_rect.size.x * 0.30
	var col := COLOR_CURSOR
	
	# TL
	draw_line(outer_rect.position, outer_rect.position + Vector2(corner_len, 0), col, border_width)
	draw_line(outer_rect.position, outer_rect.position + Vector2(0, corner_len), col, border_width)
	# TR
	var tr := outer_rect.position + Vector2(outer_rect.size.x, 0)
	draw_line(tr, tr + Vector2(-corner_len, 0), col, border_width)
	draw_line(tr, tr + Vector2(0, corner_len), col, border_width)
	# BL
	var bl := outer_rect.position + Vector2(0, outer_rect.size.y)
	draw_line(bl, bl + Vector2(corner_len, 0), col, border_width)
	draw_line(bl, bl + Vector2(0, -corner_len), col, border_width)
	# BR
	var br := outer_rect.position + outer_rect.size
	draw_line(br, br + Vector2(-corner_len, 0), col, border_width)
	draw_line(br, br + Vector2(0, -corner_len), col, border_width)
