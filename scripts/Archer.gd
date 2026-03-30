extends CharacterBody2D

class_name Archer

signal lives_changed(current_lives: int, max_lives: int)
signal died
signal xp_gained(amount: int)
signal raw_xp_gained(amount: int)

@export var arrow_scene: PackedScene

var is_drawing: bool = false
var drag_start: Vector2
var max_drag_distance: float = 120.0
var min_drag_distance: float = 20.0
var max_lives: int = 7
var current_lives: int = 7
var is_invincible: bool = false
var invincibility_duration: float = 0.8
var is_dead: bool = false
var fire_cooldown: float = 0.0
var base_fire_cooldown: float = 0.5
var base_damage: float = 10.0
var is_mouse_held: bool = false

# Multipliers
var fire_rate_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var arrow_distance_multiplier: float = 1.0
var xp_multiplier: float = 1.0

# Upgrade flags and scaled values
var has_piercing: bool = false
var pierce_count: int = 0
var pierce_damage_bonus: float = 0.0

var has_slow: bool = false
var slow_factor: float = 0.0
var slow_duration: float = 0.0
var slow_spreads: bool = false

var has_multi_shot: bool = false
var multi_shot_count: int = 0
var multi_shot_damage: float = 1.0
var multi_shot_spread: float = 12.0

var has_explosive: bool = false
var explosive_radius: float = 40.0
var explosive_damage_ratio: float = 0.3
var explosive_secondary: bool = false
var explosive_ignites: bool = false

var has_poison: bool = false
var poison_dps: float = 0.0
var poison_duration: float = 0.0
var poison_spreads: bool = false
var poison_spread_count: int = 0

var has_bouncing: bool = false
var bounce_max: int = 0
var bounce_damage_bonus: float = 0.0
var bounce_speed_increase: float = 0.0

var has_xp_shot: bool = false
var xp_shot_amount: int = 0
var xp_auto_collect_radius: float = 0.0

var has_sniper: bool = false
var sniper_always_crit: bool = false

var upgrade_levels: Dictionary = {}

@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var bow_sprite: AnimatedSprite2D = $BowSprite
@onready var bow_sound: AudioStreamPlayer = $BowSound
@onready var hurt_sound: AudioStreamPlayer = $HurtSound

var current_bow_state: String = "idle"
var locked_aim_angle: float = 0.0
var is_animating_shot: bool = false
var shot_anim_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")
	position = Vector2(270, 860)
	died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if fire_cooldown > 0:
		fire_cooldown -= delta
	if is_mouse_held and fire_cooldown <= 0:
		match GameSettings.control_mode:
			"point_and_click":
				var mouse_pos: Vector2 = get_global_mouse_position()
				if mouse_pos.y < global_position.y:
					_fire_toward_position(mouse_pos)
			"auto_aim":
				_fire_auto_aim()
	update_bow_rotation()
	if GameSettings.control_mode == "bow":
		var drag_dist: float = (get_global_mouse_position() - drag_start).length() if is_drawing else 0.0
		if not is_drawing:
			update_bow_state("idle")
		elif drag_dist < max_drag_distance * 0.5:
			update_bow_state("drawing")
		else:
			update_bow_state("full_draw")
	else:
		if is_animating_shot:
			shot_anim_timer += delta
			if shot_anim_timer < 0.08:
				update_bow_state("drawing")
			elif shot_anim_timer < 0.18:
				update_bow_state("full_draw")
			else:
				update_bow_state("idle")
				is_animating_shot = false
		else:
			update_bow_state("idle")


func update_bow_state(state: String) -> void:
	if state == current_bow_state:
		return
	current_bow_state = state
	bow_sprite.play(state)


func update_bow_rotation() -> void:
	if not is_drawing:
		var dir: Vector2 = get_global_mouse_position() - global_position
		bow_sprite.rotation = dir.angle() - PI / 2.0
		bow_sprite.flip_v = true
	else:
		var drag: Vector2 = get_global_mouse_position() - drag_start
		if drag.length() > 10.0:
			locked_aim_angle = (-drag).angle()
		bow_sprite.rotation = locked_aim_angle - PI / 2.0
		bow_sprite.flip_v = true


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_mouse_held = true
		else:
			is_mouse_held = false
		match GameSettings.control_mode:
			"bow":
				if event.pressed:
					is_drawing = true
					drag_start = event.position
				else:
					if is_drawing:
						var drag: Vector2 = event.position - drag_start
						if drag.y > 0 and drag.length() >= min_drag_distance:
							fire(drag)
					trajectory_line.points = []
					is_drawing = false
	elif event is InputEventMouseMotion and is_drawing and GameSettings.control_mode == "bow":
		var drag: Vector2 = event.position - drag_start
		if drag.y > 0 and drag.length() >= min_drag_distance:
			_update_trajectory(drag)
		else:
			trajectory_line.points = []


func get_upgrade_level(id: String) -> int:
	return upgrade_levels.get(id, 0)


func increment_upgrade(id: String) -> void:
	upgrade_levels[id] = get_upgrade_level(id) + 1


func fire(drag: Vector2) -> void:
	if arrow_scene == null or fire_cooldown > 0:
		return
	var power: float = clamp(drag.length() / max_drag_distance, 0.2, 1.0)
	_fire_in_direction(-drag.normalized(), power)


func _fire_toward_position(target_pos: Vector2) -> void:
	if arrow_scene == null or fire_cooldown > 0:
		return
	is_animating_shot = true
	shot_anim_timer = 0.0
	_fire_in_direction((target_pos - global_position).normalized(), 1.0)


func _fire_auto_aim() -> void:
	if arrow_scene == null or fire_cooldown > 0:
		return
	var targets: Array = get_tree().get_nodes_in_group("enemies")
	targets.append_array(get_tree().get_nodes_in_group("bosses"))
	if targets.is_empty():
		return
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for t in targets:
		if not is_instance_valid(t):
			continue
		var d: float = global_position.distance_to(t.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = t
	if nearest == null:
		return
	_fire_in_direction((nearest.global_position - global_position).normalized(), 1.0)


func _fire_in_direction(main_dir: Vector2, power: float) -> void:
	bow_sound.play()
	_spawn_arrow(main_dir, power)
	if has_multi_shot and multi_shot_count > 0:
		var extra_dmg: float = base_damage * damage_multiplier * multi_shot_damage
		for i in range(multi_shot_count):
			var side: float = 1.0 if i % 2 == 0 else -1.0
			var offset_deg: float = side * multi_shot_spread * ceil((i + 1.0) / 2.0)
			_spawn_arrow(main_dir.rotated(deg_to_rad(offset_deg)), power, extra_dmg)
	fire_cooldown = base_fire_cooldown * fire_rate_multiplier


func _spawn_arrow(dir: Vector2, power: float, damage_override: float = -1.0) -> void:
	var arrow: Arrow = arrow_scene.instantiate()
	arrow.global_position = global_position + Vector2(0, -30) + dir * 24.0
	arrow.base_speed *= speed_multiplier
	arrow.set_direction(dir, power)
	arrow.damage = damage_override if damage_override >= 0.0 else base_damage * damage_multiplier
	arrow.max_travel_distance *= arrow_distance_multiplier
	if has_piercing:
		arrow.pierce_count = pierce_count
		arrow.pierce_damage_bonus = pierce_damage_bonus
	if has_slow:
		arrow.applies_slow = true
		arrow.slow_factor = slow_factor
		arrow.slow_duration = slow_duration
		arrow.slow_spreads = slow_spreads
	if has_explosive:
		arrow.is_explosive = true
		arrow.explosive_radius = explosive_radius
		arrow.explosive_damage_ratio = explosive_damage_ratio
		arrow.explosive_secondary = explosive_secondary
		arrow.explosive_ignites = explosive_ignites
	if has_poison:
		arrow.has_poison = true
		arrow.poison_dps = poison_dps
		arrow.poison_duration = poison_duration
		arrow.poison_spreads = poison_spreads
		arrow.poison_spread_count = poison_spread_count
	if has_bouncing:
		arrow.has_bouncing = true
		arrow.bounce_max = bounce_max
		arrow.bounce_damage_bonus = bounce_damage_bonus
		arrow.bounce_speed_increase = bounce_speed_increase
	if has_xp_shot:
		arrow.has_xp_shot = true
		arrow.xp_shot_amount = xp_shot_amount
	arrow.xp_shot_hit.connect(func(amount: int): raw_xp_gained.emit(amount))
	get_tree().root.add_child(arrow)


func take_damage(amount: int = 1) -> void:
	if is_dead or is_invincible:
		return
	current_lives -= amount
	current_lives = max(0, current_lives)
	lives_changed.emit(current_lives, max_lives)
	is_invincible = true
	hurt_sound.play()
	var timer: Timer = Timer.new()
	timer.wait_time = invincibility_duration
	timer.one_shot = true
	timer.timeout.connect(func(): is_invincible = false; timer.queue_free())
	add_child(timer)
	timer.start()
	if current_lives <= 0:
		is_dead = true
		died.emit()


func apply_upgrade(upgrade_id: String) -> void:
	increment_upgrade(upgrade_id)
	var level: int = get_upgrade_level(upgrade_id)
	match upgrade_id:
		"sharp_tips":
			damage_multiplier += 0.15
		"mend":
			current_lives = min(current_lives + 1, max_lives)
			lives_changed.emit(current_lives, max_lives)
		"xp_surge":
			xp_multiplier += 0.25
		"rapid_fire":
			fire_rate_multiplier = max(0.2, fire_rate_multiplier * 0.90)
		"emergency_rations":
			current_lives = min(current_lives + 2, max_lives)
			lives_changed.emit(current_lives, max_lives)
		"heavy_shot":
			has_sniper = true
			damage_multiplier = 1.0 + (level * 0.2) + (level * 0.02 * level)
			fire_rate_multiplier *= 1.05
			if level >= 7:
				pierce_count = max(pierce_count, 1)
				has_piercing = true
			if level >= 9:
				sniper_always_crit = true
		"freezing_shot":
			has_slow = true
			var factor_table: Array = [0, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50, 0.45, 0.40]
			var dur_table: Array    = [0.0,  1.5,  2.0,  2.0,  2.5,  3.0,  3.0,  3.0,  3.5,  3.5,  4.0]
			slow_factor   = factor_table[mini(level, 10)]
			slow_duration = dur_table[mini(level, 10)]
			slow_spreads  = level >= 9
		"piercing_shot":
			has_piercing = true
			pierce_count = level
			pierce_damage_bonus = level * 0.05
		"poison_tip":
			has_poison = true
			var dps_table: Array = [0.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 10.0, 12.0, 12.0, 15.0]
			var dur_table: Array = [0.0, 2.0, 2.5, 3.0, 3.0, 3.5,  3.5,  3.5,  4.0,  4.0,  5.0]
			poison_dps      = dps_table[mini(level, 10)]
			poison_duration = dur_table[mini(level, 10)]
			poison_spreads  = level >= 7
			if level >= 10:
				poison_spread_count = 3
			elif level >= 9:
				poison_spread_count = 2
			elif level >= 7:
				poison_spread_count = 1
			else:
				poison_spread_count = 0
		"bouncing_shot":
			has_bouncing = true
			bounce_max = level
			bounce_damage_bonus = 0.0
			bounce_speed_increase = 0.0
			if level >= 7:
				bounce_damage_bonus = 0.20
			elif level >= 5:
				bounce_damage_bonus = 0.10
			if level >= 9:
				bounce_speed_increase = 0.05
		"multi_shot":
			has_multi_shot = true
			var count_table: Array  = [0, 1, 1, 1, 2, 2, 3, 3, 4, 5, 6]
			var dmg_table: Array    = [0.0, 0.25, 0.50, 0.75, 0.75, 1.0, 1.0, 1.0, 1.0, 1.25, 1.25]
			multi_shot_count  = count_table[mini(level, 10)]
			multi_shot_damage = dmg_table[mini(level, 10)]
			multi_shot_spread = 12.0 + (level * 3.0)
		"explosive_tip":
			has_explosive = true
			explosive_radius = 70.0 + (level * 8.0)
			var ratio_table: Array = [0.0, 0.30, 0.40, 0.50, 0.60, 0.75, 0.90, 1.0, 1.0, 1.0, 1.0]
			explosive_damage_ratio = ratio_table[mini(level, 10)]
			explosive_secondary    = level >= 7
			explosive_ignites      = level >= 9
		"xp_shot":
			has_xp_shot = true
			xp_shot_amount = level
			xp_auto_collect_radius = 20.0 + ((level - 3) * 10.0) if level >= 3 else 0.0


func _on_died() -> void:
	print("Archer died")


func _update_trajectory(drag: Vector2) -> void:
	var launch_dir: Vector2 = -drag.normalized()
	var power: float = clamp(drag.length() / max_drag_distance, 0.2, 1.0)
	var launch_vel: Vector2 = launch_dir * 800.0 * power
	var start_pos: Vector2 = global_position + Vector2(0, -30)
	var max_travel: float = lerp(100.0, 500.0, power)
	var t_step: float = max_travel / (12.0 * launch_vel.length())
	var points: PackedVector2Array = []
	for i in range(12):
		var t: float = i * t_step
		points.append(start_pos + launch_vel * t - global_position)
	trajectory_line.points = points
