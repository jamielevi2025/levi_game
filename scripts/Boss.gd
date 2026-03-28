extends CharacterBody2D

class_name Boss

signal died(death_position: Vector2, xp_value: int)

@export var projectile_scene: PackedScene = null
@export var bomb_scene: PackedScene = null

var max_hp: float = 200.0
var current_hp: float = 200.0
var move_speed: float = 60.0
var xp_value: int = 50
var is_dead: bool = false
var has_arrived: bool = false
var archer_ref: Node = null
var current_level: int = 1

var _target_y: float = 160.0
var move_speed_x: float = 60.0
var direction_x: float = 1.0
var direction_timer: float = 0.0
var direction_change_interval: float = 0.0
var sine_offset: float = 0.0
var sine_speed: float = 1.2
var sine_amplitude: float = 55.0

var attack_index: int = 0
var attack_timer: float = 0.0
var attack_interval: float = 1.8
var is_phase_two: bool = false
var phase_two_triggered: bool = false
var active_bombs: int = 0
var max_bombs: int = 2
var phase_one_pattern: Array = ["aimed", "aimed", "bomb"]
var phase_two_pattern: Array = ["aimed", "aimed", "bomb", "spread"]


func _ready() -> void:
	add_to_group("bosses")
	$HealthBarContainer/HealthBarFill.size.x = 100.0
	direction_change_interval = randf_range(1.5, 3.5)
	sine_offset = randf_range(0.0, TAU)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not has_arrived:
		velocity = Vector2(0, move_speed)
		move_and_slide()
		if position.y >= _target_y:
			position.y = _target_y
			velocity = Vector2.ZERO
			has_arrived = true
	else:
		sine_offset += sine_speed * delta
		direction_timer += delta
		if direction_timer >= direction_change_interval:
			direction_timer = 0.0
			direction_change_interval = randf_range(1.5, 4.0)
			move_speed_x = randf_range(40.0, 100.0)
			direction_x = 1.0 if randf() > 0.5 else -1.0
		position.x += direction_x * move_speed_x * delta + sin(sine_offset) * sine_amplitude * delta
		if position.x < 60.0:
			position.x = 60.0
			direction_x = 1.0
		elif position.x > 480.0:
			position.x = 480.0
			direction_x = -1.0
		velocity = Vector2.ZERO
		move_and_slide()

		if not phase_two_triggered and current_hp <= max_hp * 0.5:
			is_phase_two = true
			phase_two_triggered = true
			attack_interval = 1.3
			attack_index = 0
			var tween: Tween = create_tween()
			for i in range(6):
				tween.tween_property($Visual, "modulate", Color(1, 0, 0), 0.1)
				tween.tween_property($Visual, "modulate", Color(1, 1, 1), 0.1)

		attack_timer += delta
		if attack_timer >= attack_interval:
			attack_timer = 0.0
			var pattern: Array = phase_two_pattern if is_phase_two else phase_one_pattern
			var current_attack: String = pattern[attack_index % pattern.size()]
			attack_index += 1
			match current_attack:
				"aimed":
					fire_aimed()
				"spread":
					fire_spread()
				"bomb":
					fire_bomb()


func setup(hp: float, speed: float) -> void:
	max_hp = hp
	current_hp = hp
	move_speed = speed


func fire_aimed() -> void:
	if projectile_scene == null or archer_ref == null:
		return
	var proj: BossProjectile = projectile_scene.instantiate()
	proj.global_position = global_position + Vector2(0, 40)
	proj.setup(archer_ref.global_position)
	proj.ignore_body = self
	get_tree().root.add_child(proj)


func fire_spread() -> void:
	if projectile_scene == null or archer_ref == null:
		return
	var archer_pos: Vector2 = archer_ref.global_position
	var offsets: Array[Vector2] = [Vector2.ZERO, Vector2(-80, 0), Vector2(80, 0)]
	for offset in offsets:
		var proj: BossProjectile = projectile_scene.instantiate()
		proj.global_position = global_position + Vector2(0, 40)
		proj.setup(archer_pos + offset)
		proj.ignore_body = self
		get_tree().root.add_child(proj)


func fire_bomb() -> void:
	if bomb_scene == null or active_bombs >= max_bombs:
		return
	var landing_pos: Vector2 = Vector2(randf_range(80.0, 460.0), randf_range(350.0, 750.0))
	var bomb: Bomb = bomb_scene.instantiate()
	bomb.setup(landing_pos, global_position + Vector2(0, 40), 30.0 + (current_level - 1) * 10.0)
	bomb.bomb_destroyed.connect(on_bomb_resolved)
	bomb.bomb_exploded.connect(on_bomb_resolved)
	active_bombs += 1
	get_tree().root.add_child(bomb)


func on_bomb_resolved() -> void:
	active_bombs = max(0, active_bombs - 1)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp -= amount
	$HealthBarContainer/HealthBarFill.size.x = (current_hp / max_hp) * 100.0
	if current_hp <= 0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit(global_position, xp_value)
	queue_free()
