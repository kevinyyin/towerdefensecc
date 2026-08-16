extends Node2D

signal cooldown_started(duration: float)
signal cooldown_ended

const DamageType = preload("res://scripts/combat/damage_type.gd")
const SpellImpactScene = preload("res://scenes/spells/spell_impact.tscn")

@export var radius := 180.0
@export var damage := 40.0
@export var cooldown := 10.0

@onready var _cooldown_timer: Timer = $CooldownTimer

var _armed := false
var _on_cooldown := false

func _ready() -> void:
	add_to_group(&"spell_manager")
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)

func arm() -> void:
	if _on_cooldown or _armed:
		return
	_armed = true
	queue_redraw()

func disarm() -> void:
	if _armed:
		_armed = false
		queue_redraw()

func _process(_delta: float) -> void:
	if _armed:
		global_position = get_global_mouse_position()
		queue_redraw()

func _draw() -> void:
	if _armed:
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.4, 0.1, 0.15))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.4, 0.1, 0.7), 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if not _armed:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_cast(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			disarm()

func _cast(target_pos: Vector2) -> void:
	_armed = false
	queue_redraw()

	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if is_instance_valid(enemy) and target_pos.distance_to(enemy.global_position) <= radius:
			enemy.take_damage(damage, DamageType.Type.MAGIC)

	var impact := SpellImpactScene.instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_position = target_pos
	impact.radius = radius

	_start_cooldown()

func _start_cooldown() -> void:
	_on_cooldown = true
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.start()
	cooldown_started.emit(cooldown)

func _on_cooldown_timeout() -> void:
	_on_cooldown = false
	cooldown_ended.emit()
