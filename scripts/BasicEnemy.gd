extends CharacterBody2D

class_name BasicEnemy

signal died(death_position: Vector2, xp_value: int)

var max_hp: float = 30.0
var current_hp: float = 30.0
var move_speed: float = 80.0
var damage_on_contact: float = 10.0
var xp_value: int = 5
var danger_line_y: float = 700.0
var archer_position: Vector2 = Vector2(270, 860)
var is_dead: bool = false
var spawn_protection: bool = true
var _is_poisoned: bool = false
var _poison_tick_timer: Timer = null

@onready var health_bar_fill: ColorRect = $HealthBarContainer/HealthBarFill
@onready var visual: ColorRect = $Visual


func _ready() -> void:
	add_to_group("enemies")
	var protection_timer: Timer = Timer.new()
	protection_timer.wait_time = 0.1
	protection_timer.one_shot = true
	protection_timer.timeout.connect(func(): spawn_protection = false)
	add_child(protection_timer)
	protection_timer.start()


func _physics_process(_delta: float) -> void:
	if position.y < danger_line_y:
		velocity = Vector2(0, move_speed)
	else:
		velocity = (archer_position - position).normalized() * move_speed
	move_and_slide()

	for i in get_slide_collision_count():
		on_body_entered(get_slide_collision(i).get_collider())

	health_bar_fill.size.x = (current_hp / max_hp) * 40.0


func on_body_entered(body: Node) -> void:
	if body is Archer:
		if body.has_method("take_damage"):
			body.take_damage(damage_on_contact)
		die()


func setup(hp: float, speed: float) -> void:
	max_hp = hp
	current_hp = hp
	move_speed = speed


func take_damage(amount: float) -> void:
	if spawn_protection:
		return
	if is_dead:
		return
	current_hp -= amount
	if current_hp <= 0:
		die()


func apply_slow(factor: float, duration: float) -> void:
	var original_speed: float = move_speed
	move_speed *= (1.0 - factor)
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(self) and not is_dead:
			move_speed = original_speed
	)


func apply_poison(damage_per_sec: float, duration: float) -> void:
	if is_dead:
		return
	if _is_poisoned and _poison_tick_timer != null:
		_poison_tick_timer.queue_free()
		_poison_tick_timer = null
	_is_poisoned = true
	visual.color = Color(0.4, 0.9, 0.2)
	var ticks_remaining: Array[int] = [int(duration / 0.5)]
	var tick_timer: Timer = Timer.new()
	tick_timer.wait_time = 0.5
	add_child(tick_timer)
	_poison_tick_timer = tick_timer
	tick_timer.timeout.connect(func():
		if is_dead:
			tick_timer.queue_free()
			return
		var dmg: float = damage_per_sec * 0.5
		take_damage(dmg)
		Arrow._spawn_damage_number(get_tree(), global_position, int(dmg), Color(0.4, 0.9, 0.2))
		ticks_remaining[0] -= 1
		if ticks_remaining[0] <= 0:
			tick_timer.queue_free()
			_poison_tick_timer = null
			_is_poisoned = false
			if not is_dead:
				visual.color = Color(0.8, 0.2, 0.2)
	)
	tick_timer.start()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit(global_position, xp_value)
	queue_free()
