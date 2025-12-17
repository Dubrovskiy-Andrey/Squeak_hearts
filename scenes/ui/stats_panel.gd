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
	
	# ПОДКЛЮЧАЕМ ВСЕ СИГНАЛЫ ДЛЯ АВТООБНОВЛЕНИЯ
	_connect_player_signals()
	
	# Первоначальное обновление
	refresh_stats()

func _connect_player_signals():
	# Подключаемся ко всем нужным сигналам игрока
	if player_node.has_signal("health_changed"):
		player_node.health_changed.connect(_on_player_health_changed)
		print("StatsPanel: Подписан на health_changed")
	
	if player_node.has_signal("currency_changed"):
		player_node.currency_changed.connect(_on_player_currency_changed)
		print("StatsPanel: Подписан на currency_changed")
	
	# Если игрок имеет метод для обновления инвентаря (для талисманов)
	if player_node.has_method("_refresh_inventory_stats"):
		# Создаем таймер для периодической проверки
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 0.5  # Проверяем каждые 0.5 секунды
		timer.timeout.connect(_periodic_check)
		timer.start()

func _on_player_health_changed(current_health, max_health):
	# Обновляем статистику при изменении здоровья
	print("StatsPanel: Здоровье изменилось, обновляю статистику")
	refresh_stats()

func _on_player_currency_changed(new_amount):
	# Обновляем статистику при изменении валюты
	print("StatsPanel: Валюта изменилась на ", new_amount, ", обновляю статистику")
	refresh_stats()

func _periodic_check():
	# Периодическая проверка на случай, если что-то не сработало
	refresh_stats()

func refresh_stats():
	if player_node == null:
		# Пробуем найти игрока снова
		player_node = get_tree().get_first_node_in_group("players")
		if player_node == null:
			return
	
	# Используем существующие методы игрока
	if health_label:
		health_label.text = player_node.get_player_health()
	if damage_label:
		damage_label.text = str(player_node.get_player_damage())
	if currency_label:
		currency_label.text = str(player_node.get_player_currency())
	
	print("📊 StatsPanel обновлен:", 
		"HP:", player_node.get_player_health() if health_label else "N/A",
		"DMG:", player_node.get_player_damage() if damage_label else "N/A",
		"Trash:", player_node.get_player_currency() if currency_label else "N/A")
