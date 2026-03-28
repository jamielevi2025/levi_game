extends CanvasLayer

class_name GameOver

signal restart_pressed
signal quit_pressed
signal menu_pressed


func _ready() -> void:
	$VBoxContainer/RestartButton.pressed.connect(func(): restart_pressed.emit())
	$VBoxContainer/MenuButton.pressed.connect(func(): menu_pressed.emit())
	$VBoxContainer/QuitButton.pressed.connect(func(): quit_pressed.emit())


func show_screen(level: int, wave: int) -> void:
	visible = true
	$VBoxContainer/StatsLabel.text = "You reached Level " + str(level) + " - Wave " + str(wave)
