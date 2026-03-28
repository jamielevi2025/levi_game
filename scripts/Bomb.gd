extends Node2D

class_name Bomb

signal bomb_destroyed
signal bomb_exploded

var max_hp: float = 30.0
var current_hp: float = 30.0
var is_active: bool = false
var is_exploding: bool = false
var countdown_duration: float = 5.0
var countdown_timer: float = 0.0
var pre_blink_delay: float = 1.0
var pre_blink_timer: float = 0.0
var flash_interval: float = 0.5
var flash_timer: float = 0.0
var flash_visible: bool = true
var damage: float = 35.0
var landing_position: Vector2
var start_position: Vector2
var drop_duration: float = 1.5
var drop_timer: float = 0.0
var explosion_ring_radius: float = 0.0
var max_ring_radius: float = 600.0
var ring_expanding: bool = false
var already_damaged: bool = false


func _ready() -> void:
	add_to_group("bombs")


func setup(land_pos: Vector2, from_pos: Vector2, hp: float) -> void:
	landing_position = land_pos
	start_position = from_pos
	max_hp = hp
	current_hp = hp
	# WarningCircle centered offsets put it at its position in local space;
	# since Bomb starts at (0,0), local == world
	$WarningCircle.position = landing_position
	$Visual.position = from_pos
	is_active = false


func _process(delta: float) -> void:
	if not is_active:
		drop_timer += delta
		var t: float = clampf(drop_timer / drop_duration, 0.0, 1.0)
		$Visual.position = start_position.lerp(landing_position, t)
		if drop_timer >= drop_duration:
			on_landed()
		return

	if not is_exploding:
		pre_blink_timer += delta
		if pre_blink_timer >= pre_blink_delay:
			countdown_timer += delta
			if countdown_timer >= countdown_duration - 1.0:
				flash_interval = 0.05
			else:
				flash_interval = lerpf(0.5, 0.1, countdown_timer / (countdown_duration - 1.0))
			flash_timer += delta
			if flash_timer >= flash_interval:
				flash_timer = 0.0
				flash_visible = not flash_visible
				$Visual.modulate = Color(1, 1, 1, 1) if flash_visible else Color(0.9, 0.1, 0.1, 1)
			if countdown_timer >= countdown_duration:
				explode()

	if ring_expanding:
		explosion_ring_radius += 500.0 * delta
		var archer_nodes: Array = get_tree().get_nodes_in_group("player")
		for archer in archer_nodes:
			var dist: float = global_position.distance_to(archer.global_position)
			if explosion_ring_radius >= dist and not already_damaged:
				archer.take_damage(damage)
				already_damaged = true
		if explosion_ring_radius >= max_ring_radius:
			queue_free()


func on_landed() -> void:
	is_active = true
	$WarningCircle.hide()
	position = landing_position
	$Visual.position = Vector2.ZERO
	$ArrowDetector.area_entered.connect(on_arrow_hit)


func on_arrow_hit(body: Area2D) -> void:
	if not is_active:
		return
	if is_exploding:
		return
	if body.has_method("set_direction"):
		take_damage(10.0)
		if body.pierce_count > 0:
			body.pierce_count -= 1
		else:
			body.queue_free()


func take_damage(amount: float) -> void:
	current_hp -= amount
	Arrow._spawn_damage_number(get_tree(), global_position, int(amount), Color(1.0, 0.5, 0.0))
	if current_hp <= 0:
		bomb_destroyed.emit()
		queue_free()


func explode() -> void:
	is_exploding = true
	ring_expanding = true
	already_damaged = false
	bomb_exploded.emit()

	var ring_node := Node2D.new()
	ring_node.global_position = global_position
	var ring_rect := ColorRect.new()
	ring_rect.color = Color(1.0, 0.3, 0.0, 0.6)
	ring_rect.offset_left = -10.0
	ring_rect.offset_top = -10.0
	ring_rect.offset_right = 10.0
	ring_rect.offset_bottom = 10.0
	ring_node.add_child(ring_rect)
	get_tree().root.add_child(ring_node)

	var expand_tween: Tween = ring_node.create_tween()
	expand_tween.tween_property(ring_rect, "offset_left", -max_ring_radius * 2.0, 0.5)
	expand_tween.parallel().tween_property(ring_rect, "offset_top", -max_ring_radius * 2.0, 0.5)
	expand_tween.parallel().tween_property(ring_rect, "offset_right", max_ring_radius * 2.0, 0.5)
	expand_tween.parallel().tween_property(ring_rect, "offset_bottom", max_ring_radius * 2.0, 0.5)

	var fade_tween: Tween = ring_node.create_tween()
	fade_tween.tween_property(ring_rect, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(ring_node.queue_free)

	$Visual.hide()
