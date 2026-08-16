extends CharacterBody2D

const DamageType = preload("res://scripts/combat/damage_type.gd")
const HealthBar = preload("res://scripts/ui/health_bar.gd")
const DeathExplosionScene = preload("res://scenes/effects/death_explosion.tscn")

const HEAVY_DAMAGE_THRESHOLD := 20.0
const HEAVY_HIT_SHAKE := 0.4

signal health_changed(current_hp: float, max_hp: float)
signal died(gold_reward: int)
signal reached_end

@export var max_hp := 20.0
@export var speed := 120.0
@export var gold_reward := 5
@export var armor := 2.0
@export var melee_range := 26.0
@export var melee_damage := 5.0
@export var attack_rate := 1.0

@onready var _attack_cooldown: Timer = $AttackCooldown
@onready var _health_bar: HealthBar = $HealthBar

var current_hp: float
var path: Array[Vector2] = []
var path_progress := 0.0

var _target_index := 1
var _melee_target: Node2D = null

func _ready() -> void:
	current_hp = max_hp
	add_to_group(&"enemies")

	_attack_cooldown.wait_time = 1.0 / attack_rate
	_attack_cooldown.one_shot = false
	_attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
	_attack_cooldown.start()

func start(new_path: Array[Vector2]) -> void:
	path = new_path
	_target_index = 1
	path_progress = 0.0
	global_position = path[0]

func _physics_process(delta: float) -> void:
	if _melee_target != null and not is_instance_valid(_melee_target):
		_melee_target = null
	if _melee_target == null:
		_melee_target = _find_nearby_ally()
	if _melee_target != null:
		velocity = Vector2.ZERO
		return

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

func _find_nearby_ally() -> Node2D:
	for ally in get_tree().get_nodes_in_group(&"allies"):
		if ally.engaged_by != null and ally.engaged_by != self:
			continue
		if global_position.distance_to(ally.global_position) <= melee_range:
			ally.engaged_by = self
			return ally
	return null

func _on_attack_cooldown_timeout() -> void:
	if _melee_target != null and is_instance_valid(_melee_target):
		_melee_target.take_damage(melee_damage)

func take_damage(amount: float, damage_type: DamageType.Type = DamageType.Type.PHYSICAL) -> void:
	var mitigated := amount
	if damage_type == DamageType.Type.PHYSICAL:
		mitigated = max(amount - armor, 0.0)

	current_hp -= mitigated
	health_changed.emit(current_hp, max_hp)
	_health_bar.fraction = current_hp / max_hp

	if mitigated >= HEAVY_DAMAGE_THRESHOLD:
		ScreenShake.shake(HEAVY_HIT_SHAKE)

	if current_hp <= 0:
		_release_melee_target()
		_spawn_death_explosion()
		died.emit(gold_reward)
		queue_free()

func _release_melee_target() -> void:
	if _melee_target != null and is_instance_valid(_melee_target) and _melee_target.engaged_by == self:
		_melee_target.engaged_by = null

func _spawn_death_explosion() -> void:
	var explosion := DeathExplosionScene.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
