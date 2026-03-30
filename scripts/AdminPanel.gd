extends CanvasLayer

class_name AdminPanel

signal kill_all
signal spawn_boss
signal next_level
signal grant_xp(amount: int)
signal instant_level_up
signal set_level(level: int)

@onready var stats_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsLabel
@onready var level_spin_box: SpinBox = $PanelContainer/MarginContainer/VBoxContainer/LevelRow/LevelSpinBox


func _ready() -> void:
	$PanelContainer/MarginContainer/VBoxContainer/BtnKillAll.pressed.connect(func(): kill_all.emit())
	$PanelContainer/MarginContainer/VBoxContainer/BtnSpawnBoss.pressed.connect(func(): spawn_boss.emit())
	$PanelContainer/MarginContainer/VBoxContainer/BtnNextLevel.pressed.connect(func(): next_level.emit())
	$PanelContainer/MarginContainer/VBoxContainer/BtnGrantXP.pressed.connect(func(): grant_xp.emit(50))
	$PanelContainer/MarginContainer/VBoxContainer/BtnLevelUp.pressed.connect(func(): instant_level_up.emit())
	$PanelContainer/MarginContainer/VBoxContainer/LevelRow/BtnSetLevel.pressed.connect(func(): set_level.emit(int(level_spin_box.value)))
	$PanelContainer/MarginContainer/VBoxContainer/BtnClose.pressed.connect(hide_panel)


func show_panel(stats_text: String) -> void:
	visible = true
	stats_label.text = stats_text


func hide_panel() -> void:
	visible = false
