class_name BottomBar
extends Control

signal place_pressed
signal undo_pressed
signal guide_toggled
signal menu_pressed

@onready var btn_place: Button = $HBox/BtnPlace
@onready var btn_undo: Button = $HBox/BtnUndo
@onready var btn_guide: Button = $HBox/BtnGuide
@onready var btn_menu: Button = $HBox/BtnMenu

var _guide_active: bool = true

func _ready() -> void:
	btn_place.pressed.connect(func(): place_pressed.emit())
	btn_undo.pressed.connect(func(): undo_pressed.emit())
	btn_guide.pressed.connect(_on_guide_pressed)
	btn_menu.pressed.connect(func(): menu_pressed.emit())
	_update_guide_label()

func _on_guide_pressed() -> void:
	_guide_active = not _guide_active
	_update_guide_label()
	guide_toggled.emit()

func set_guide_state(active: bool) -> void:
	_guide_active = active
	_update_guide_label()

func _update_guide_label() -> void:
	if _guide_active:
		btn_guide.text = "[X] 💡 ガイド: ON"
	else:
		btn_guide.text = "[X] 💡 ガイド: OFF"

func set_undo_enabled(enabled: bool) -> void:
	btn_undo.disabled = not enabled

func set_place_enabled(enabled: bool) -> void:
	btn_place.disabled = not enabled
