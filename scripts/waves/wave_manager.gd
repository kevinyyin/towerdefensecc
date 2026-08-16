extends Node

signal waiting_for_next_wave(is_waiting: bool)

@export var enemy_scene: PackedScene
@export var enemies_per_wave := 5
@export var spawn_interval := 0.8
@export var time_between_waves := 4.0
@export var early_start_bonus_gold := 15
@export var waves_to_win := 10

@onready var _level: Node = get_parent()
@onready var _enemy_container: Node2D = _level.get_node("EnemyContainer")
@onready var _between_waves: Timer = $BetweenWaves

var current_wave := 0
var _active_enemies := 0
var _world_path: Array[Vector2] = []

func _ready() -> void:
	add_to_group(&"wave_manager")
	_between_waves.one_shot = true
	_world_path = _level.get_world_path()
	_run_waves()

func _run_waves() -> void:
	while current_wave < waves_to_win:
		current_wave += 1
		GameManager.start_wave(current_wave)

		for i in enemies_per_wave:
			_spawn_enemy()
			await get_tree().create_timer(spawn_interval).timeout

		while _active_enemies > 0:
			await get_tree().create_timer(0.25).timeout

		if current_wave < waves_to_win:
			await _wait_between_waves()

	_trigger_victory()

func _trigger_victory() -> void:
	if GameManager.is_game_over:
		return

	var hp_fraction := float(GameManager.base_hp) / float(GameManager.max_base_hp)
	var stars := 1
	if hp_fraction >= 1.0:
		stars = 3
	elif hp_fraction >= 0.5:
		stars = 2

	Upgrades.add_stars(stars)
	get_tree().change_scene_to_file("res://scenes/menu/level_complete.tscn")

func _wait_between_waves() -> void:
	waiting_for_next_wave.emit(true)
	_between_waves.wait_time = time_between_waves
	_between_waves.start()
	await _between_waves.timeout
	waiting_for_next_wave.emit(false)

func start_next_wave_early() -> bool:
	if _between_waves.is_stopped():
		return false
	_between_waves.stop()
	GameManager.add_gold(early_start_bonus_gold)
	_between_waves.timeout.emit()
	return true

func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate()
	_enemy_container.add_child(enemy)
	enemy.start(_world_path)

	_active_enemies += 1
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)

func _on_enemy_died(gold_reward: int) -> void:
	_active_enemies -= 1
	GameManager.add_gold(gold_reward)

func _on_enemy_reached_end() -> void:
	_active_enemies -= 1
	GameManager.take_damage(1)
