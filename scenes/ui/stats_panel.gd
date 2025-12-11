extends Control

@onready var health_label: Label = $HealthLabel
@onready var damage_label: Label = $DamageLabel
@onready var currency_label: Label = $CurrencyLabel

var player_node: Node = null

func _ready():
	# Ищем игрока, но через отложенный вызов, чтобы скрипт успел загрузиться
	call_deferred("_find_player_and_refresh")

func _find_player_and_refresh():
	player_node = get_tree().get_first_node_in_group("players")
	if player_node == null:
		print("StatsPanel: Игрок не найден!")
		return
	# Проверяем методы, чтобы избежать крашей
	if not player_node.has_method("get_player_health") or not player_node.has_method("get_player_damage") or not player_node.has_method("get_player_currency"):
		print("StatsPanel: Методы игрока не найдены!")
		return
	refresh_stats()

func refresh_stats():
	if player_node == null:
		return
	if health_label:
		health_label.text = player_node.get_player_health()
	if damage_label:
		damage_label.text = str(player_node.get_player_damage())
	if currency_label:
		currency_label.text = str(player_node.get_player_currency())
