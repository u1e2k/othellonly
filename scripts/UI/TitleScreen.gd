class_name TitleScreen
extends Control

signal start_game(mode: int, player_color: int, ai_diff: int, sound_on: bool, guide_on: bool)
signal open_settings_requested

@onready var btn_1p_black: Button = $CenterContainer/VBox/MenuVBox/Btn1PBlack
@onready var btn_1p_white: Button = $CenterContainer/VBox/MenuVBox/Btn1PWhite
@onready var btn_2p: Button = $CenterContainer/VBox/MenuVBox/Btn2P
@onready var btn_watch: Button = $CenterContainer/VBox/MenuVBox/BtnWatch
@onready var btn_settings: Button = $CenterContainer/VBox/MenuVBox/BtnSettings

@onready var logo_disc: Control = $CenterContainer/VBox/LogoContainer/LogoDisc
@onready var diff_lbl: Label = $CenterContainer/VBox/MenuVBox/DiffLabel

var current_diff: int = AIController.DIFFICULTY_HARD
var sound_enabled: bool = true
var guide_enabled: bool = true

var _anim_rot: float = 0.0

func _ready() -> void:
	btn_1p_black.pressed.connect(_on_1p_black_pressed)
	btn_1p_white.pressed.connect(_on_1p_white_pressed)
	btn_2p.pressed.connect(_on_2p_pressed)
	btn_watch.pressed.connect(_on_watch_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	logo_disc.draw.connect(_draw_logo_disc)
	
	_update_diff_label()
	btn_1p_black.grab_focus()

func _process(delta: float) -> void:
	_anim_rot += delta * 1.5
	logo_disc.queue_redraw()

func _update_diff_label() -> void:
	var diff_str := "上級 (HARD)"
	match current_diff:
		AIController.DIFFICULTY_EASY:
			diff_str = "初級 (EASY)"
		AIController.DIFFICULTY_NORMAL:
			diff_str = "中級 (NORMAL)"
		AIController.DIFFICULTY_HARD:
			diff_str = "上級 (HARD)"
	diff_lbl.text = "CPU難易度: %s" % diff_str

func set_settings(diff: int, sound: bool, guide: bool) -> void:
	current_diff = diff
	sound_enabled = sound
	guide_enabled = guide
	_update_diff_label()

func _on_1p_black_pressed() -> void:
	start_game.emit(GameController.MODE_1P_BLACK, ReversiLogic.BLACK, current_diff, sound_enabled, guide_enabled)

func _on_1p_white_pressed() -> void:
	start_game.emit(GameController.MODE_1P_WHITE, ReversiLogic.WHITE, current_diff, sound_enabled, guide_enabled)

func _on_2p_pressed() -> void:
	start_game.emit(GameController.MODE_2P_LOCAL, ReversiLogic.BLACK, current_diff, sound_enabled, guide_enabled)

func _on_watch_pressed() -> void:
	start_game.emit(GameController.MODE_WATCH, ReversiLogic.BLACK, current_diff, sound_enabled, guide_enabled)

func _on_settings_pressed() -> void:
	open_settings_requested.emit()

func focus_first_button() -> void:
	btn_1p_black.grab_focus()

func _draw_logo_disc() -> void:
	var center := logo_disc.size * 0.5
	var r: float = minf(logo_disc.size.x, logo_disc.size.y) * 0.44
	
	# Outer glowing ring
	var glow_col := Color(0.20, 0.85, 0.60, 0.4 + sin(_anim_rot * 2.0) * 0.2)
	logo_disc.draw_arc(center, r + 6.0, 0, TAU, 36, glow_col, 3.0, true)
	
	# Yin-yang / Dual color split Reversi disc
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
