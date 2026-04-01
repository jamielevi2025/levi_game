extends Node2D

class_name DPSDummy

signal dps_check_complete(dps: float)

var total_damage: float = 0.0
var check_duration: float = 30.0
var timer: float = 0.0
var is_active: bool = false
var hurt_timer: float = 0.0
var hurt_duration: float = 0.15

func _ready() -> void:
	add_to_group("dps_dummy")
	position = Vector2(270, 400)
	$Hitbox.area_entered.connect(on_area_hit)


func start() -> void:
	is_active = true
	timer = 0.0
	total_damage = 0.0


func _process(delta: float) -> void:
	if not is_active:
		return
	timer += delta
	$TimerLabel.text = str(int(check_duration - timer)) + "s"
	if timer > 0:
		$DPSLabel.text = "DPS: " + str(int(total_damage / timer))
	else:
		$DPSLabel.text = "DPS: 0"
	if hurt_timer > 0:
		hurt_timer -= delta
		if hurt_timer <= 0:
			$AnimatedSprite2D.play("idle")
	if timer >= check_duration:
		is_active = false
		var final_dps: float = total_damage / check_duration
		dps_check_complete.emit(final_dps)


func take_damage(amount: float) -> void:
	print("DPSDummy hit for: ", amount)
	total_damage += amount
	Arrow._spawn_damage_number(get_tree(), global_position, int(amount), Color(1.0, 1.0, 1.0))
	$AnimatedSprite2D.play("hurt")
	hurt_timer = hurt_duration
	var effect = load("res://scenes/HitEffect.tscn").instantiate()
	effect.setup(global_position)
	get_tree().root.add_child(effect)


func on_area_hit(area: Node2D) -> void:
	var parent = area.get_parent()
	if parent is Arrow:
		take_damage(parent.damage)
