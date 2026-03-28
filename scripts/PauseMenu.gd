extends CanvasLayer

class_name PauseMenu

signal resume_pressed
signal restart_pressed
signal menu_pressed


func _ready() -> void:
	$VBoxContainer/ResumeButton.pressed.connect(func():
		resume_pressed.emit()
		hide_pause()
	)
	$VBoxContainer/RestartButton.pressed.connect(func(): restart_pressed.emit())
	$VBoxContainer/MenuButton.pressed.connect(func(): menu_pressed.emit())


func show_pause() -> void:
	visible = true
	Engine.time_scale = 0.0


func hide_pause() -> void:
	visible = false
	Engine.time_scale = 1.0
