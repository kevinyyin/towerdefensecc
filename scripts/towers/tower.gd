extends Area2D

enum TargetingMode { FIRST_IN_PATH, CLOSEST_TO_TOWER, STRONGEST }

@export var display_name := "Basic Turret"
@export var range_radius := 150.0
@export var fire_rate := 1.0 # shots per second
@export var damage := 10.0
@export var cost := 50
@export var targeting_mode: TargetingMode = TargetingMode.FIRST_IN_PATH
@export var projectile_scene: PackedScene

@export var range_upgrade_amount := 30.0
@export var power_upgrade_amount := 5.0

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _cooldown: Timer = $Cooldown
@onready var _click_area: Area2D = $ClickArea

var _enemies_in_range: Array[Node2D] = []

func _ready() -> void:
	_apply_range_shape()
	collision_mask = 2

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_cooldown.wait_time = 1.0 / fire_rate
	_cooldown.one_shot = false
	_cooldown.timeout.connect(_on_cooldown_timeout)
	_cooldown.start()

	get_viewport().physics_object_picking = true
	_click_area.input_pickable = true
	_click_area.input_event.connect(_on_click_area_input_event)

func _apply_range_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = range_radius
	_collision_shape.shape = shape

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print_stats()

func print_stats() -> void:
	print("Tower stats — range: %.0f  damage: %.0f  fire_rate: %.2f/s  cost: %d gold  targeting: %s" % [
		range_radius, damage, fire_rate, cost, TargetingMode.keys()[targeting_mode]
	])

func upgrade_range(gold_cost: int) -> bool:
	if not GameManager.spend_gold(gold_cost):
		print("Tower upgrade failed: need %d gold, have %d" % [gold_cost, GameManager.gold])
		return false
	range_radius += range_upgrade_amount
	_apply_range_shape()
	print("Tower range upgraded to %.0f (spent %d gold)" % [range_radius, gold_cost])
	print_stats()
	return true

func upgrade_power(gold_cost: int) -> bool:
	if not GameManager.spend_gold(gold_cost):
		print("Tower upgrade failed: need %d gold, have %d" % [gold_cost, GameManager.gold])
		return false
	damage += power_upgrade_amount
	print("Tower power upgraded to %.0f damage (spent %d gold)" % [damage, gold_cost])
	print_stats()
	return true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"enemies"):
		_enemies_in_range.append(body)

func _on_body_exited(body: Node2D) -> void:
	_enemies_in_range.erase(body)

func _on_cooldown_timeout() -> void:
	_enemies_in_range = _enemies_in_range.filter(is_instance_valid)

	var target := _select_target()
	if target == null or projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.launch(target, damage)

func _select_target() -> Node2D:
	if _enemies_in_range.is_empty():
		return null

	match targeting_mode:
		TargetingMode.CLOSEST_TO_TOWER:
			return _enemies_in_range.reduce(func(best, e):
				return e if global_position.distance_to(e.global_position) < global_position.distance_to(best.global_position) else best
			)
		TargetingMode.STRONGEST:
			return _enemies_in_range.reduce(func(best, e):
				return e if e.current_hp > best.current_hp else best
			)
		_: # FIRST_IN_PATH
			return _enemies_in_range.reduce(func(best, e):
				return e if e.path_progress > best.path_progress else best
			)
