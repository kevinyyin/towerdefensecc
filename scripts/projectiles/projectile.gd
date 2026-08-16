extends Node2D

const DamageType = preload("res://scripts/combat/damage_type.gd")

@export var speed := 400.0
@export var arrival_threshold := 6.0

var _target: Node2D
var _damage := 0.0
var _damage_type: DamageType.Type = DamageType.Type.PHYSICAL

func launch(target: Node2D, damage: float, damage_type: DamageType.Type = DamageType.Type.PHYSICAL) -> void:
	_target = target
	_damage = damage
	_damage_type = damage_type

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		queue_free()
		return

	var to_target := _target.global_position - global_position
	if to_target.length() <= arrival_threshold:
		_target.take_damage(_damage, _damage_type)
		queue_free()
		return

	global_position += to_target.normalized() * speed * delta
