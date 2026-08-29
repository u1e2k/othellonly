class_name GameController
extends Control

enum State {
	TITLE,
	IDLE,
	WAITING_INPUT,
	CPU_THINKING,
	ANIMATING,
	CHECK_TRANSITION,
	GAME_OVER,
	PAUSED
}

const MODE_1P_BLACK: int = 0
const MODE_1P_WHITE: int = 1
const MODE_2P_LOCAL: int = 2
const MODE_WATCH: int = 3

@onready var game_container: VBoxContainer = $CanvasLayer/GameContainer
@onready var top_bar: TopBar = $CanvasLayer/GameContainer/TopBar
@onready var board_view: BoardView = $CanvasLayer/GameContainer/CenterContainer/BoardView
@onready var bottom_bar: BottomBar = $CanvasLayer/GameContainer/BottomBar
@onready var title_screen: TitleScreen = $CanvasLayer/TitleScreen
@onready var pause_dialog: PauseDialog = $CanvasLayer/PauseDialog
@onready var game_over_dialog: GameOverDialog = $CanvasLayer/GameOverDialog
@onready var toast: Toast = $CanvasLayer/Toast
@onready var sound_manager: SoundManager = $SoundManager

var logic: ReversiLogic = ReversiLogic.new()
var state: State = State.TITLE

var game_mode: int = MODE_1P_BLACK
var player_color: int = ReversiLogic.BLACK
var ai_difficulty: int = AIController.DIFFICULTY_HARD
var current_turn: int = ReversiLogic.BLACK

var guide_enabled: bool = true
var sound_enabled: bool = true
var last_move_pos: Vector2i = Vector2i(-1, -1)

var _stick_cooldown: float = 0.0
const STICK_REPEAT_DELAY: float = 0.22

func _ready() -> void:
	board_view.set_sound_manager(sound_manager)
	
	# Wire Title signals
	title_screen.start_game.connect(_on_title_start_game)
	title_screen.open_settings_requested.connect(_open_pause_menu)
	
	# Wire UI signals
	board_view.cell_pressed.connect(_on_cell_pressed)
	top_bar.pause_pressed.connect(_open_pause_menu)
	bottom_bar.place_pressed.connect(_on_place_pressed)
	bottom_bar.undo_pressed.connect(_on_undo_pressed)
	bottom_bar.guide_toggled.connect(_on_guide_toggled)
	bottom_bar.menu_pressed.connect(_open_pause_menu)
	
	pause_dialog.resumed.connect(_on_pause_resumed)
	pause_dialog.restarted.connect(_on_game_restarted)
	pause_dialog.title_requested.connect(_return_to_title)
	pause_dialog.settings_changed.connect(_on_settings_changed)
	
	game_over_dialog.rematch_requested.connect(_on_rematch_requested)
	game_over_dialog.settings_requested.connect(_open_pause_menu)
	game_over_dialog.closed.connect(_on_game_over_closed)
	
	_show_title_screen()

func _process(delta: float) -> void:
	if state != State.WAITING_INPUT or not _is_human_turn():
		return
	
	# Analog stick continuous navigation
	if _stick_cooldown > 0.0:
		_stick_cooldown -= delta
	else:
		var stick_vec: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if stick_vec.length() > 0.5:
			var dir := Vector2i.ZERO
			if absf(stick_vec.x) > absf(stick_vec.y):
				dir.x = 1 if stick_vec.x > 0 else -1
			else:
				dir.y = 1 if stick_vec.y > 0 else -1
			
			if dir != Vector2i.ZERO:
				board_view.move_cursor(dir)
				sound_manager.play_click()
				_stick_cooldown = STICK_REPEAT_DELAY

func _input(event: InputEvent) -> void:
	if not is_inside_tree() or state == State.TITLE or state == State.PAUSED or pause_dialog.visible or game_over_dialog.visible:
		return
	
	# 1. System actions
	if event.is_action_pressed("ui_pause") or event.is_action_pressed("btn_start"):
		get_viewport().set_input_as_handled()
		_open_pause_menu()
		return
	
	if event.is_action_pressed("action_x") or event.is_action_pressed("btn_x"):
		get_viewport().set_input_as_handled()
		_on_guide_toggled()
		return
	
	if event.is_action_pressed("action_cancel") or event.is_action_pressed("btn_b") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_undo_pressed()
		return
	
	# 2. Board D-pad cursor movement (Discrete button presses for instant response)
	var move_dir := Vector2i.ZERO
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		move_dir.x -= 1
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		move_dir.x += 1
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		move_dir.y -= 1
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		move_dir.y += 1
	
	if move_dir != Vector2i.ZERO:
		get_viewport().set_input_as_handled()
		board_view.move_cursor(move_dir)
		sound_manager.play_click()
		return
	
	# 3. Main Action A button (Place piece)
	if event.is_action_pressed("action_accept") or event.is_action_pressed("btn_a") or event.is_action_pressed("ui_accept"):
		if state == State.WAITING_INPUT and _is_human_turn():
			get_viewport().set_input_as_handled()
			_on_place_pressed()
			return

func _show_title_screen() -> void:
	state = State.TITLE
	game_container.visible = false
	title_screen.visible = true
	title_screen.set_settings(ai_difficulty, sound_enabled, guide_enabled)
	title_screen.focus_first_button()

func _on_title_start_game(p_mode: int, p_color: int, p_diff: int, p_sound: bool, p_guide: bool) -> void:
	game_mode = p_mode
	player_color = p_color
	ai_difficulty = p_diff
	sound_enabled = p_sound
	sound_manager.enabled = p_sound
	guide_enabled = p_guide
	bottom_bar.set_guide_state(p_guide)
	
	sound_manager.play_click()
	title_screen.visible = false
	game_container.visible = true
	_start_new_game()

func _return_to_title() -> void:
	sound_manager.play_click()
	_show_title_screen()

func _start_new_game() -> void:
	logic.reset()
	current_turn = ReversiLogic.BLACK
	last_move_pos = Vector2i(-1, -1)
	
	_update_header_mode()
	_update_views()
	
	# Initial cursor placement on an active valid move (2, 3)
	board_view.set_cursor_pos(Vector2i(2, 3))
	board_view.set_cursor_visible(true)
	
	state = State.CHECK_TRANSITION
	_advance_turn()

func _update_header_mode() -> void:
	var mode_text := ""
	var p1_name := "1P (黒)"
	var p2_name := "CPU (白)"
	
	match game_mode:
		MODE_1P_BLACK:
			var diff_name := _get_diff_name(ai_difficulty)
			mode_text = "1P vs CPU (%s)" % diff_name
			p1_name = "YOU (黒)"
			p2_name = "CPU (白)"
		MODE_1P_WHITE:
			var diff_name := _get_diff_name(ai_difficulty)
			mode_text = "CPU vs 1P (%s)" % diff_name
			p1_name = "CPU (黒)"
			p2_name = "YOU (白)"
		MODE_2P_LOCAL:
			mode_text = "2P Local (対戦)"
			p1_name = "1P (黒)"
			p2_name = "2P (白)"
		MODE_WATCH:
			var diff_name := _get_diff_name(ai_difficulty)
			mode_text = "Watch (%s)" % diff_name
			p1_name = "CPU 1 (黒)"
			p2_name = "CPU 2 (白)"
	
	top_bar.set_mode_title(mode_text)
	top_bar.set_player_names(p1_name, p2_name)

func _get_diff_name(diff: int) -> String:
	match diff:
		AIController.DIFFICULTY_EASY:
			return "初級"
		AIController.DIFFICULTY_NORMAL:
			return "中級"
		AIController.DIFFICULTY_HARD:
			return "上級"
	return "NORMAL"

func _update_views() -> void:
	var score: Dictionary = logic.get_score()
	top_bar.update_scores(score["black"], score["white"])
	top_bar.set_turn(current_turn, not _is_human_turn())
	
	board_view.update_board(logic, last_move_pos)
	bottom_bar.set_undo_enabled(logic.can_undo() and state == State.WAITING_INPUT)
	
	if guide_enabled and _is_human_turn() and state == State.WAITING_INPUT:
		var valid_moves: Array[Vector2i] = logic.get_valid_moves(current_turn)
		board_view.show_valid_moves(valid_moves)
	else:
		board_view.clear_guides()

func _is_human_turn() -> bool:
	match game_mode:
		MODE_1P_BLACK:
			return current_turn == ReversiLogic.BLACK
		MODE_1P_WHITE:
			return current_turn == ReversiLogic.WHITE
		MODE_2P_LOCAL:
			return true
		MODE_WATCH:
			return false
	return false

func _advance_turn() -> void:
	if logic.check_game_over():
		_handle_game_over()
		return
	
	var valid_moves: Array[Vector2i] = logic.get_valid_moves(current_turn)
	if valid_moves.is_empty():
		_handle_pass()
		return
	
	if _is_human_turn():
		state = State.WAITING_INPUT
		board_view.set_cursor_visible(true)
		_update_views()
	else:
		state = State.CPU_THINKING
		_update_views()
		_run_cpu_turn()

func _run_cpu_turn() -> void:
	var think_time: float = randf_range(0.35, 0.45)
	await get_tree().create_timer(think_time).timeout
	
	if state != State.CPU_THINKING:
		return
	
	var cpu_move: Vector2i = AIController.get_best_move(logic, current_turn, ai_difficulty)
	if cpu_move != Vector2i(-1, -1) and logic.is_valid_move(cpu_move, current_turn):
		_execute_move(cpu_move)
	else:
		_handle_pass()

func _on_cell_pressed(pos: Vector2i) -> void:
	if state != State.WAITING_INPUT or not _is_human_turn():
		return
	
	if not logic.is_valid_move(pos, current_turn):
		sound_manager.play_invalid()
		return
	
	_execute_move(pos)

func _on_place_pressed() -> void:
	if state != State.WAITING_INPUT or not _is_human_turn():
		return
	
	var pos: Vector2i = board_view.get_cursor_pos()
	if not logic.is_valid_move(pos, current_turn):
		sound_manager.play_invalid()
		return
	
	_execute_move(pos)

func _execute_move(pos: Vector2i) -> void:
	state = State.ANIMATING
	board_view.clear_guides()
	
	last_move_pos = pos
	var flips: Array[Vector2i] = logic.place_piece(pos, current_turn)
	var anim_duration: float = board_view.animate_move(pos, current_turn, flips)
	
	var score: Dictionary = logic.get_score()
	top_bar.update_scores(score["black"], score["white"])
	
	await get_tree().create_timer(anim_duration + 0.05).timeout
	
	if state != State.ANIMATING:
		return
	
	current_turn = ReversiLogic.get_opponent(current_turn)
	state = State.CHECK_TRANSITION
	_advance_turn()

func _handle_pass() -> void:
	state = State.ANIMATING
	var pass_name := "黒" if current_turn == ReversiLogic.BLACK else "白"
	toast.show_message("%s の手番はパスです" % pass_name, 1.3)
	sound_manager.play_pass()
	
	await get_tree().create_timer(1.3).timeout
	
	current_turn = ReversiLogic.get_opponent(current_turn)
	state = State.CHECK_TRANSITION
	_advance_turn()

func _handle_game_over() -> void:
	state = State.GAME_OVER
	board_view.clear_guides()
	
	var score: Dictionary = logic.get_score()
	top_bar.update_scores(score["black"], score["white"])
	
	var is_1p: bool = (game_mode == MODE_1P_BLACK or game_mode == MODE_1P_WHITE)
	var p1_name := "1P (黒)"
	var p2_name := "CPU (白)"
	if game_mode == MODE_1P_BLACK:
		p1_name = "YOU (黒)"
		p2_name = "CPU (白)"
	elif game_mode == MODE_1P_WHITE:
		p1_name = "CPU (黒)"
		p2_name = "YOU (白)"
	elif game_mode == MODE_2P_LOCAL:
		p1_name = "1P (黒)"
		p2_name = "2P (白)"
	elif game_mode == MODE_WATCH:
		p1_name = "CPU 1 (黒)"
		p2_name = "CPU 2 (白)"
	
	if is_1p:
		var won: bool = (player_color == ReversiLogic.BLACK and score["black"] > score["white"]) or (player_color == ReversiLogic.WHITE and score["white"] > score["black"])
		if won:
			sound_manager.play_win()
		elif score["black"] == score["white"]:
			sound_manager.play_pass()
		else:
			sound_manager.play_lose()
	else:
		sound_manager.play_win()
	
	game_over_dialog.show_result(score["black"], score["white"], p1_name, p2_name, is_1p, player_color)

func _on_undo_pressed() -> void:
	if state != State.WAITING_INPUT or not logic.can_undo():
		sound_manager.play_invalid()
		return
	
	if game_mode == MODE_1P_BLACK or game_mode == MODE_1P_WHITE:
		var rec1: Dictionary = logic.undo()
		if logic.can_undo():
			var rec2: Dictionary = logic.undo()
			last_move_pos = rec2.get("move", Vector2i(-1, -1))
		else:
			last_move_pos = Vector2i(-1, -1)
		current_turn = player_color
	else:
		var rec: Dictionary = logic.undo()
		last_move_pos = rec.get("move", Vector2i(-1, -1))
		current_turn = ReversiLogic.get_opponent(current_turn)
	
	sound_manager.play_click()
	toast.show_message("一手戻しました", 1.0)
	
	_update_views()
	state = State.WAITING_INPUT

func _on_guide_toggled() -> void:
	guide_enabled = not guide_enabled
	bottom_bar.set_guide_state(guide_enabled)
	sound_manager.play_click()
	_update_views()

func _open_pause_menu() -> void:
	if pause_dialog.visible:
		return
	if state != State.TITLE:
		state = State.PAUSED
	sound_manager.play_click()
	pause_dialog.open(game_mode, ai_difficulty, sound_enabled, guide_enabled)

func _on_pause_resumed() -> void:
	sound_manager.play_click()
	if state == State.TITLE:
		title_screen.focus_first_button()
		return
	
	if logic.check_game_over():
		state = State.GAME_OVER
	else:
		state = State.CHECK_TRANSITION
		_advance_turn()

func _on_game_restarted(p_mode: int, p_color: int, p_diff: int, p_sound: bool, p_guide: bool) -> void:
	game_mode = p_mode
	player_color = p_color
	ai_difficulty = p_diff
	sound_enabled = p_sound
	sound_manager.enabled = p_sound
	guide_enabled = p_guide
	bottom_bar.set_guide_state(p_guide)
	
	sound_manager.play_click()
	title_screen.visible = false
	game_container.visible = true
	_start_new_game()

func _on_settings_changed(p_sound: bool, p_guide: bool) -> void:
	sound_enabled = p_sound
	sound_manager.enabled = p_sound
	guide_enabled = p_guide
	bottom_bar.set_guide_state(p_guide)
	title_screen.set_settings(ai_difficulty, sound_enabled, guide_enabled)
	_update_views()

func _on_rematch_requested() -> void:
	game_over_dialog.close()
	sound_manager.play_click()
	_start_new_game()

func _on_game_over_closed() -> void:
	sound_manager.play_click()
	_update_views()
