extends CanvasLayer

@onready var _health_label: Label = $Margin/TopBar/HealthRow/HealthLabel
@onready var _gold_label: Label = $Margin/TopBar/GoldRow/GoldLabel

func _ready() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.gold_changed.connect(_on_gold_changed)
	_on_health_changed(GameManager.base_hp, GameManager.max_base_hp)
	_on_gold_changed(GameManager.gold)

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	_health_label.text = "%d" % current_hp

func _on_gold_changed(new_gold: int) -> void:
	_gold_label.text = str(new_gold)
