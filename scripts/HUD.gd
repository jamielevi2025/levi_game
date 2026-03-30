extends CanvasLayer

class_name HUD

signal menu_button_pressed

@onready var wave_label: Label = $WaveInfoContainer/WaveLabel
@onready var level_label: Label = $WaveInfoContainer/LevelLabel
@onready var enemy_count_label: Label = $EnemyInfoContainer/EnemyCountLabel
@onready var lives_container: Label = $LivesContainer
@onready var xp_bar_fill: ColorRect = $XPBarFill
@onready var player_level_label: Label = $PlayerLevelLabel
@onready var menu_button: Button = $MenuButton


func _ready() -> void:
	menu_button.pressed.connect(func(): menu_button_pressed.emit())


func update_wave(wave: int, level: int) -> void:
	wave_label.text = "Wave " + str(wave)
	level_label.text = "Level " + str(level)


func update_enemy_count(count: int) -> void:
	enemy_count_label.text = "Enemies: " + str(count)


func update_lives(current: int, maximum: int) -> void:
	var text = ""
	for i in range(maximum):
		if i < current:
			text += "\u2665"
		else:
			text += "\u2661"
	lives_container.text = text


func update_xp(current: int, maximum: int, level: int) -> void:
	xp_bar_fill.size.x = (float(current) / float(maximum)) * 200.0
	player_level_label.text = "Lv." + str(level)
