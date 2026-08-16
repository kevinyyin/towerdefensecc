extends CharacterBody2D

const HealthBar = preload("res://scripts/ui/health_bar.gd")

signal ability_activated(duration: float)
signal ability_ended

@export var speed := 140.0
@export var max_hp := 60.0
@export var aggro_radius := 160.0
@export var melee_range := 28.0
@export var melee_damage := 10.0
@export var attack_rate := 1.5
@export var arrival_threshold := 8.0

@export var ability_duration := 5.0
@export var ability_attack_speed_bonus := 0.25

@onready var _attack_cooldown: Timer = $AttackCooldown
@onready var _ability_timer: Timer = $AbilityTimer
@onready var _health_bar: HealthBar = $HealthBar

var current_hp: float
var engaged_by: Node2D = null
var _move_target: Vector2
var _target: Node2D = null
var _invulnerable := false
var _ability_active := false

func _ready() -> void:
	add_to_group(&"allies")
	add_to_group(&"hero")
	current_hp = max_hp
	_move_target = global_position

	_attack_cooldown.wait_time = 1.0 / attack_rate
	_attack_cooldown.one_shot = false
	_attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
	_attack_cooldown.start()

	_ability_timer.one_shot = true
	_ability_timer.timeout.connect(_on_ability_timeout)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_move_target = get_global_mouse_position()

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

	var to_move := _move_target - global_position
	if to_move.length() > arrival_threshold:
		velocity = to_move.normalized() * speed
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

func activate_ability() -> void:
	if _ability_active:
		return

	_ability_active = true
	_invulnerable = true
	_attack_cooldown.wait_time = (1.0 / attack_rate) / (1.0 + ability_attack_speed_bonus)
	modulate = Color(1.6, 1.6, 0.9)

	_ability_timer.wait_time = ability_duration
	_ability_timer.start()
	ability_activated.emit(ability_duration)

func _on_ability_timeout() -> void:
	_ability_active = false
	_invulnerable = false
	_attack_cooldown.wait_time = 1.0 / attack_rate
	modulate = Color(1, 1, 1)
	ability_ended.emit()

func take_damage(amount: float) -> void:
	if _invulnerable:
		return
	current_hp -= amount
	_health_bar.fraction = current_hp / max_hp
	if current_hp <= 0:
		queue_free()
