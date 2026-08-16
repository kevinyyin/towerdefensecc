extends CharacterBody2D

const HealthBar = preload("res://scripts/ui/health_bar.gd")

@export var speed := 90.0
@export var aggro_radius := 140.0
@export var melee_range := 26.0
@export var melee_damage := 6.0
@export var attack_rate := 1.5
@export var lifespan := 12.0
@export var max_hp := 25.0
@export var arrival_threshold := 8.0

@onready var _attack_cooldown: Timer = $AttackCooldown
@onready var _lifespan_timer: Timer = $LifespanTimer
@onready var _health_bar: HealthBar = $HealthBar

var current_hp: float
var engaged_by: Node2D = null
var rally_point: Vector2 = Vector2.ZERO
var _target: Node2D = null

func _ready() -> void:
	add_to_group(&"allies")
	current_hp = max_hp

	_lifespan_timer.wait_time = lifespan
	_lifespan_timer.one_shot = true
	_lifespan_timer.timeout.connect(queue_free)
	_lifespan_timer.start()

	_attack_cooldown.wait_time = 1.0 / attack_rate
	_attack_cooldown.one_shot = false
	_attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
	_attack_cooldown.start()

func _physics_process(_delta: float) -> void:
	_target = _find_nearest_enemy()

	if _target != null:
		var to_target := _target.global_position - global_position
		if to_target.length() > melee_range:
			velocity = to_target.normalized() * speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
		return

	var to_rally := rally_point - global_position
	if to_rally.length() > arrival_threshold:
		velocity = to_rally.normalized() * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := aggro_radius
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= nearest_dist:
			nearest = enemy
			nearest_dist = dist
	return nearest

func _on_attack_cooldown_timeout() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if global_position.distance_to(_target.global_position) <= melee_range:
		_target.take_damage(melee_damage)

func take_damage(amount: float) -> void:
	current_hp -= amount
	_health_bar.fraction = current_hp / max_hp
	if current_hp <= 0:
		queue_free()
