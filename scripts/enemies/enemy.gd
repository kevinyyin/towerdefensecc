extends CharacterBody2D

signal health_changed(current_hp: float, max_hp: float)
signal died(gold_reward: int)
signal reached_end

@export var max_hp := 20.0
@export var speed := 120.0
@export var gold_reward := 5

var current_hp: float
var path: Array[Vector2] = []
var path_progress := 0.0

var _target_index := 1

func _ready() -> void:
	current_hp = max_hp
	add_to_group(&"enemies")

func start(new_path: Array[Vector2]) -> void:
	path = new_path
	_target_index = 1
	path_progress = 0.0
	global_position = path[0]

func _physics_process(delta: float) -> void:
	if _target_index >= path.size():
		velocity = Vector2.ZERO
		return

	var target := path[_target_index]
	var to_target := target - global_position
	var step := speed * delta

	if to_target.length() <= step:
		path_progress += to_target.length()
		global_position = target
		velocity = Vector2.ZERO
		_target_index += 1
		if _target_index >= path.size():
			reached_end.emit()
			queue_free()
			return
	else:
		velocity = to_target.normalized() * speed
		path_progress += step

	move_and_slide()

func take_damage(amount: float) -> void:
	current_hp -= amount
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		died.emit(gold_reward)
		queue_free()
