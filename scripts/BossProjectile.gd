extends Area2D

class_name BossProjectile

var speed: float = 180.0
var velocity: Vector2 = Vector2.ZERO
var damage: float = 15.0
var ignore_body: Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(target_position: Vector2) -> void:
	var direction: Vector2 = (target_position - global_position).normalized()
	velocity = direction * speed


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if position.y > 1000.0 or position.x < -50.0 or position.x > 590.0 or position.y < -50.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == ignore_body:
		return
	if body is Archer or body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()


func take_damage(_amount: float) -> void:
	queue_free()
