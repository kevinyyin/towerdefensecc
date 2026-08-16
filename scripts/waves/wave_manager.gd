extends Node

@export var enemy_scene: PackedScene
@export var enemies_per_wave := 5
@export var spawn_interval := 0.8
@export var time_between_waves := 4.0

var current_wave := 0
var _active_enemies := 0
var _world_path: Array[Vector2] = []

@onready var _level: Node = get_parent()
@onready var _enemy_container: Node2D = _level.get_node("EnemyContainer")

func _ready() -> void:
	_world_path = _level.get_world_path()
	_run_waves()

func _run_waves() -> void:
	while true:
		current_wave += 1
		GameManager.start_wave(current_wave)

		for i in enemies_per_wave:
			_spawn_enemy()
			await get_tree().create_timer(spawn_interval).timeout

		while _active_enemies > 0:
			await get_tree().create_timer(0.25).timeout

		await get_tree().create_timer(time_between_waves).timeout

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
