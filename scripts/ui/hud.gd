extends CanvasLayer

@onready var _health_label: Label = $Margin/TopBar/HealthRow/HealthLabel
@onready var _gold_label: Label = $Margin/TopBar/GoldRow/GoldLabel
@onready var _rain_of_fire_button: Button = $AbilityBar/RainOfFireButton
@onready var _hero_ability_button: Button = $AbilityBar/HeroAbilityButton

func _ready() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.gold_changed.connect(_on_gold_changed)
	_on_health_changed(GameManager.base_hp, GameManager.max_base_hp)
	_on_gold_changed(GameManager.gold)

	_rain_of_fire_button.pressed.connect(_on_rain_of_fire_pressed)
	_hero_ability_button.pressed.connect(_on_hero_ability_pressed)

	var spell_manager := get_tree().get_first_node_in_group(&"spell_manager")
	if spell_manager:
		spell_manager.cooldown_started.connect(_on_spell_cooldown_started)
		spell_manager.cooldown_ended.connect(_on_spell_cooldown_ended)

	var hero := get_tree().get_first_node_in_group(&"hero")
	if hero:
		hero.ability_activated.connect(_on_hero_ability_activated)
		hero.ability_ended.connect(_on_hero_ability_ended)

func _on_health_changed(current_hp: int, _max_hp: int) -> void:
	_health_label.text = "%d" % current_hp

func _on_gold_changed(new_gold: int) -> void:
	_gold_label.text = str(new_gold)

func _on_rain_of_fire_pressed() -> void:
	var spell_manager := get_tree().get_first_node_in_group(&"spell_manager")
	if spell_manager:
		spell_manager.arm()

func _on_hero_ability_pressed() -> void:
	var hero := get_tree().get_first_node_in_group(&"hero")
	if hero:
		hero.activate_ability()

func _on_spell_cooldown_started(_duration: float) -> void:
	_rain_of_fire_button.disabled = true
	_rain_of_fire_button.modulate.a = 0.4

func _on_spell_cooldown_ended() -> void:
	_rain_of_fire_button.disabled = false
	_rain_of_fire_button.modulate.a = 1.0

func _on_hero_ability_activated(_duration: float) -> void:
	_hero_ability_button.disabled = true
	_hero_ability_button.modulate.a = 0.4

func _on_hero_ability_ended() -> void:
	_hero_ability_button.disabled = false
	_hero_ability_button.modulate.a = 1.0
