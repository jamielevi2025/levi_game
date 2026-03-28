extends Node2D

class_name MainMenu

@onready var play_button: Button = $MenuContainer/PlayButton
@onready var mode_bow: Button = $MenuContainer/ModeButtons/ModeBow
@onready var mode_point_click: Button = $MenuContainer/ModeButtons/ModePointClick
@onready var mode_auto_aim: Button = $MenuContainer/ModeButtons/ModeAutoAim
@onready var mode_desc_label: Label = $ModeDescLabel


func _ready() -> void:
	Engine.time_scale = 1.0
	play_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	)
	mode_bow.pressed.connect(func():
		GameSettings.control_mode = "bow"
		mode_desc_label.text = "Click, drag down and release to fire"
		_update_highlights()
	)
	mode_point_click.pressed.connect(func():
		GameSettings.control_mode = "point_and_click"
		mode_desc_label.text = "Click anywhere to fire toward your cursor"
		_update_highlights()
	)
	mode_auto_aim.pressed.connect(func():
		GameSettings.control_mode = "auto_aim"
		mode_desc_label.text = "Click to fire at the nearest enemy automatically"
		_update_highlights()
	)
	_update_highlights()


func _update_highlights() -> void:
	var highlight: Color = Color(0.9, 0.7, 0.2)
	var normal: Color = Color(1.0, 1.0, 1.0)
	mode_bow.modulate = highlight if GameSettings.control_mode == "bow" else normal
	mode_point_click.modulate = highlight if GameSettings.control_mode == "point_and_click" else normal
	mode_auto_aim.modulate = highlight if GameSettings.control_mode == "auto_aim" else normal
