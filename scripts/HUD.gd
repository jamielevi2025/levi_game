extends CanvasLayer

class_name HUD

@onready var wave_label: Label = $WaveInfoContainer/WaveLabel
@onready var level_label: Label = $WaveInfoContainer/LevelLabel
@onready var enemy_count_label: Label = $EnemyInfoContainer/EnemyCountLabel
@onready var player_health_fill: ColorRect = $PlayerHealthFill
@onready var xp_bar_fill: ColorRect = $XPBarFill
@onready var player_level_label: Label = $PlayerLevelLabel


func update_wave(wave: int, level: int) -> void:
	wave_label.text = "Wave " + str(wave)
	level_label.text = "Level " + str(level)


func update_enemy_count(count: int) -> void:
	enemy_count_label.text = "Enemies: " + str(count)


func update_player_hp(current: float, max_hp: float) -> void:
	player_health_fill.size.x = (current / max_hp) * 200.0


func update_xp(current: int, maximum: int, level: int) -> void:
	xp_bar_fill.size.x = (float(current) / float(maximum)) * 200.0
	player_level_label.text = "Lv." + str(level)
