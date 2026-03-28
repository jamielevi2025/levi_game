extends Node2D

class_name HitEffect


func _ready() -> void:
	$Visual.play("hit")
	$Visual.animation_finished.connect(queue_free)


func setup(pos: Vector2) -> void:
	global_position = pos
