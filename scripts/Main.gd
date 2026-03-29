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

var current_level: int = 1
var current_wave: int = 0
var enemies_alive: int = 0
var is_wave_active: bool = false
var is_boss_phase: bool = false
var wave_enemy_counts: Array = [3, 5, 7]
var spawn_interval: float = 0.8
var current_xp: int = 0
var xp_to_level: int = 10
var player_level: int = 1

var _remaining_spawns: int = 0
var _spawn_timer: Timer = null
var hud: HUD = null
var game_over_screen: GameOver = null
var upgrade_screen: UpgradeScreen = null
var pause_menu: PauseMenu = null


func _ready() -> void:
	$Archer.arrow_scene = preload("res://scenes/Arrow.tscn")
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	$Archer.hp_changed.connect(hud.update_player_hp)
	$Archer.died.connect(on_archer_died)
	$Archer.xp_gained.connect(on_xp_collected)
	hud.menu_button_pressed.connect(func():
		if upgrade_screen.visible or game_over_screen.visible:
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
	_remaining_spawns = wave_enemy_counts[current_wave - 1] + (current_level - 1) * 2
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
	if _remaining_spawns <= 0:
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
	boss.setup(200.0 + (current_level - 1) * 100.0, 60.0)
	boss.died.connect(on_boss_died)
	add_child(boss)
	hud.update_wave(current_wave, current_level)


func on_boss_died(death_position: Vector2, xp_amount: int) -> void:
	is_boss_phase = false
	current_level += 1
	current_wave = 0
	enemies_alive = 0
	var orb: XPOrb = XP_ORB_SCENE.instantiate()
	orb.setup(xp_amount, $Archer.xp_auto_collect_radius)
	orb.position = death_position
	orb.collected.connect(on_xp_collected)
	add_child(orb)
	get_tree().create_timer(3.0).timeout.connect(start_next_wave)


func spawn_enemy() -> void:
	var enemy: BasicEnemy = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(randf_range(40.0, 500.0), -40.0)
	var hp: float = 30.0 + (current_level - 1) * 15.0
	var speed: float = 80.0 + (current_level - 1) * 10.0
	enemy.setup(hp, speed)
	enemy.died.connect(on_enemy_died)
	add_child(enemy)


func on_enemy_died(death_position: Vector2, xp_amount: int) -> void:
	enemies_alive = max(0, enemies_alive - 1)
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
	elif event.keycode == KEY_K:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.has_method("die"):
				enemy.die()
	elif event.keycode == KEY_B:
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
	elif event.keycode == KEY_N:
		for boss in get_tree().get_nodes_in_group("bosses"):
			boss.queue_free()
		on_boss_died(Vector2(270, 160), 0)


func on_debug_pressed() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("die"):
			enemy.die()
	enemies_alive = 0
	hud.update_enemy_count(0)


func on_archer_died() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for boss in get_tree().get_nodes_in_group("bosses"):
		boss.queue_free()
	for bomb in get_tree().get_nodes_in_group("bombs"):
		bomb.queue_free()
	for orb in get_tree().get_nodes_in_group("orbs"):
		orb.queue_free()
	game_over_screen.show_screen(current_level, current_wave)


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
