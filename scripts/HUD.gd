extends CanvasLayer

class_name HUD

signal menu_button_pressed

@onready var wave_label: Label = $WaveInfoContainer/WaveLabel
@onready var level_label: Label = $WaveInfoContainer/LevelLabel
@onready var enemy_count_label: Label = $EnemyInfoContainer/EnemyCountLabel
@onready var lives_container: HBoxContainer = $LivesContainer
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
	for child in lives_container.get_children():
		child.queue_free()
	for i in range(maximum):
		var heart: Label = Label.new()
		heart.text = "\u2665" if i < current else "\u2661"
		heart.modulate = Color(1.0, 0.2, 0.2) if i < current else Color(0.4, 0.4, 0.4)
		heart.add_theme_font_size_override("font_size", 18)
		lives_container.add_child(heart)


func update_xp(current: int, maximum: int, level: int) -> void:
	xp_bar_fill.size.x = (float(current) / float(maximum)) * 200.0
	player_level_label.text = "Lv." + str(level)
