extends Node2D

class_name Leaderboard


func _ready() -> void:
	$BackButton.pressed.connect(on_back_pressed)
	Supabase.scores_fetched.connect(on_scores_fetched)
	Supabase.fetch_scores()


func on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func on_scores_fetched(scores: Array) -> void:
	$LoadingLabel.visible = false
	for child in $ScoreList.get_children():
		child.queue_free()
	if scores.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No scores yet — be the first!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		$ScoreList.add_child(empty_label)
		return
	for i in range(scores.size()):
		var score_data = scores[i]
		var row: HBoxContainer = HBoxContainer.new()
		var rank_label: Label = Label.new()
		rank_label.text = str(i + 1) + "."
		rank_label.custom_minimum_size = Vector2(30, 0)
		var name_label: Label = Label.new()
		name_label.text = str(score_data.get("name", "???"))
		name_label.custom_minimum_size = Vector2(180, 0)
		var score_label: Label = Label.new()
		score_label.text = str(int(score_data.get("score", 0)))
		score_label.custom_minimum_size = Vector2(100, 0)
		var level_label: Label = Label.new()
		level_label.text = "Lv." + str(int(score_data.get("level", 0)))
		level_label.custom_minimum_size = Vector2(60, 0)
		var color: Color
		match i:
			0: color = Color(1.0, 0.85, 0.0)
			1: color = Color(0.8, 0.8, 0.8)
			2: color = Color(0.8, 0.5, 0.2)
			_: color = Color(1, 1, 1)
		rank_label.modulate = color
		name_label.modulate = color
		score_label.modulate = color
		level_label.modulate = color
		row.add_child(rank_label)
		row.add_child(name_label)
		row.add_child(score_label)
		row.add_child(level_label)
		$ScoreList.add_child(row)
