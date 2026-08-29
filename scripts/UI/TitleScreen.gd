class_name TitleScreen
extends Control

signal start_game(mode: int, player_color: int, ai_diff: int, sound_on: bool, guide_on: bool)
signal open_settings_requested

@onready var main_menu_vbox: VBoxContainer = $CenterContainer/VBox/MainMenuVBox
@onready var btn_1p_black: Button = $CenterContainer/VBox/MainMenuVBox/Btn1PBlack
@onready var btn_1p_white: Button = $CenterContainer/VBox/MainMenuVBox/Btn1PWhite
@onready var btn_2p: Button = $CenterContainer/VBox/MainMenuVBox/Btn2P
@onready var btn_watch: Button = $CenterContainer/VBox/MainMenuVBox/BtnWatch
@onready var btn_settings: Button = $CenterContainer/VBox/MainMenuVBox/BtnSettings

# Difficulty Selection Submenu
@onready var diff_modal: PanelContainer = $CenterContainer/VBox/DiffModal
@onready var diff_title_lbl: Label = $CenterContainer/VBox/DiffModal/Margin/VBox/DiffTitleLabel
@onready var btn_diff_easy: Button = $CenterContainer/VBox/DiffModal/Margin/VBox/BtnEasy
@onready var btn_diff_normal: Button = $CenterContainer/VBox/DiffModal/Margin/VBox/BtnNormal
@onready var btn_diff_hard: Button = $CenterContainer/VBox/DiffModal/Margin/VBox/BtnHard
@onready var btn_diff_back: Button = $CenterContainer/VBox/DiffModal/Margin/VBox/BtnBack

@onready var logo_disc: Control = $CenterContainer/VBox/LogoContainer/LogoDisc

var pending_mode: int = GameController.MODE_1P_BLACK
var pending_color: int = ReversiLogic.BLACK
var current_diff: int = AIController.DIFFICULTY_HARD
var sound_enabled: bool = true
var guide_enabled: bool = true

var _main_menu_buttons: Array[Button] = []
var _diff_menu_buttons: Array[Button] = []
var _selected_idx: int = 0

var _anim_rot: float = 0.0

func _ready() -> void:
	_main_menu_buttons = [btn_1p_black, btn_1p_white, btn_2p, btn_watch, btn_settings]
	_diff_menu_buttons = [btn_diff_easy, btn_diff_normal, btn_diff_hard, btn_diff_back]
	
	# Main menu button signals
	btn_1p_black.pressed.connect(_on_1p_black_pressed)
	btn_1p_white.pressed.connect(_on_1p_white_pressed)
	btn_2p.pressed.connect(_on_2p_pressed)
	btn_watch.pressed.connect(_on_watch_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	
	# Difficulty modal button signals
	btn_diff_easy.pressed.connect(func(): _choose_difficulty_and_start(AIController.DIFFICULTY_EASY))
	btn_diff_normal.pressed.connect(func(): _choose_difficulty_and_start(AIController.DIFFICULTY_NORMAL))
	btn_diff_hard.pressed.connect(func(): _choose_difficulty_and_start(AIController.DIFFICULTY_HARD))
	btn_diff_back.pressed.connect(_close_diff_modal)
	
	logo_disc.draw.connect(_draw_logo_disc)
	
	diff_modal.visible = false
	main_menu_vbox.visible = true
	_selected_idx = 0
	btn_1p_black.grab_focus()

func _process(delta: float) -> void:
	_anim_rot += delta * 1.5
	logo_disc.queue_redraw()

func set_settings(diff: int, sound: bool, guide: bool) -> void:
	current_diff = diff
	sound_enabled = sound
	guide_enabled = guide

func focus_first_button() -> void:
	if diff_modal.visible:
		_focus_current_diff_button()
	else:
		_selected_idx = 0
		btn_1p_black.grab_focus()

func _focus_current_diff_button() -> void:
	match current_diff:
		AIController.DIFFICULTY_EASY:
			_selected_idx = 0
			btn_diff_easy.grab_focus()
		AIController.DIFFICULTY_NORMAL:
			_selected_idx = 1
			btn_diff_normal.grab_focus()
		AIController.DIFFICULTY_HARD:
			_selected_idx = 2
			btn_diff_hard.grab_focus()
		_:
			_selected_idx = 2
			btn_diff_hard.grab_focus()

func _on_1p_black_pressed() -> void:
	pending_mode = GameController.MODE_1P_BLACK
	pending_color = ReversiLogic.BLACK
	_open_diff_modal("1P vs CPU (黒・先手) - 難易度を選択")

func _on_1p_white_pressed() -> void:
	pending_mode = GameController.MODE_1P_WHITE
	pending_color = ReversiLogic.WHITE
	_open_diff_modal("1P vs CPU (白・後手) - 難易度を選択")

func _on_watch_pressed() -> void:
	pending_mode = GameController.MODE_WATCH
	pending_color = ReversiLogic.BLACK
	_open_diff_modal("Watch Mode - CPU難易度を選択")

func _on_2p_pressed() -> void:
	start_game.emit(GameController.MODE_2P_LOCAL, ReversiLogic.BLACK, current_diff, sound_enabled, guide_enabled)

func _open_diff_modal(title_text: String) -> void:
	diff_title_lbl.text = title_text
	main_menu_vbox.visible = false
	diff_modal.visible = true
	_focus_current_diff_button()

func _close_diff_modal() -> void:
	diff_modal.visible = false
	main_menu_vbox.visible = true
	match pending_mode:
		GameController.MODE_1P_BLACK:
			_selected_idx = 0
			btn_1p_black.grab_focus()
		GameController.MODE_1P_WHITE:
			_selected_idx = 1
			btn_1p_white.grab_focus()
		GameController.MODE_WATCH:
			_selected_idx = 3
			btn_watch.grab_focus()
		_:
			_selected_idx = 0
			btn_1p_black.grab_focus()

func _choose_difficulty_and_start(diff: int) -> void:
	current_diff = diff
	diff_modal.visible = false
	main_menu_vbox.visible = true
	start_game.emit(pending_mode, pending_color, current_diff, sound_enabled, guide_enabled)

func _on_settings_pressed() -> void:
	open_settings_requested.emit()

func _input(event: InputEvent) -> void:
	if not visible or not is_inside_tree():
		return
	
	# B button / cancel
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("action_cancel") or event.is_action_pressed("btn_b"):
		if diff_modal.visible:
			get_viewport().set_input_as_handled()
			_close_diff_modal()
			return
	
	# D-pad Up / Down menu navigation
	var active_list: Array[Button] = _diff_menu_buttons if diff_modal.visible else _main_menu_buttons
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_selected_idx = wrapi(_selected_idx - 1, 0, active_list.size())
		active_list[_selected_idx].grab_focus()
		return
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_selected_idx = wrapi(_selected_idx + 1, 0, active_list.size())
		active_list[_selected_idx].grab_focus()
		return
	
	# A button / accept
	if event.is_action_pressed("action_accept") or event.is_action_pressed("btn_a") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		var focused: Control = get_viewport().gui_get_focus_owner()
		if focused and focused is Button and is_ancestor_of(focused) and focused.is_visible_in_tree():
			focused.emit_signal("pressed")
		else:
			# If no focus, activate current selected index
			if _selected_idx >= 0 and _selected_idx < active_list.size():
				active_list[_selected_idx].emit_signal("pressed")
		return

func _draw_logo_disc() -> void:
	var center := logo_disc.size * 0.5
	var r: float = minf(logo_disc.size.x, logo_disc.size.y) * 0.44
	
	var glow_col := Color(0.20, 0.85, 0.60, 0.4 + sin(_anim_rot * 2.0) * 0.2)
	logo_disc.draw_arc(center, r + 6.0, 0, TAU, 36, glow_col, 3.0, true)
	
	var cos_a := cos(_anim_rot)
	var scale_x := absf(cos_a)
	var show_black := cos_a >= 0.0
	
	logo_disc.draw_set_transform(center, 0.0, Vector2(maxf(scale_x, 0.05), 1.0))
	if show_black:
		logo_disc.draw_circle(Vector2.ZERO, r, Color(0.25, 0.30, 0.38, 1.0))
		logo_disc.draw_circle(Vector2.ZERO, r * 0.92, Color(0.10, 0.12, 0.16, 1.0))
		logo_disc.draw_circle(Vector2(-r * 0.28, -r * 0.28), r * 0.40, Color(0.40, 0.50, 0.65, 0.45))
	else:
		logo_disc.draw_circle(Vector2.ZERO, r, Color(0.75, 0.80, 0.86, 1.0))
		logo_disc.draw_circle(Vector2.ZERO, r * 0.92, Color(0.95, 0.96, 0.98, 1.0))
		logo_disc.draw_circle(Vector2(-r * 0.28, -r * 0.28), r * 0.40, Color(1.0, 1.0, 1.0, 0.85))
	logo_disc.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
