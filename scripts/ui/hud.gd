extends CanvasLayer

const TOWER_SCENES: Array[PackedScene] = [
	preload("res://scenes/towers/tower_basic.tscn"),
	preload("res://scenes/towers/tower_rapid.tscn"),
	preload("res://scenes/towers/tower_heavy.tscn"),
	preload("res://scenes/towers/tower_sniper.tscn"),
]

@onready var _health_label: Label = $Margin/TopBar/HealthRow/HealthLabel
@onready var _gold_label: Label = $Margin/TopBar/GoldRow/GoldLabel
@onready var _tower_buttons: Array[Button] = [
	$TowerMenu/TowerButtonBasic,
	$TowerMenu/TowerButtonRapid,
	$TowerMenu/TowerButtonHeavy,
	$TowerMenu/TowerButtonSniper,
]

var _tower_costs: Array[int] = []
var _placer: Node = null

func _ready() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.gold_changed.connect(_on_gold_changed)
	_on_health_changed(GameManager.base_hp, GameManager.max_base_hp)
	_build_tower_menu()
	_on_gold_changed(GameManager.gold)

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	_health_label.text = "%d" % current_hp

func _on_gold_changed(new_gold: int) -> void:
	_gold_label.text = str(new_gold)
	_update_tower_button_states(new_gold)

func _build_tower_menu() -> void:
	for i in TOWER_SCENES.size():
		var scene := TOWER_SCENES[i]
		var probe := scene.instantiate()
		var button := _tower_buttons[i]
		button.text = "%s\n%d g" % [probe.display_name, probe.cost]
		_tower_costs.append(probe.cost)
		probe.free()
		button.pressed.connect(_on_tower_button_pressed.bind(scene))

func _on_tower_button_pressed(scene: PackedScene) -> void:
	var placer := _get_placer()
	if placer != null:
		placer.arm(scene)

func _update_tower_button_states(new_gold: int) -> void:
	for i in _tower_buttons.size():
		var affordable := new_gold >= _tower_costs[i]
		_tower_buttons[i].disabled = not affordable
		_tower_buttons[i].modulate.a = 1.0 if affordable else 0.4

func _get_placer() -> Node:
	if _placer == null or not is_instance_valid(_placer):
		_placer = get_tree().get_first_node_in_group(&"tower_placer")
	return _placer
