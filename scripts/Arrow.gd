extends Area2D

class_name Arrow

const HIT_EFFECT_SCENE = preload("res://scenes/HitEffect.tscn")

signal xp_shot_hit(amount: int)

@export var base_speed: float = 800.0
var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var max_travel_distance: float = 0.0
var original_max_travel_distance: float = 0.0
var distance_traveled: float = 0.0
var pierce_count: int = 0
var pierce_damage_bonus: float = 0.0
var applies_slow: bool = false
var slow_factor: float = 0.0
var slow_duration: float = 2.0
var slow_spreads: bool = false
var is_explosive: bool = false
var explosive_radius: float = 40.0
var explosive_damage_ratio: float = 0.3
var explosive_secondary: bool = false
var explosive_ignites: bool = false
var pierced_enemies: Array = []
var has_poison: bool = false
var poison_dps: float = 5.0
var poison_duration: float = 3.0
var poison_spreads: bool = false
var poison_spread_count: int = 0
var has_bouncing: bool = false
var bounce_max: int = 0
var bounce_count: int = 0
var bounce_damage_bonus: float = 0.0
var bounce_speed_increase: float = 0.0
var has_xp_shot: bool = false
var xp_shot_amount: int = 1
var is_player_arrow: bool = true


func _ready() -> void:
	bounce_count = bounce_max
	rotation = velocity.angle() + PI
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)
	$Hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if has_bouncing and bounce_count > 0:
		var bounced: bool = false
		if position.x < 10 and velocity.x < 0:
			velocity.x = abs(velocity.x)
			bounced = true
		elif position.x > 530 and velocity.x > 0:
			velocity.x = -abs(velocity.x)
			bounced = true
		if position.y < 10 and velocity.y < 0:
			velocity.y = abs(velocity.y)
			bounced = true
		if bounced:
			distance_traveled = 0.0
			max_travel_distance = original_max_travel_distance
			bounce_count -= 1
			if bounce_damage_bonus > 0.0:
				damage *= (1.0 + bounce_damage_bonus)
			if bounce_speed_increase > 0.0:
				velocity = velocity.normalized() * velocity.length() * (1.0 + bounce_speed_increase)
			if bounce_count <= 0:
				has_bouncing = false
	rotation = velocity.angle() + PI
	distance_traveled += velocity.length() * delta
	if distance_traveled >= max_travel_distance:
		queue_free()


func set_direction(dir: Vector2, power: float) -> void:
	velocity = dir.normalized() * base_speed * power
	max_travel_distance = lerp(150.0, 900.0, power)
	original_max_travel_distance = max_travel_distance


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	if body in pierced_enemies:
		return
	if not body.has_method("take_damage"):
		return

	var _result = body.take_damage(damage)
	var damage_applied: bool = _result == null or _result == true

	if has_poison and body.has_method("apply_poison"):
		body.apply_poison(poison_dps, poison_duration)
		if poison_spreads and poison_spread_count > 0:
			var enemies: Array = get_tree().get_nodes_in_group("enemies")
			var nearby: Array = []
			for e in enemies:
				if e != body and e.global_position.distance_to(body.global_position) < 150.0:
					nearby.append(e)
			nearby.sort_custom(func(a, b): return a.global_position.distance_to(body.global_position) < b.global_position.distance_to(body.global_position))
			for i in range(mini(poison_spread_count, nearby.size())):
				nearby[i].apply_poison(poison_dps, poison_duration)

	if applies_slow and body.has_method("apply_slow"):
		body.apply_slow(slow_factor, slow_duration)
		if slow_spreads:
			var enemies: Array = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if e != body and e.global_position.distance_to(body.global_position) < 120.0:
					if e.has_method("apply_slow"):
						e.apply_slow(slow_factor, slow_duration)

	if has_xp_shot and xp_shot_amount > 0:
		xp_shot_hit.emit(xp_shot_amount)

	if damage_applied:
		_spawn_damage_number(get_tree(), body.global_position, int(damage), Color(1.0, 1.0, 1.0))
		spawn_hit_effect(body.global_position)

	if is_explosive:
		explode()

	pierced_enemies.append(body)
	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()


func _on_hitbox_area_entered(area: Node2D) -> void:
	if not area is BossProjectile:
		return
	spawn_hit_effect(area.global_position)
	if is_explosive:
		explode()
	area.queue_free()
	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()


func spawn_hit_effect(pos: Vector2) -> void:
	var effect: HitEffect = HIT_EFFECT_SCENE.instantiate()
	effect.setup(pos)
	get_tree().root.add_child(effect)


func explode() -> void:
	var pos: Vector2 = global_position
	var dmg: float = damage
	var radius: float = explosive_radius
	var ratio: float = explosive_damage_ratio
	var ignites: bool = explosive_ignites
	var tree: SceneTree = get_tree()
	_do_explosion(tree, pos, dmg, radius, ratio, ignites)
	_spawn_explosion_visual(tree, pos, radius)
	if explosive_secondary:
		tree.create_timer(0.5).timeout.connect(func():
			_do_explosion(tree, pos, dmg, radius * 0.5, ratio * 0.5, ignites)
			_spawn_explosion_visual(tree, pos, radius * 0.5)
		)


static func _do_explosion(tree: SceneTree, pos: Vector2, dmg: float, radius: float, ratio: float, ignites: bool) -> void:
	var targets: Array = tree.get_nodes_in_group("enemies")
	targets.append_array(tree.get_nodes_in_group("bosses"))
	for enemy in targets:
		if is_instance_valid(enemy) and pos.distance_to(enemy.global_position) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(dmg * ratio)
				_spawn_damage_number(tree, enemy.global_position, int(dmg * ratio), Color(1.0, 0.8, 0.0))
			if ignites and enemy.has_method("apply_poison"):
				enemy.apply_poison(5.0, 3.0)


static func _spawn_explosion_visual(tree: SceneTree, pos: Vector2, radius: float) -> void:
	var ring_node := Node2D.new()
	ring_node.global_position = pos
	var ring_rect := ColorRect.new()
	ring_rect.color = Color(1.0, 0.4, 0.0, 0.5)
	var initial_size := 20.0
	ring_rect.size = Vector2(initial_size, initial_size)
	ring_rect.pivot_offset = Vector2(initial_size / 2.0, initial_size / 2.0)
	ring_rect.position = -Vector2(initial_size / 2.0, initial_size / 2.0)
	ring_node.add_child(ring_rect)
	tree.current_scene.add_child(ring_node)
	var expand_tween := ring_node.create_tween()
	expand_tween.tween_property(ring_rect, "size", Vector2(radius * 2.0, radius * 2.0), 0.3)
	expand_tween.parallel().tween_property(ring_rect, "pivot_offset", Vector2(radius, radius), 0.3)
	expand_tween.parallel().tween_property(ring_rect, "position", -Vector2(radius, radius), 0.3)
	var fade_tween := ring_node.create_tween()
	fade_tween.tween_property(ring_rect, "modulate:a", 0.0, 0.3)
	fade_tween.tween_callback(ring_node.queue_free)


static func _spawn_damage_number(tree: SceneTree, pos: Vector2, amount: int, color: Color) -> void:
	var label: Label = Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 14)
	label.modulate = color
	label.position = pos + Vector2(randf_range(-15.0, 15.0), -20.0)
	tree.root.add_child(label)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)
