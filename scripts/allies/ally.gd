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
@onready var _sprite: AnimatedSprite2D = $Visual

var current_hp: float
var engaged_by: Node2D = null
var rally_point: Vector2 = Vector2.ZERO
var _target: Node2D = null
var _action_playing := false
var _dying := false

func _ready() -> void:
	add_to_group(&"allies")
	max_hp *= Upgrades.get_multiplier("ally_max_hp")
	current_hp = max_hp

	_lifespan_timer.wait_time = lifespan
	_lifespan_timer.one_shot = true
	_lifespan_timer.timeout.connect(queue_free)
	_lifespan_timer.start()

	_attack_cooldown.wait_time = 1.0 / attack_rate
	_attack_cooldown.one_shot = false
	_attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
	_attack_cooldown.start()

	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play(&"idle")

func _physics_process(_delta: float) -> void:
	if _dying:
		return

	_target = _find_nearest_enemy()

	if _target != null:
		var to_target := _target.global_position - global_position
		_face(to_target.x)
		if to_target.length() > melee_range:
			velocity = to_target.normalized() * speed
			move_and_slide()
			_set_locomotion_animation(&"walk")
		else:
			velocity = Vector2.ZERO
			_set_locomotion_animation(&"idle")
		return

	var to_rally := rally_point - global_position
	if to_rally.length() > arrival_threshold:
		velocity = to_rally.normalized() * speed
		move_and_slide()
		_face(velocity.x)
		_set_locomotion_animation(&"walk")
	else:
		velocity = Vector2.ZERO
		_set_locomotion_animation(&"idle")

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
	if _dying or _target == null or not is_instance_valid(_target):
		return
	if global_position.distance_to(_target.global_position) <= melee_range:
		_target.take_damage(melee_damage)
		_play_action(&"attack")

func take_damage(amount: float) -> void:
	if _dying:
		return
	current_hp -= amount
	_health_bar.fraction = current_hp / max_hp
	if current_hp <= 0:
		_dying = true
		remove_from_group(&"allies")
		_lifespan_timer.stop()
		set_physics_process(false)
		_sprite.play(&"death")
		await _sprite.animation_finished
		queue_free()
	else:
		_play_action(&"hurt")

func _play_action(anim_name: StringName) -> void:
	_action_playing = true
	_sprite.play(anim_name)

func _on_animation_finished() -> void:
	if _sprite.animation == &"attack" or _sprite.animation == &"hurt":
		_action_playing = false

func _face(dx: float) -> void:
	if dx != 0.0:
		_sprite.flip_h = dx > 0.0

func _set_locomotion_animation(anim_name: StringName) -> void:
	if _action_playing:
		return
	if _sprite.animation != anim_name:
		_sprite.play(anim_name)
