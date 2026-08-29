class_name TopBar
extends Control

signal pause_pressed

@onready var p1_panel: PanelContainer = $HBox/Player1Card
@onready var p1_name_lbl: Label = $HBox/Player1Card/HBox/VBox/NameLabel
@onready var p1_score_lbl: Label = $HBox/Player1Card/HBox/ScoreLabel
@onready var p1_disc: Control = $HBox/Player1Card/HBox/DiscIcon
@onready var p1_thinking_lbl: Label = $HBox/Player1Card/HBox/VBox/ThinkingLabel

@onready var p2_panel: PanelContainer = $HBox/Player2Card
@onready var p2_name_lbl: Label = $HBox/Player2Card/HBox/VBox/NameLabel
@onready var p2_score_lbl: Label = $HBox/Player2Card/HBox/ScoreLabel
@onready var p2_disc: Control = $HBox/Player2Card/HBox/DiscIcon
@onready var p2_thinking_lbl: Label = $HBox/Player2Card/HBox/VBox/ThinkingLabel

@onready var mode_badge_lbl: Label = $HBox/CenterInfo/ModeBadge
@onready var pause_btn: Button = $HBox/PauseButton

const COLOR_ACTIVE_BORDER: Color = Color(0.20, 0.85, 0.60, 1.0)
const COLOR_INACTIVE_BORDER: Color = Color(0.18, 0.22, 0.28, 0.7)
const COLOR_THINKING: Color = Color(1.0, 0.80, 0.20, 1.0)

var _current_turn: int = ReversiLogic.BLACK
var _is_thinking: bool = false
var _thinking_timer: float = 0.0

func _ready() -> void:
	pause_btn.pressed.connect(func(): pause_pressed.emit())
	p1_disc.draw.connect(_draw_p1_disc)
	p2_disc.draw.connect(_draw_p2_disc)
	p1_thinking_lbl.visible = false
	p2_thinking_lbl.visible = false

func _process(delta: float) -> void:
	if _is_thinking:
		_thinking_timer += delta
		var dots: String = ".".repeat(int(_thinking_timer * 3.0) % 4)
		if _current_turn == ReversiLogic.BLACK:
			p1_thinking_lbl.text = "Thinking" + dots
		else:
			p2_thinking_lbl.text = "Thinking" + dots

func set_mode_title(title: String) -> void:
	mode_badge_lbl.text = title

func set_player_names(p1_name: String, p2_name: String) -> void:
	p1_name_lbl.text = p1_name
	p2_name_lbl.text = p2_name

func update_scores(black_score: int, white_score: int) -> void:
	p1_score_lbl.text = "%02d" % black_score
	p2_score_lbl.text = "%02d" % white_score

func set_turn(turn: int, is_cpu: bool = false) -> void:
	_current_turn = turn
	_is_thinking = is_cpu
	_thinking_timer = 0.0
	
	p1_thinking_lbl.visible = is_cpu and turn == ReversiLogic.BLACK
	p2_thinking_lbl.visible = is_cpu and turn == ReversiLogic.WHITE
	
	_update_card_style(p1_panel, turn == ReversiLogic.BLACK)
	_update_card_style(p2_panel, turn == ReversiLogic.WHITE)

func _update_card_style(panel: PanelContainer, is_active: bool) -> void:
	var sb: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if is_active:
		sb.border_color = COLOR_ACTIVE_BORDER
		sb.border_width_bottom = 3
		sb.border_width_top = 3
		sb.border_width_left = 3
		sb.border_width_right = 3
		sb.bg_color = Color(0.12, 0.18, 0.16, 0.95)
	else:
		sb.border_color = COLOR_INACTIVE_BORDER
		sb.border_width_bottom = 1
		sb.border_width_top = 1
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.bg_color = Color(0.09, 0.11, 0.15, 0.75)
	panel.add_theme_stylebox_override("panel", sb)

func _draw_p1_disc() -> void:
	var center := p1_disc.size * 0.5
	var r: float = minf(p1_disc.size.x, p1_disc.size.y) * 0.42
	p1_disc.draw_circle(center, r, Color(0.3, 0.35, 0.45, 1.0))
	p1_disc.draw_circle(center, r * 0.9, Color(0.1, 0.12, 0.16, 1.0))
	p1_disc.draw_circle(center + Vector2(-r * 0.25, -r * 0.25), r * 0.35, Color(0.4, 0.5, 0.6, 0.5))

func _draw_p2_disc() -> void:
	var center := p2_disc.size * 0.5
	var r: float = minf(p2_disc.size.x, p2_disc.size.y) * 0.42
	p2_disc.draw_circle(center, r, Color(0.75, 0.8, 0.85, 1.0))
	p2_disc.draw_circle(center, r * 0.9, Color(0.95, 0.96, 0.98, 1.0))
	p2_disc.draw_circle(center + Vector2(-r * 0.25, -r * 0.25), r * 0.35, Color(1.0, 1.0, 1.0, 0.8))
