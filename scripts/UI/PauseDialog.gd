class_name PauseDialog
extends Control

signal resumed
signal restarted(mode: int, player_color: int, ai_diff: int, sound_on: bool, guide_on: bool)
signal title_requested
signal settings_changed(sound_on: bool, guide_on: bool)

const MODE_1P_BLACK: int = 0
const MODE_1P_WHITE: int = 1
const MODE_2P_LOCAL: int = 2
const MODE_WATCH: int = 3

@onready var mode_opt: OptionButton = $CenterContainer/PanelContainer/MarginContainer/VBox/GridSettings/ModeOption
@onready var diff_opt: OptionButton = $CenterContainer/PanelContainer/MarginContainer/VBox/GridSettings/DiffOption
@onready var sound_btn: CheckButton = $CenterContainer/PanelContainer/MarginContainer/VBox/GridSettings/SoundCheck
@onready var guide_btn: CheckButton = $CenterContainer/PanelContainer/MarginContainer/VBox/GridSettings/GuideCheck

@onready var resume_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/ButtonHBox/ResumeButton
@onready var restart_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/ButtonHBox/RestartButton
@onready var title_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/TitleButton

var current_mode: int = MODE_1P_BLACK
var current_diff: int = AIController.DIFFICULTY_HARD
var sound_enabled: bool = true
var guide_enabled: bool = true

func _ready() -> void:
	visible = false
	_populate_options()
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	if title_btn:
		title_btn.pressed.connect(_on_title_pressed)
	sound_btn.toggled.connect(_on_sound_toggled)
	guide_btn.toggled.connect(_on_guide_toggled)
	mode_opt.item_selected.connect(_on_mode_selected)
	diff_opt.item_selected.connect(_on_diff_selected)

func _populate_options() -> void:
	mode_opt.clear()
	mode_opt.add_item("1P vs CPU (黒・先手)", MODE_1P_BLACK)
	mode_opt.add_item("1P vs CPU (白・後手)", MODE_1P_WHITE)
	mode_opt.add_item("2P Local (二人対局)", MODE_2P_LOCAL)
	mode_opt.add_item("Watch Mode (CPU観戦)", MODE_WATCH)
	
	diff_opt.clear()
	diff_opt.add_item("EASY (初級・ランダム)", AIController.DIFFICULTY_EASY)
	diff_opt.add_item("NORMAL (中級・貪欲法)", AIController.DIFFICULTY_NORMAL)
	diff_opt.add_item("HARD (上級・評価+先読み)", AIController.DIFFICULTY_HARD)
	
	mode_opt.select(current_mode)
	diff_opt.select(current_diff)
	sound_btn.button_pressed = sound_enabled
	guide_btn.button_pressed = guide_enabled

func open(p_mode: int, p_diff: int, p_sound: bool, p_guide: bool) -> void:
	current_mode = p_mode
	current_diff = p_diff
	sound_enabled = p_sound
	guide_enabled = p_guide
	
	mode_opt.select(current_mode)
	diff_opt.select(current_diff)
	sound_btn.button_pressed = sound_enabled
	guide_btn.button_pressed = guide_enabled
	
	diff_opt.disabled = (current_mode == MODE_2P_LOCAL)
	
	visible = true
	resume_btn.grab_focus()

func close() -> void:
	visible = false

func _on_resume_pressed() -> void:
	close()
	resumed.emit()

func _on_restart_pressed() -> void:
	close()
	var mode_val: int = mode_opt.selected
	var diff_val: int = diff_opt.selected
	var p_color: int = ReversiLogic.BLACK
	if mode_val == MODE_1P_WHITE:
		p_color = ReversiLogic.WHITE
	
	restarted.emit(mode_val, p_color, diff_val, sound_btn.button_pressed, guide_btn.button_pressed)

func _on_title_pressed() -> void:
	close()
	title_requested.emit()

func _on_mode_selected(idx: int) -> void:
	current_mode = idx
	diff_opt.disabled = (current_mode == MODE_2P_LOCAL)

func _on_diff_selected(idx: int) -> void:
	current_diff = idx

func _on_sound_toggled(pressed: bool) -> void:
	sound_enabled = pressed
	settings_changed.emit(sound_enabled, guide_btn.button_pressed)

func _on_guide_toggled(pressed: bool) -> void:
	guide_enabled = pressed
	settings_changed.emit(sound_btn.button_pressed, guide_enabled)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_pause") or event.is_action_pressed("action_cancel") or event.is_action_pressed("btn_b"):
		get_viewport().set_input_as_handled()
		_on_resume_pressed()
