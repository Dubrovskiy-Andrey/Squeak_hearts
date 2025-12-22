extends Area2D

var can_interact = false
@export var npc_name: String = "salli"

# Уровни прокачки (сохраняются)
var upgrade_levels = {
	"health_damage": 0,      # Основная прокачка (HP + урон)
	"extra_cheese": 0,       # +1 сыр (макс 1 уровень)
	"drop_chance": 0,        # +20% шанс дропа (макс 3 уровня)
	"cheese_health": 0       # +HP сыру (макс 3 уровня)
}

# Стоимость улучшений
var upgrades_data = {
	"health_damage": {
		"name": "Улучшение персонажа",
		"max_level": 3,
		"costs": [
			{"trash": 100, "crystals": 1, "hp_bonus": 20, "damage_bonus": 5},
			{"trash": 150, "crystals": 2, "hp_bonus": 25, "damage_bonus": 7},
			{"trash": 200, "crystals": 3, "hp_bonus": 30, "damage_bonus": 10}
		],
		"description": "Увеличивает HP и урон персонажа"
	},
	"extra_cheese": {
		"name": "Дополнительный сыр",
		"max_level": 1,
		"costs": [
			{"crystals": 10, "extra_cheese": 1}
		],
		"description": "Добавляет +1 слот для сыра"
	},
	"drop_chance": {
		"name": "Удача охотника",
		"max_level": 3,
		"costs": [
			{"crystals": 5, "drop_bonus": 0.05},
			{"crystals": 8, "drop_bonus": 0.10},
			{"crystals": 12, "drop_bonus": 0.20}
		],
		"description": "Увеличивает шанс выпадения кристаллов на +20%"
	},
	"cheese_health": {
		"name": "Усиление сыра",
		"max_level": 3,
		"costs": [
			{"crystals": 2, "cheese_hp_bonus": 200},
			{"crystals": 4, "cheese_hp_bonus": 300},
			{"crystals": 6, "cheese_hp_bonus": 400}
		],
		"description": "Увеличивает максимальное HP сыра на арене"
	}
}

func _ready():
	print("NPC Salli готов к работе")
	
	# Подключаемся к сигналам Dialogic 2
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	# Загружаем сохранённые уровни прокачки
	load_upgrade_levels()

	
	if $Label:
		$Label.visible = false

func load_upgrade_levels():
	if save_system:
		for upgrade_type in upgrade_levels.keys():
			var key = npc_name + "_" + upgrade_type
			upgrade_levels[upgrade_type] = save_system.get_npc_upgrade_level(key)
		print("📂 Уровни прокачки Salli загружены: ", upgrade_levels)
	else:
		print("❌ SaveSystem не найден!")

func save_upgrade_level(upgrade_type: String, new_level: int):
	if save_system:
		var key = npc_name + "_" + upgrade_type
		save_system.set_npc_upgrade_level(key, new_level)
		print("💾 Уровень прокачки сохранен: ", upgrade_type, " = ", new_level)
		
		# Сохраняем игру
		var player = get_tree().get_first_node_in_group("players")
		if player:
			save_system.save_game(player)

func _physics_process(_delta):
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play()
	
	if can_interact and Input.is_action_just_pressed("interact"):
		start_dialog()

func start_dialog():
	print("💬 Начинаем диалог с Salli")
	
	# Обновляем переменные Dialogic перед началом
	update_dialogic_variables()
	
	# Запускаем основной диалог (ИСПОЛЬЗУЕМ salli_upgrade_timeline)
	Dialogic.start("salli_upgrade_timeline")

func update_dialogic_variables():
	# Обновляем данные игрока
	var player = get_tree().get_first_node_in_group("players")
	if player:
		Dialogic.VAR.set('player_currency', player.currency)
		
		var crystal_count = 0
		if PlayerInventory:
			crystal_count = PlayerInventory.get_crystal_count()
		Dialogic.VAR.set('player_crystals', crystal_count)
		print("💰 Игрок: Trash=", player.currency, ", Crystals=", crystal_count)
	
	# Основное улучшение (HP + урон) - ДЛЯ СОВМЕСТИМОСТИ
	var main_level = upgrade_levels["health_damage"]
	Dialogic.VAR.set('upgrade_level', main_level)
	
	# Стоимость основного улучшения
	if main_level < upgrades_data["health_damage"]["max_level"]:
		var cost_data = upgrades_data["health_damage"]["costs"][main_level]
		Dialogic.VAR.set('current_upgrade_cost', cost_data.get("trash", 0))
		Dialogic.VAR.set('current_crystal_cost', cost_data.get("crystals", 0))
		print("💵 Стоимость улучшения: ", cost_data.get("trash", 0), " Trash + ", cost_data.get("crystals", 0), " Crystals")
	else:
		Dialogic.VAR.set('current_upgrade_cost', 0)
		Dialogic.VAR.set('current_crystal_cost', 0)
	
	# Кристальные улучшения
	Dialogic.VAR.set('extra_cheese_level', upgrade_levels["extra_cheese"])
	Dialogic.VAR.set('drop_chance_level', upgrade_levels["drop_chance"])
	Dialogic.VAR.set('cheese_health_level', upgrade_levels["cheese_health"])
	
	# Максимальные уровни
	Dialogic.VAR.set('extra_cheese_max', 1)
	Dialogic.VAR.set('drop_chance_max', 3)
	Dialogic.VAR.set('cheese_health_max', 3)
	
	# Статусы улучшений (для условий в Dialogic)
	Dialogic.VAR.set('can_upgrade_health', main_level < 3)
	Dialogic.VAR.set('can_upgrade_cheese', upgrade_levels["extra_cheese"] < 1)
	Dialogic.VAR.set('can_upgrade_drop', upgrade_levels["drop_chance"] < 3)
	Dialogic.VAR.set('can_upgrade_cheese_hp', upgrade_levels["cheese_health"] < 3)
	
	print("📊 Основная прокачка: уровень", main_level, "/3")
	print("📊 Доп. сыр: уровень", upgrade_levels["extra_cheese"], "/1")
	print("📊 Шанс дропа: уровень", upgrade_levels["drop_chance"], "/3")
	print("📊 HP сыра: уровень", upgrade_levels["cheese_health"], "/3")

func _on_body_entered(body):
	if body.is_in_group("players"):
		print("✅ Игрок вошел в зону Salli")
		if $Label:
			$Label.visible = true
			$Label.text = "Нажми E для разговора"
		can_interact = true

func _on_body_exited(body):
	if body.is_in_group("players"):
		print("✅ Игрок вышел из зоны Salli")
		if $Label:
			$Label.visible = false
		can_interact = false

func _on_dialogic_signal(argument: String):
	print("📢 Получен сигнал от Dialogic:", argument)
	
	match argument:
		# Основное улучшение
		"upgrade_health_damage":
			try_upgrade("health_damage")
		
		# Кристальные улучшения
		"upgrade_extra_cheese":
			try_upgrade("extra_cheese")
		"upgrade_drop_chance":
			try_upgrade("drop_chance")
		"upgrade_cheese_health":
			try_upgrade("cheese_health")
		
		# Переключение диалогов
		"salli_crystal_upgrades":
			print("🔄 Переходим к кристальным улучшениям")
			update_dialogic_variables()
			Dialogic.start("salli_crystal_upgrades")
		
		"salli_upgrade_timeline":  # ИСПРАВЛЕНО: используем твой timeline
			print("🔄 Возвращаемся в главное меню")
			update_dialogic_variables()
			Dialogic.start("salli_upgrade_timeline")
		
		"exit_dialog":
			print("👋 Выходим из диалога")
		
		_:
			print("⚠️ Неизвестный сигнал:", argument)

func try_upgrade(upgrade_type: String):
	print("🔄 Пытаюсь улучшить:", upgrade_type)
	
	# Проверяем можно ли улучшать дальше
	var current_level = upgrade_levels[upgrade_type]
	var max_level = upgrades_data[upgrade_type]["max_level"]
	
	if current_level >= max_level:
		print("❌ Максимальный уровень достигнут!")
		show_notification("❌ МАКСИМАЛЬНЫЙ УРОВЕНЬ!", Color(1, 0.3, 0.3))
		return
	
	# Получаем стоимость улучшения
	var cost_data = upgrades_data[upgrade_type]["costs"][current_level]
	
	# Проверяем ресурсы игрока
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		print("❌ Игрок не найден!")
		return
	
	# Проверяем валюту (если требуется)
	if cost_data.has("trash") and player.currency < cost_data["trash"]:
		print("❌ Недостаточно валюты! Нужно:", cost_data["trash"], " есть:", player.currency)
		show_notification("❌ НЕДОСТАТОЧНО ВАЛЮТЫ!", Color(1, 0.3, 0.3))
		return
	
	# Проверяем кристаллы (если требуется)
	if cost_data.has("crystals"):
		var crystal_cost = cost_data["crystals"]
		var player_crystals = PlayerInventory.get_crystal_count() if PlayerInventory else 0
		if player_crystals < crystal_cost:
			print("❌ Недостаточно кристаллов! Нужно:", crystal_cost, " есть:", player_crystals)
			show_notification("❌ НЕДОСТАТОЧНО КРИСТАЛЛОВ!", Color(1, 0.3, 0.3))
			return
	
	# Применяем улучшение
	if apply_upgrade(upgrade_type, cost_data, player):
		# Увеличиваем уровень
		upgrade_levels[upgrade_type] += 1
		
		# Сохраняем новый уровень
		save_upgrade_level(upgrade_type, upgrade_levels[upgrade_type])
		
		# Обновляем переменные Dialogic
		update_dialogic_variables()
		
		print("✅ Улучшение применено:", upgrade_type, " уровень", upgrade_levels[upgrade_type])
		show_notification("✅ УЛУЧШЕНИЕ ПРИМЕНЕНО!", Color(0.3, 1, 0.3))
	else:
		print("❌ Ошибка при применении улучшения")
		show_notification("❌ ОШИБКА!", Color(1, 0.3, 0.3))

func apply_upgrade(upgrade_type: String, cost_data: Dictionary, player) -> bool:
	print("✨ Применяю улучшение:", upgrade_type, " за ", cost_data)
	
	# Тратим ресурсы
	if cost_data.has("trash"):
		player.currency -= cost_data["trash"]
		player.emit_signal("currency_changed", player.currency)
		print("💰 Потрачено валюты:", cost_data["trash"])
	
	if cost_data.has("crystals"):
		var crystal_cost = cost_data["crystals"]
		if PlayerInventory:
			PlayerInventory.spend_crystals(crystal_cost)
			print("💎 Потрачено кристаллов:", crystal_cost)
	
	# Применяем бонусы в зависимости от типа улучшения
	match upgrade_type:
		"health_damage":
			# Увеличиваем HP и урон персонажа
			if cost_data.has("hp_bonus") and cost_data.has("damage_bonus"):
				player.max_health += cost_data["hp_bonus"]
				player.current_health += cost_data["hp_bonus"]
				player.attack_damage += cost_data["damage_bonus"]
				
				player.emit_signal("health_changed", player.current_health, player.max_health + player.talisman_hp_bonus)
				print("❤️ +", cost_data["hp_bonus"], " HP, ⚔️ +", cost_data["damage_bonus"], " урона")
				print("❤️ Теперь HP: ", player.current_health, "/", player.max_health)
				print("⚔️ Теперь урон: ", player.attack_damage)
		
		"extra_cheese":
			# Добавляем +1 слот для сыра
			if cost_data.has("extra_cheese"):
				# Используем метод добавления слота
				if player.has_method("add_extra_cheese_slot"):
					player.add_extra_cheese_slot()
				else:
					# Резервный вариант
					if "salli_extra_cheese_slots" in player:
						player.salli_extra_cheese_slots += cost_data["extra_cheese"]
					player.cheese_bites.append(3)
					player.emit_cheese_changed()
				
				print("🧀 +", cost_data["extra_cheese"], " слот для сыра")
				print("🧀 Теперь слотов для сыра: ", player.cheese_bites.size())
		
		"drop_chance":
			# Увеличиваем шанс дропа (логика в врагах)
			if cost_data.has("drop_bonus"):
				print("🎯 +", int(cost_data["drop_bonus"] * 100), "% к шансу дропа")
				print("🎯 Общий бонус дропа: ", upgrade_levels["drop_chance"] * 5, "%")
		
		"cheese_health":
			# Увеличиваем HP сыра на арене
			if cost_data.has("cheese_hp_bonus"):
				print("🧀 +", cost_data["cheese_hp_bonus"], " HP сыру на арене")
				print("🧀 Общий бонус HP сыра: ", upgrade_levels["cheese_health"] * 200, " HP")
	
	# Обновляем статистику игрока
	if player.has_method("_refresh_inventory_stats"):
		player._refresh_inventory_stats()
	
	# Сохраняем игру
	if save_system:
		save_system.save_game(player)
	
	return true

func show_notification(text: String, color: Color = Color(1, 1, 1)):
	var notification = Label.new()
	notification.text = text
	notification.position = global_position + Vector2(0, -80)
	get_parent().add_child(notification)
	
	notification.add_theme_color_override("font_color", color)
	notification.add_theme_font_size_override("font_size", 20)
	notification.add_theme_font_override("font", load("res://Fonts/m5x7.ttf") if ResourceLoader.exists("res://Fonts/m5x7.ttf") else null)
	
	var tween = create_tween()
	tween.tween_property(notification, "position:y", notification.position.y - 40, 1.0)
	tween.parallel().tween_property(notification, "modulate:a", 0, 1.5)
	
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(notification):
		notification.queue_free()

# Методы для получения информации об улучшениях
func get_upgrade_info(upgrade_type: String) -> Dictionary:
	var info = {
		"current_level": upgrade_levels[upgrade_type],
		"max_level": upgrades_data[upgrade_type]["max_level"],
		"name": upgrades_data[upgrade_type]["name"],
		"description": upgrades_data[upgrade_type]["description"],
		"can_upgrade": false,
		"next_cost": {}
	}
	
	if info["current_level"] < info["max_level"]:
		info["can_upgrade"] = true
		info["next_cost"] = upgrades_data[upgrade_type]["costs"][info["current_level"]]
	
	return info

func get_all_upgrade_levels() -> Dictionary:
	return upgrade_levels.duplicate()
