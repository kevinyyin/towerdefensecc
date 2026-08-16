extends CanvasLayer

const UPGRADE_DEFS := [
	{"key": "archer_fire_rate", "label": "Archer Fire Rate"},
	{"key": "ally_max_hp", "label": "Barracks Soldier HP"},
	{"key": "mage_damage", "label": "Mage Damage"},
	{"key": "artillery_range", "label": "Artillery Range"},
]

@onready var _stars_label: Label = $CenterContainer/VBox/StarsLabel
@onready var _back_button: Button = $CenterContainer/VBox/BackButton
@onready var _rows: Array[HBoxContainer] = [
	$CenterContainer/VBox/ArcherRow,
	$CenterContainer/VBox/AllyRow,
	$CenterContainer/VBox/MageRow,
	$CenterContainer/VBox/ArtilleryRow,
]

func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	for i in UPGRADE_DEFS.size():
		var button: Button = _rows[i].get_node("BuyButton")
		button.pressed.connect(_on_buy_pressed.bind(UPGRADE_DEFS[i]["key"]))
	_refresh()

func _refresh() -> void:
	_stars_label.text = "★ %d" % Upgrades.stars
	for i in UPGRADE_DEFS.size():
		var def = UPGRADE_DEFS[i]
		var key: String = def["key"]
		var row := _rows[i]
		var label: Label = row.get_node("StatLabel")
		var button: Button = row.get_node("BuyButton")
		var level := Upgrades.get_level(key)
		label.text = "%s (Lv %d/%d)" % [def["label"], level, Upgrades.MAX_LEVEL]
		if Upgrades.is_maxed(key):
			button.text = "Maxed"
			button.disabled = true
		else:
			button.text = "Upgrade (%d★)" % Upgrades.get_cost(key)
			button.disabled = not Upgrades.can_afford(key)

func _on_buy_pressed(key: String) -> void:
	if Upgrades.purchase(key):
		_refresh()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
