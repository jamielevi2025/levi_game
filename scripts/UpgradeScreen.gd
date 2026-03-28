extends CanvasLayer

class_name UpgradeScreen

signal upgrade_chosen(upgrade_id: String)

var current_upgrades: Array = []


func _ready() -> void:
	$HBoxContainer/Card1/VBoxContainer/SelectButton.pressed.connect(func(): on_card_selected(0))
	$HBoxContainer/Card2/VBoxContainer/SelectButton.pressed.connect(func(): on_card_selected(1))
	$HBoxContainer/Card3/VBoxContainer/SelectButton.pressed.connect(func(): on_card_selected(2))


func show_screen(upgrades: Array, upgrade_levels_dict: Dictionary = {}) -> void:
	visible = true
	current_upgrades = upgrades
	var cards: Array = [
		$HBoxContainer/Card1/VBoxContainer,
		$HBoxContainer/Card2/VBoxContainer,
		$HBoxContainer/Card3/VBoxContainer,
	]
	for i in range(cards.size()):
		if i >= upgrades.size():
			break
		var u: Dictionary = upgrades[i]
		var vbox = cards[i]
		var current_level: int = upgrade_levels_dict.get(u.id, 0)

		vbox.get_node("TierLabel").text = u.tier.to_upper()
		match u.tier:
			"common": vbox.get_node("TierLabel").modulate = Color(0.7, 0.7, 0.7)
			"rare":   vbox.get_node("TierLabel").modulate = Color(0.3, 0.5, 1.0)
			"epic":   vbox.get_node("TierLabel").modulate = Color(0.7, 0.2, 1.0)

		vbox.get_node("NameLabel").text = u.name

		var level_label = vbox.get_node("LevelLabel")
		if u.id == "emergency_rations":
			level_label.text = ""
		elif current_level == 0:
			level_label.text = "New!"
			level_label.modulate = Color(0.6, 0.9, 0.4)
		else:
			level_label.text = "Lv. " + str(current_level) + " > " + str(current_level + 1)
			level_label.modulate = Color(1.0, 0.85, 0.4)

		vbox.get_node("DescLabel").text = UpgradeData.next_level_description(u.id, current_level)


func on_card_selected(index: int) -> void:
	if index < current_upgrades.size():
		upgrade_chosen.emit(current_upgrades[index].id)
	visible = false
