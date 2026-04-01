extends Node2D

class_name Main

const ENEMY_SCENE = preload("res://scenes/BasicEnemy.tscn")
const XP_ORB_SCENE = preload("res://scenes/XPOrb.tscn")
const HUD_SCENE = preload("res://scenes/HUD.tscn")
const BOSS_SCENE = preload("res://scenes/Boss.tscn")
const BOSS_PROJECTILE_SCENE = preload("res://scenes/BossProjectile.tscn")
const BOMB_SCENE = preload("res://scenes/Bomb.tscn")
const GAME_OVER_SCENE = preload("res://scenes/GameOver.tscn")
const UPGRADE_SCREEN_SCENE = preload("res://scenes/UpgradeScreen.tscn")
const PAUSE_MENU_SCENE = preload("res://scenes/PauseMenu.tscn")
const ADMIN_PANEL_SCENE = preload("res://scenes/AdminPanel.tscn")
const DPS_DUMMY_SCENE = preload("res://scenes/DPSDummy.tscn")
const VICTORY_SCREEN_SCENE = preload("res://scenes/VictoryScreen.tscn")

var current_level: int = 1
var current_wave: int = 0
var enemies_alive: int = 0
var is_wave_active: bool = false
var is_boss_phase: bool = false
var wave_enemy_counts: Array = [3, 5, 7]
var spawn_interval: float = 0.8
var warning_shown: bool = false
var is_dps_check: bool = false
var final_dps: float = 0.0
var current_xp: int = 0
var xp_to_level: int = 10
var player_level: int = 1
var enemies_killed: int = 0

var _remaining_spawns: int = 0
var _spawn_timer: Timer = null
var hud: HUD = null
var game_over_screen: GameOver = null
var upgrade_screen: UpgradeScreen = null
var pause_menu: PauseMenu = null
var admin_panel: AdminPanel = null
var victory_screen: VictoryScreen = null


func _ready() -> void:
	$Archer.arrow_scene = preload("res://scenes/Arrow.tscn")
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	$Archer.lives_changed.connect(hud.update_lives)
	hud.update_lives(7, 7)
	$Archer.died.connect(on_archer_died)
	$Archer.xp_gained.connect(on_xp_collected)
	$Archer.raw_xp_gained.connect(on_raw_xp_collected)
	hud.menu_button_pressed.connect(func():
		if upgrade_screen.visible or game_over_screen.visible or victory_screen.visible:
			return
		if pause_menu.visible:
			pause_menu.hide_pause()
		else:
			pause_menu.show_pause()
	)
	game_over_screen = GAME_OVER_SCENE.instantiate()
	add_child(game_over_screen)
	game_over_screen.restart_pressed.connect(on_restart_pressed)
	game_over_screen.menu_pressed.connect(on_menu_pressed)
	game_over_screen.quit_pressed.connect(on_quit_pressed)
	upgrade_screen = UPGRADE_SCREEN_SCENE.instantiate()
	add_child(upgrade_screen)
	upgrade_screen.upgrade_chosen.connect(on_upgrade_chosen)
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
	pause_menu.hide_pause()
	pause_menu.resume_pressed.connect(func(): pause_menu.hide_pause())
	pause_menu.debug_pressed.connect(on_debug_pressed)
	pause_menu.restart_pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
	)
	pause_menu.menu_pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	victory_screen = VICTORY_SCREEN_SCENE.instantiate()
	add_child(victory_screen)
	victory_screen.play_again_pressed.connect(on_restart_pressed)
	victory_screen.menu_pressed.connect(on_menu_pressed)
	admin_panel = ADMIN_PANEL_SCENE.instantiate()
	add_child(admin_panel)
	admin_panel.kill_all.connect(_on_admin_kill_all)
	admin_panel.spawn_boss.connect(_on_admin_spawn_boss)
	admin_panel.next_level.connect(_on_admin_next_level)
	admin_panel.grant_xp.connect(on_xp_collected)
	admin_panel.instant_level_up.connect(_on_admin_instant_level_up)
	admin_panel.set_level.connect(_on_admin_set_level)
	admin_panel.dps_check_pressed.connect(on_admin_dps_check)
	var safety_timer: Timer = Timer.new()
	safety_timer.wait_time = 2.0
	safety_timer.autostart = true
	safety_timer.timeout.connect(on_enemy_count_safety_check)
	add_child(safety_timer)
	get_tree().create_timer(2.0).timeout.connect(start_next_wave)


func start_next_wave() -> void:
	current_wave += 1
	if current_wave > 3:
		start_boss_phase()
		return
	is_wave_active = true
	spawn_interval = max(0.8 - (current_level * 0.08), 0.15)
	_remaining_spawns = wave_enemy_counts[current_wave - 1] + ((current_level - 1) * 3)
	hud.update_wave(current_wave, current_level)
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	_spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
	enemies_alive += 1
	hud.update_enemy_count(enemies_alive)
	_remaining_spawns -= 1
	if _remaining_spawns <= 0 and _spawn_timer != null:
		_spawn_timer.stop()
		_spawn_timer.queue_free()
		_spawn_timer = null


func start_boss_phase() -> void:
	is_boss_phase = true
	var boss: Boss = BOSS_SCENE.instantiate()
	boss.position = Vector2(270, -60)
	boss.projectile_scene = BOSS_PROJECTILE_SCENE
	boss.bomb_scene = BOMB_SCENE
	boss.archer_ref = $Archer
	boss.current_level = current_level
	var boss_hp: float
	if current_level <= 10:
		boss_hp = round(150.0 * pow(1.45, current_level - 1))
	else:
		var boss_base_at_10: float = round(150.0 * pow(1.45, 9))
		boss_hp = round(boss_base_at_10 * pow(1.6, current_level - 10))
	boss.setup(boss_hp, 60.0)
	boss.died.connect(on_boss_died)
	add_child(boss)
	hud.update_wave(current_wave, current_level)


func on_boss_died(death_position: Vector2, xp_amount: int) -> void:
	is_boss_phase = false
	enemies_killed += 1
	current_level += 1
	current_wave = 0
	enemies_alive = 0
	var orb: XPOrb = XP_ORB_SCENE.instantiate()
	orb.setup(xp_amount, $Archer.xp_auto_collect_radius)
	orb.position = death_position
	orb.collected.connect(on_xp_collected)
	add_child(orb)
	if current_level == 10 and not warning_shown:
		warning_shown = true
		show_warning_banner("Final boss approaching in 3 levels")
	if current_level == 14:
		get_tree().create_timer(3.0).timeout.connect(start_dps_check)
	else:
		get_tree().create_timer(3.0).timeout.connect(start_next_wave)


func spawn_enemy() -> void:
	var enemy: BasicEnemy = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(randf_range(40.0, 500.0), -40.0)
	var hp: float
	if current_level <= 10:
		hp = round(30.0 * pow(1.15, current_level - 1))
	else:
		var base_at_10: float = round(30.0 * pow(1.15, current_level - 1))
		hp = round(base_at_10 * pow(1.10, current_level - 10))
	var speed: float = min(80.0 * pow(1.1, current_level - 1), 300.0)
	enemy.setup(hp, speed)
	enemy.died.connect(on_enemy_died)
	add_child(enemy)


func on_enemy_died(death_position: Vector2, xp_amount: int) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	enemies_killed += 1
	hud.update_enemy_count(enemies_alive)
	var orb: XPOrb = XP_ORB_SCENE.instantiate()
	orb.setup(xp_amount, $Archer.xp_auto_collect_radius)
	orb.position = death_position
	orb.collected.connect(on_xp_collected)
	add_child(orb)
	on_enemy_died_check()


func on_enemy_died_check() -> void:
	if enemies_alive <= 0 and is_wave_active and _remaining_spawns <= 0 and not is_boss_phase:
		is_wave_active = false
		get_tree().create_timer(3.0).timeout.connect(start_next_wave)


func on_enemy_count_safety_check() -> void:
	if not is_wave_active:
		return
	if is_boss_phase:
		return
	var actual_count: int = get_tree().get_nodes_in_group("enemies").size()
	if actual_count == 0 and enemies_alive > 0:
		print("WARNING: enemies_alive was ", enemies_alive, " but no enemies found. Correcting.")
		enemies_alive = 0
		on_enemy_died_check()
	elif actual_count != enemies_alive and actual_count > 0:
		enemies_alive = actual_count
		hud.update_enemy_count(enemies_alive)


func show_upgrade_screen() -> void:
	Engine.time_scale = 0.0
	var upgrades: Array = UpgradeData.get_random_upgrades(3, $Archer.upgrade_levels)
	upgrade_screen.show_screen(upgrades, $Archer.upgrade_levels)


func on_upgrade_chosen(upgrade_id: String) -> void:
	$Archer.apply_upgrade(upgrade_id)
	Engine.time_scale = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_M:
		if upgrade_screen.visible or game_over_screen.visible:
			return
		if pause_menu.visible:
			pause_menu.hide_pause()
		else:
			pause_menu.show_pause()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_D and event.pressed and not event.echo:
		if Input.is_key_pressed(KEY_SHIFT):
			if admin_panel.visible:
				admin_panel.hide_panel()
			else:
				admin_panel.show_panel(build_stats_text())


func _on_admin_kill_all() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("die"):
			enemy.die()
	enemies_alive = 0
	hud.update_enemy_count(0)


func _on_admin_spawn_boss() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	if _spawn_timer != null:
		_spawn_timer.stop()
		_spawn_timer.queue_free()
		_spawn_timer = null
	_remaining_spawns = 0
	enemies_alive = 0
	is_wave_active = false
	current_wave = 3
	start_boss_phase()


func _on_admin_next_level() -> void:
	if _spawn_timer != null:
		_spawn_timer.stop()
		_spawn_timer.queue_free()
		_spawn_timer = null
	_remaining_spawns = 0
	is_wave_active = false
	for boss in get_tree().get_nodes_in_group("bosses"):
		boss.queue_free()
	on_boss_died(Vector2(270, 160), 0)


func _on_admin_instant_level_up() -> void:
	current_xp = xp_to_level
	on_xp_collected(0)


func _on_admin_set_level(level: int) -> void:
	current_level = level
	print("Admin: level set to ", level)


func on_admin_dps_check() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for boss in get_tree().get_nodes_in_group("bosses"):
		boss.queue_free()
	for bomb in get_tree().get_nodes_in_group("bombs"):
		bomb.queue_free()
	enemies_alive = 0
	is_wave_active = false
	is_boss_phase = false
	current_level = 14
	current_wave = 3
	start_dps_check()


func build_stats_text() -> String:
	var lines: Array = [
		"Level: " + str(current_level) + "  Wave: " + str(current_wave),
		"Enemies alive: " + str(enemies_alive),
		"Player XP: " + str(current_xp) + "/" + str(xp_to_level),
		"Player level: " + str(player_level),
		"Damage mult: " + str(snapped($Archer.damage_multiplier, 0.01)),
		"Fire rate mult: " + str(snapped($Archer.fire_rate_multiplier, 0.01)),
		"Pierce count: " + str($Archer.pierce_count),
		"Has multi-shot: " + str($Archer.has_multi_shot),
	]
	return "\n".join(lines)


func on_debug_pressed() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("die"):
			enemy.die()
	enemies_alive = 0
	hud.update_enemy_count(0)


func calculate_score() -> int:
	return (enemies_killed * 50) + (current_level * 500) + (current_wave * 100)


func on_archer_died() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for boss in get_tree().get_nodes_in_group("bosses"):
		boss.queue_free()
	for bomb in get_tree().get_nodes_in_group("bombs"):
		bomb.queue_free()
	for orb in get_tree().get_nodes_in_group("orbs"):
		orb.queue_free()
	var final_score: int = calculate_score() + ($Archer.current_lives * 500)
	game_over_screen.show_screen(current_level, current_wave, final_score)


func show_warning_banner(message: String) -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 50
	var label: Label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 0.3, 0.3)
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.offset_top = 120.0
	label.offset_bottom = 145.0
	canvas.add_child(label)
	add_child(canvas)
	var tween: Tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(canvas.queue_free)


func start_dps_check() -> void:
	is_dps_check = true
	hud.wave_label.text = "FINAL TEST"
	var dummy: DPSDummy = DPS_DUMMY_SCENE.instantiate()
	dummy.dps_check_complete.connect(on_dps_complete)
	add_child(dummy)
	get_tree().create_timer(2.0).timeout.connect(dummy.start)


func on_dps_complete(dps: float) -> void:
	final_dps = dps
	for d in get_tree().get_nodes_in_group("dps_dummy"):
		d.queue_free()
	show_victory_screen()


func show_victory_screen() -> void:
	var final_score: int = calculate_score() + ($Archer.current_lives * 500) + (int(final_dps) * 30)
	victory_screen.show_screen(final_score, int(final_dps), $Archer.current_lives)


func on_restart_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func on_menu_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func on_quit_pressed() -> void:
	get_tree().quit()


func on_xp_collected(amount: int) -> void:
	var actual: int = int(float(amount) * $Archer.xp_multiplier)
	current_xp += actual
	while current_xp >= xp_to_level:
		current_xp -= xp_to_level
		xp_to_level += 5
		player_level += 1
		show_upgrade_screen()
	hud.update_xp(current_xp, xp_to_level, player_level)


func on_raw_xp_collected(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_level:
		current_xp -= xp_to_level
		xp_to_level += 5
		player_level += 1
		show_upgrade_screen()
	hud.update_xp(current_xp, xp_to_level, player_level)
