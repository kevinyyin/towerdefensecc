extends Node

signal health_changed(current_hp: int, max_hp: int)
signal gold_changed(new_gold: int)
signal wave_started(wave_number: int)
signal game_over

@export var max_base_hp := 10
@export var starting_gold := 100

var base_hp: int
var gold: int
var current_wave: int = 0
var is_game_over: bool = false

func _ready() -> void:
	base_hp = max_base_hp
	gold = starting_gold

func take_damage(amount: int) -> void:
	if is_game_over:
		return
	base_hp = max(base_hp - amount, 0)
	health_changed.emit(base_hp, max_base_hp)
	if base_hp <= 0:
		_trigger_game_over()

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if amount > gold:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	wave_started.emit(wave_number)

func _trigger_game_over() -> void:
	is_game_over = true
	game_over.emit()
