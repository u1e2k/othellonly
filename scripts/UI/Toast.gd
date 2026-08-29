class_name Toast
extends Control

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var label: Label = $CenterContainer/PanelContainer/Margin/Label

var _tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	mouse_filter = MOUSE_FILTER_IGNORE

func show_message(text: String, duration: float = 1.4) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	
	label.text = text
	scale = Vector2(0.9, 0.9)
	pivot_offset = size * 0.5
	
	_tween = create_tween()
	# Fade in & scale up
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Wait
	_tween.set_parallel(false)
	_tween.tween_interval(duration)
	
	# Fade out
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.3)
