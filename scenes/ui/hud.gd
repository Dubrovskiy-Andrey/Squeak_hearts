extends Control

@onready var health_bar: TextureProgressBar = $HealthBar

func _ready():
	# Находим игрока в сцене и подключаемся к сигналу
	var player = get_tree().get_first_node_in_group("players")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		# Инициализируем полоску здоровья текущими значениями
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health

func _on_player_health_changed(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health
