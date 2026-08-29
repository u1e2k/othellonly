class_name GameOverDialog
extends Control

signal rematch_requested
signal settings_requested
signal closed

@onready var title_lbl: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/TitleLabel
@onready var result_msg_lbl: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/ResultMsgLabel
@onready var p1_score_lbl: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/ScoreHBox/P1Card/VBox/ScoreLabel
@onready var p2_score_lbl: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/ScoreHBox/P2Card/VBox/ScoreLabel
@onready var p1_name_lbl: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/ScoreHBox/P1Card/VBox/NameLabel
@onready var p2_name_lbl: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/ScoreHBox/P2Card/VBox/NameLabel
@onready var p1_disc: Control = $CenterContainer/PanelContainer/MarginContainer/VBox/ScoreHBox/P1Card/VBox/DiscIcon
@onready var p2_disc: Control = $CenterContainer/PanelContainer/MarginContainer/VBox/ScoreHBox/P2Card/VBox/DiscIcon

@onready var rematch_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/ButtonVBox/RematchButton
@onready var settings_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/ButtonVBox/SettingsButton
@onready var close_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/ButtonVBox/CloseButton

func _ready() -> void:
	visible = false
	rematch_btn.pressed.connect(func(): rematch_requested.emit())
	settings_btn.pressed.connect(func(): settings_requested.emit())
	close_btn.pressed.connect(func(): close(); closed.emit())
	p1_disc.draw.connect(_draw_p1_disc)
	p2_disc.draw.connect(_draw_p2_disc)

func show_result(black_score: int, white_score: int, p1_name: String, p2_name: String, is_1p_mode: bool, player_color: int) -> void:
	p1_name_lbl.text = p1_name
	p2_name_lbl.text = p2_name
	p1_score_lbl.text = "%d" % black_score
	p2_score_lbl.text = "%d" % white_score
	
	if black_score > white_score:
		if is_1p_mode:
			if player_color == ReversiLogic.BLACK:
				title_lbl.text = "🎉 YOU WIN!"
				title_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6, 1))
				result_msg_lbl.text = "黒の勝利です！お見事！"
			else:
				title_lbl.text = "DEFEAT..."
				title_lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1))
				result_msg_lbl.text = "黒（CPU）の勝利です。"
		else:
			title_lbl.text = "🎉 黒の勝利！"
			title_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6, 1))
			result_msg_lbl.text = "%s の勝利です！" % p1_name
	elif white_score > black_score:
		if is_1p_mode:
			if player_color == ReversiLogic.WHITE:
				title_lbl.text = "🎉 YOU WIN!"
				title_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6, 1))
				result_msg_lbl.text = "白の勝利です！お見事！"
			else:
				title_lbl.text = "DEFEAT..."
				title_lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1))
				result_msg_lbl.text = "白（CPU）の勝利です。"
		else:
			title_lbl.text = "🎉 白の勝利！"
			title_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6, 1))
			result_msg_lbl.text = "%s の勝利です！" % p2_name
	else:
		title_lbl.text = "🤝 DRAW"
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1))
		result_msg_lbl.text = "同点で引き分けです！"
	
	visible = true
	rematch_btn.grab_focus()

func close() -> void:
	visible = false

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

func _input(event: InputEvent) -> void:
	if not visible or not is_inside_tree():
		return
	if event.is_action_pressed("action_accept") or event.is_action_pressed("btn_a") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		rematch_requested.emit()
	elif event.is_action_pressed("action_x") or event.is_action_pressed("btn_x"):
		get_viewport().set_input_as_handled()
		settings_requested.emit()
	elif event.is_action_pressed("action_cancel") or event.is_action_pressed("btn_b") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		closed.emit()
