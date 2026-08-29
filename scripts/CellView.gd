class_name CellView
extends Control

signal cell_clicked(pos: Vector2i)

var grid_pos: Vector2i = Vector2i.ZERO
var current_color: int = ReversiLogic.EMPTY
var is_guide: bool = false
var is_last_move: bool = false
var is_hovered: bool = false

# Visual state for animation
var piece_scale: Vector2 = Vector2.ONE
var piece_elevation: float = 0.0 # Vertical offset when flipping
var display_color: int = ReversiLogic.EMPTY

var _tween: Tween

const COLOR_BOARD_BG: Color = Color(0.11, 0.28, 0.20, 1.0)       # Rich deep emerald felt
const COLOR_BOARD_ALT: Color = Color(0.09, 0.25, 0.18, 1.0)      # Subtle checker tone
const COLOR_GRID_LINE: Color = Color(0.06, 0.16, 0.12, 0.8)      # Grid line border
const COLOR_BLACK_PIECE: Color = Color(0.10, 0.12, 0.16, 1.0)    # Sleek dark slate
const COLOR_BLACK_RIM: Color = Color(0.25, 0.30, 0.38, 1.0)
const COLOR_WHITE_PIECE: Color = Color(0.94, 0.96, 0.98, 1.0)    # Pearl white
const COLOR_WHITE_RIM: Color = Color(0.75, 0.80, 0.86, 1.0)
const COLOR_GUIDE_DOT: Color = Color(0.20, 0.90, 0.65, 0.55)     # Glowing mint
const COLOR_LAST_MOVE: Color = Color(0.98, 0.75, 0.20, 0.90)     # Warm gold accent

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(64, 64)
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(pos: Vector2i) -> void:
	grid_pos = pos
	display_color = current_color
	queue_redraw()

func set_piece(color: int, animate: bool = false) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	
	current_color = color
	display_color = color
	piece_scale = Vector2.ONE
	piece_elevation = 0.0
	
	if animate and color != ReversiLogic.EMPTY:
		# Pop-in drop animation for placed stone
		piece_scale = Vector2(0.3, 0.3)
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(self, "piece_scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	queue_redraw()

func play_flip(new_color: int, delay: float = 0.0) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	
	current_color = new_color
	_tween = create_tween()
	
	if delay > 0.0:
		_tween.tween_interval(delay)
	
	# Phase 1: Scale down X, lift disc up slightly
	_tween.tween_property(self, "piece_scale", Vector2(0.05, 1.15), 0.11).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "piece_elevation", -4.0, 0.11)
	
	# Midpoint: swap color
	_tween.tween_callback(func():
		display_color = new_color
		queue_redraw()
	)
	
	# Phase 2: Scale back to 1.0, drop down
	_tween.tween_property(self, "piece_scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "piece_elevation", 0.0, 0.13)

func set_guide(active: bool) -> void:
	if is_guide != active:
		is_guide = active
		queue_redraw()

func set_last_move(active: bool) -> void:
	if is_last_move != active:
		is_last_move = active
		queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			cell_clicked.emit(grid_pos)
			accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			cell_clicked.emit(grid_pos)
			accept_event()

func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	
	# 1. Background Cell
	var is_alt: bool = (grid_pos.x + grid_pos.y) % 2 == 1
	var bg_col: Color = COLOR_BOARD_ALT if is_alt else COLOR_BOARD_BG
	if is_hovered and current_color == ReversiLogic.EMPTY:
		bg_col = bg_col.lightened(0.08)
	
	draw_rect(rect, bg_col, true)
	
	# Subtle inner cell border
	draw_rect(rect, COLOR_GRID_LINE, false, 1.0)
	
	# Subtle coordinate dot on board star points (3,3), (3,5), (5,3), (5,5) (1-indexed (2,2),(2,6),(6,2),(6,6))
	if (grid_pos.x == 2 or grid_pos.x == 6) and (grid_pos.y == 2 or grid_pos.y == 6):
		# Corner point dot
		pass
	
	# 2. Guide Dot for valid move
	if is_guide and current_color == ReversiLogic.EMPTY:
		var guide_radius: float = radius * 0.32
		# Soft glowing halo
		draw_circle(center, guide_radius * 1.4, Color(COLOR_GUIDE_DOT.r, COLOR_GUIDE_DOT.g, COLOR_GUIDE_DOT.b, 0.2))
		draw_circle(center, guide_radius, COLOR_GUIDE_DOT)
		draw_arc(center, guide_radius, 0, TAU, 24, Color(1, 1, 1, 0.6), 1.5, true)
	
	# 3. Piece Drawing
	if display_color != ReversiLogic.EMPTY:
		var piece_center := center + Vector2(0.0, piece_elevation)
		var rad_x: float = radius * piece_scale.x
		var rad_y: float = radius * piece_scale.y
		
		# Drop shadow
		if piece_scale.x > 0.05:
			var shadow_offset := Vector2(2.0, 3.0 - piece_elevation * 0.5)
			var shadow_rect := Rect2(piece_center + shadow_offset - Vector2(rad_x, rad_y), Vector2(rad_x * 2.0, rad_y * 2.0))
			draw_set_transform(piece_center + shadow_offset, 0.0, piece_scale)
			draw_circle(Vector2.ZERO, radius, Color(0, 0, 0, 0.35))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
		if rad_x > 1.0:
			draw_set_transform(piece_center, 0.0, piece_scale)
			
			if display_color == ReversiLogic.BLACK:
				# Outer rim / Bevel
				draw_circle(Vector2.ZERO, radius, COLOR_BLACK_RIM)
				# Main body
				draw_circle(Vector2.ZERO, radius * 0.94, COLOR_BLACK_PIECE)
				# Specular highlight (top-left)
				draw_circle(Vector2(-radius * 0.28, -radius * 0.28), radius * 0.45, Color(0.28, 0.34, 0.44, 0.45))
				draw_circle(Vector2(-radius * 0.35, -radius * 0.35), radius * 0.20, Color(0.45, 0.55, 0.70, 0.55))
			else:
				# Outer rim / Bevel
				draw_circle(Vector2.ZERO, radius, COLOR_WHITE_RIM)
				# Main body
				draw_circle(Vector2.ZERO, radius * 0.94, COLOR_WHITE_PIECE)
				# Specular highlight (top-left)
				draw_circle(Vector2(-radius * 0.26, -radius * 0.26), radius * 0.48, Color(1.0, 1.0, 1.0, 0.65))
				draw_circle(Vector2(-radius * 0.32, -radius * 0.32), radius * 0.22, Color(1.0, 1.0, 1.0, 0.90))
			
			# Last move indicator
			if is_last_move:
				draw_circle(Vector2.ZERO, radius * 0.22, COLOR_LAST_MOVE)
				draw_circle(Vector2.ZERO, radius * 0.10, Color(1, 1, 1, 0.9))
			
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
