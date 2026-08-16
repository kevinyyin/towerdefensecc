extends Node2D

@export var display_name := "Barracks"
@export var cost := 60
@export var spawn_interval := 10.0
@export var squad_size := 3
@export var ally_scene: PackedScene = preload("res://scenes/allies/ally.tscn")

@onready var _spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timeout)
	_spawn_timer.start()

func _on_spawn_timeout() -> void:
	var level := get_tree().get_first_node_in_group(&"level")
	var allies_container := level.get_node("AlliesContainer")
	var rally_point: Vector2 = level.get_nearest_path_point(global_position)

	for i in squad_size:
		var ally := ally_scene.instantiate()
		allies_container.add_child(ally)
		var angle := TAU * i / squad_size
		ally.global_position = global_position + Vector2(cos(angle), sin(angle)) * 20.0
		ally.rally_point = rally_point
