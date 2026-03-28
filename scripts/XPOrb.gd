extends Area2D

class_name XPOrb

signal collected(amount: int)

var xp_value: int = 5
var collect_radius: float = 18.0


func _ready() -> void:
	add_to_group("orbs")


func _process(_delta: float) -> void:
	if global_position.distance_to(get_global_mouse_position()) <= collect_radius:
		collected.emit(xp_value)
		queue_free()


func setup(value: int) -> void:
	xp_value = value
