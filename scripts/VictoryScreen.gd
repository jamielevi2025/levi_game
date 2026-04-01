extends CanvasLayer

class_name VictoryScreen

signal play_again_pressed
signal menu_pressed

var current_score: int = 0
var current_dps: int = 0
var current_lives: int = 0

@onready var score_breakdown: Label = $PanelContainer/MarginContainer/VBoxContainer/ScoreBreakdown
@onready var final_score_label: Label = $PanelContainer/MarginContainer/VBoxContainer/FinalScoreLabel
@onready var name_input: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/NameInput
@onready var submit_button: Button = $PanelContainer/MarginContainer/VBoxContainer/SubmitButton
@onready var submit_status: Label = $PanelContainer/MarginContainer/VBoxContainer/SubmitStatus
@onready var leaderboard_button: Button = $PanelContainer/MarginContainer/VBoxContainer/LeaderboardButton
@onready var play_again_button: Button = $PanelContainer/MarginContainer/VBoxContainer/PlayAgainButton
@onready var menu_button_node: Button = $PanelContainer/MarginContainer/VBoxContainer/MenuButton


func _ready() -> void:
	submit_button.pressed.connect(on_submit_pressed)
	leaderboard_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")
	)
	play_again_button.pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
	)
	menu_button_node.pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)


func show_screen(score: int, dps: int, lives: int) -> void:
	visible = true
	current_score = score
	current_dps = dps
	current_lives = lives
	var run_score: int = score - (lives * 500) - (dps * 30)
	score_breakdown.text = (
		"Run Score: " + str(run_score) + "\n" +
		"Lives Bonus: " + str(lives * 500) + "\n" +
		"DPS Bonus: " + str(dps * 30) + "\n" +
		"DPS: " + str(dps) + "/sec"
	)
	final_score_label.text = "Final Score: " + str(score)
	name_input.text = ""
	submit_status.text = ""
	submit_button.disabled = false


func on_submit_pressed() -> void:
	if name_input.text.strip_edges() == "":
		submit_status.text = "Please enter your name"
		return
	submit_button.disabled = true
	submit_status.text = "Submitting..."
	Supabase.submit_score_with_dps(name_input.text.strip_edges(), current_score, 14, float(current_dps))
	Supabase.score_submitted.connect(func():
		submit_status.text = "Score submitted!"
	, CONNECT_ONE_SHOT)
