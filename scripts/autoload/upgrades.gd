extends Node

const SAVE_PATH := "user://save.cfg"
const MAX_LEVEL := 5
const BONUS_PER_LEVEL := 0.1

const UPGRADE_KEYS: Array[String] = [
	"archer_fire_rate",
	"ally_max_hp",
	"mage_damage",
	"artillery_range",
]

var stars: int = 0
var last_stars_earned: int = 0

var _levels: Dictionary = {}

func _ready() -> void:
	for key in UPGRADE_KEYS:
		_levels[key] = 0
	_load()

func get_level(key: String) -> int:
	return _levels.get(key, 0)

func get_cost(key: String) -> int:
	return (get_level(key) + 1) * 2

func is_maxed(key: String) -> bool:
	return get_level(key) >= MAX_LEVEL

func can_afford(key: String) -> bool:
	return not is_maxed(key) and stars >= get_cost(key)

func purchase(key: String) -> bool:
	if not can_afford(key):
		return false
	stars -= get_cost(key)
	_levels[key] = get_level(key) + 1
	_save()
	return true

func add_stars(amount: int) -> void:
	stars += amount
	last_stars_earned = amount
	_save()

func get_multiplier(key: String) -> float:
	return 1.0 + get_level(key) * BONUS_PER_LEVEL

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "stars", stars)
	for key in UPGRADE_KEYS:
		cfg.set_value("upgrades", key, _levels[key])
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	stars = cfg.get_value("progress", "stars", 0)
	for key in UPGRADE_KEYS:
		_levels[key] = cfg.get_value("upgrades", key, 0)
