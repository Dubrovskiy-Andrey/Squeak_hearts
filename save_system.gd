extends Node

const SAVE_PATH := "user://save_game.dat"

var save_data := {
	"player_data": {},
	"inventory_data": {},
	"talisman_data": {"equipped_talismans": ["", "", ""]},
	"npc_data": {},
	"scene_name": "",
	"last_save_type": "manual",
	"campfire_id": "",
	"enemies_killed": {},
	"items_collected": {},
	"campfire_restore_points": {},
	# ДОБАВИМ данные обучения
	"tutorial_data": {
		"tutorial_completed": false,
		"need_tutorial": true,
		"tutorial_skipped": false,
		"quests_completed": {},  # Состояние каждого квеста
		"quests_progress": {}    # Прогресс квестов (счетчики)
	}
}

func _ready():
	print("save_system готов")

func save_game(player: Node = null):
	print("💾 save_game вызван")
	
	if player:
		print("💾 Перед update_player_data, сыр: ", player.cheese_bites)
		update_player_data(player)
	
	print("💾 После update_player_data, save_data сыр: ", save_data["player_data"].get("cheese_bites", []))
	
	# Сохраняем инвентарь
	if PlayerInventory:
		save_data["inventory_data"] = PlayerInventory.save_inventory_data()
		print("💾 Инвентарь сохранен")
	
	# Сохраняем имя текущей сцены
	if get_tree().current_scene:
		save_data["scene_name"] = get_tree().current_scene.scene_file_path
		print("💾 Сцена сохранена: ", save_data["scene_name"])
	
	# Сохраняем талисманы из инвентаря
	var inv = _find_inventory()
	if inv:
		var arr := ["", "", ""]
		var equipped = inv.get_equipped_talismans()
		for i in range(min(3, equipped.size())):
			if equipped[i]:
				arr[i] = equipped[i]["name"]
		save_data["talisman_data"]["equipped_talismans"] = arr
		print("💾 Талисманы сохранены: ", arr)
	
	print("💾 Сохраняем данные: ", save_data.keys())
	print("💾 Данные игрока для сохранения: ", save_data["player_data"].keys())
	
	# Сохраняем в файл
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("💾 Игра сохранена. Тип: ", save_data.get("last_save_type", "manual"))
		print("💾 Сыр в сохранении: ", save_data["player_data"].get("cheese_bites", []))
		print("💾 Все данные игрока: ", save_data["player_data"])
		return true
	else:
		print("❌ Ошибка открытия файла для сохранения")
		return false


func quick_save(player: Node):
	save_data["last_save_type"] = "quick"
	var result = save_game(player)
	if result:
		print("⚡ Быстрое сохранение выполнено")
	return result

func campfire_save(player: Node, campfire_id: String = ""):
	save_data["last_save_type"] = "campfire"
	save_data["campfire_id"] = campfire_id
	
	if campfire_id != "":
		save_data["campfire_restore_points"][campfire_id] = {
			"enemies_killed": save_data["enemies_killed"].duplicate(),
			"items_collected": save_data["items_collected"].duplicate(),
			"player_position_x": player.global_position.x,
			"player_position_y": player.global_position.y,
			"timestamp": Time.get_unix_time_from_system()
		}
	
	var result = save_game(player)
	if result:
		print("🔥 Сохранение у костра выполнено")
	return result

func load_game():
	print("📂 Попытка загрузки сохранения")
	if not FileAccess.file_exists(SAVE_PATH):
		print("📂 Файл сохранения не найден")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		file.close()
		
		print("📂 Данные загружены из файла: ", loaded_data is Dictionary)
		
		if loaded_data is Dictionary:
			save_data = loaded_data
			print("📂 Сохранение загружено")
			print("📂 Ключи в загруженных данных: ", save_data.keys())
			print("🧀 СЫР В ЗАГРУЖЕННОМ СОХРАНЕНИИ: ", save_data["player_data"].get("cheese_bites", []))
			print("📂 Все данные игрока: ", save_data["player_data"])
			
			# Загружаем инвентарь
			if PlayerInventory and save_data.has("inventory_data"):
				PlayerInventory.load_inventory_data(save_data["inventory_data"])
				print("📂 Инвентарь загружен")
			
			return true
		else:
			print("❌ Ошибка: некорректные данные в файле сохранения")
			return false
	else:
		print("❌ Ошибка открытия файла для чтения")
		return false

# ВАЖНОЕ ИСПРАВЛЕНИЕ: Добавляем сохранение информации о слотах сыра
func update_player_data(p: Node):
	if not p:
		print("❌ update_player_data: player is null")
		return
	
	print("💾 update_player_data вызван для: ", p.name)
	
	# Используем безопасный доступ к свойствам
	var player_data = {}
	
	# Проверяем наличие свойств по-разному
	if "currency" in p:
		player_data["currency"] = p.currency
	else:
		player_data["currency"] = 0
	
	if "current_health" in p:
		player_data["health"] = p.current_health
	elif "max_health" in p:
		player_data["health"] = p.max_health
	else:
		player_data["health"] = 100.0
	
	if "max_health" in p:
		player_data["max_health"] = p.max_health
	else:
		player_data["max_health"] = 100.0
	
	if "attack_damage" in p:
		player_data["damage"] = p.attack_damage
	else:
		player_data["damage"] = 20
	
	# Позиция всегда доступна
	player_data["position_x"] = p.global_position.x
	player_data["position_y"] = p.global_position.y
	
	# ГАРАНТИРОВАННОЕ СОХРАНЕНИЕ СЫРА
	if p.has_method("get_cheese_data"):
		# Если у игрока есть метод для получения полных данных о сыре
		var cheese_data = p.get_cheese_data()
		player_data["cheese_bites"] = cheese_data.get("bites", [0, 0, 0])
		player_data["max_cheese_slots"] = cheese_data.get("max_slots", 3)
		player_data["salli_extra_slots"] = cheese_data.get("salli_slots", 0)
		print("💾 СЫР СОХРАНЕН через get_cheese_data(): ", player_data["cheese_bites"])
	elif "cheese_bites" in p:
		print("💾 Найден cheese_bites у игрока: ", p.cheese_bites)
		player_data["cheese_bites"] = p.cheese_bites.duplicate()
		
		# Сохраняем информацию о слотах
		if "base_max_cheese" in p:
			player_data["base_max_cheese"] = p.base_max_cheese
		if "salli_extra_cheese_slots" in p:
			player_data["salli_extra_slots"] = p.salli_extra_cheese_slots
		
		print("💾 СЫР СОХРАНЕН В update_player_data(): ", p.cheese_bites)
	else:
		print("💾 cheese_bites НЕ НАЙДЕН у игрока!")
		player_data["cheese_bites"] = [3, 3, 3]
		player_data["max_cheese_slots"] = 3
		player_data["salli_extra_slots"] = 0
	
	if "current_hit_count" in p:
		player_data["current_hit_count"] = p.current_hit_count
	else:
		player_data["current_hit_count"] = 0
	
	print("💾 Данные игрока перед сохранением: ", player_data.keys())
	save_data["player_data"] = player_data

func get_player_data() -> Dictionary:
	print("📂 get_player_data вызван")
	print("📂 Данные в save_data: ", save_data.get("player_data", {}))
	return save_data.get("player_data", {}).duplicate()

# НОВЫЙ МЕТОД: Получить данные о сыре с проверкой
func get_cheese_data() -> Dictionary:
	var player_data = get_player_data()
	return {
		"bites": player_data.get("cheese_bites", [0, 0, 0]),
		"max_slots": player_data.get("max_cheese_slots", 3),
		"salli_slots": player_data.get("salli_extra_slots", 0),
		"current_hit_count": player_data.get("current_hit_count", 0)
	}

func mark_enemy_killed(enemy_id: String):
	if not save_data.has("enemies_killed"):
		save_data["enemies_killed"] = {}
	save_data["enemies_killed"][enemy_id] = true

func is_enemy_killed(enemy_id: String) -> bool:
	return save_data.get("enemies_killed", {}).get(enemy_id, false)

func mark_item_collected(item_id: String):
	if not save_data.has("items_collected"):
		save_data["items_collected"] = {}
	save_data["items_collected"][item_id] = true

func is_item_collected(item_id: String) -> bool:
	return save_data.get("items_collected", {}).get(item_id, false)

func clear_killed_enemies():
	if save_data.has("enemies_killed"):
		save_data["enemies_killed"].clear()
		print("🧹 Убитые враги очищены")

func clear_collected_items():
	if save_data.has("items_collected"):
		save_data["items_collected"].clear()
		print("🧹 Собранные предметы очищены")

func restore_from_campfire(campfire_id: String = ""):
	print("🔥 Восстановление из костра: ", campfire_id)
	
	if campfire_id != "" and save_data["campfire_restore_points"].has(campfire_id):
		var restore_point = save_data["campfire_restore_points"][campfire_id]
		save_data["enemies_killed"] = restore_point["enemies_killed"].duplicate()
		save_data["items_collected"] = restore_point["items_collected"].duplicate()
		print("✅ Состояние восстановлено из точки костра: ", campfire_id)
	else:
		print("🧹 Очищаем всех врагов и предметы для полного респавна")
		clear_killed_enemies()
		clear_collected_items()

func get_equipped_talismans() -> Array:
	return save_data["talisman_data"].get("equipped_talismans", ["", "", ""]).duplicate()

func set_equipped_talismans(arr: Array):
	save_data["talisman_data"]["equipped_talismans"] = arr.duplicate()
	print("💾 Талисманы установлены: ", arr)

func set_npc_upgrade_level(npc_name: String, level: int):
	save_data["npc_data"][npc_name + "_upgrade_level"] = level
	print("💾 Уровень NPC сохранен: ", npc_name, " = ", level)

func get_npc_upgrade_level(npc_name: String) -> int:
	var key = npc_name + "_upgrade_level"
	var level = save_data["npc_data"].get(key, 0)
	print("📂 Уровень NPC загружен: ", npc_name, " = ", level)
	return level

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("🧹 Файл сохранения удален")
	
	# Сбрасываем данные на дефолтные
	save_data = {
		"player_data": {},
		"inventory_data": {},
		"talisman_data": {"equipped_talismans": ["", "", ""]},
		"npc_data": {},
		"scene_name": "",
		"last_save_type": "manual",
		"campfire_id": "",
		"enemies_killed": {},
		"items_collected": {},
		"campfire_restore_points": {}
	}
	
	print("🧹 Все данные сохранения очищены")

func get_saved_scene_path() -> String:
	return save_data.get("scene_name", "")

func get_last_save_type() -> String:
	return save_data.get("last_save_type", "manual")

func get_last_campfire_id() -> String:
	return save_data.get("campfire_id", "")

func _find_inventory():
	var root = get_tree().current_scene
	if root:
		for n in root.get_children():
			if n.has_method("get_equipped_talismans"):
				return n
	return null

func add_currency(amount: int):
	var current: int = save_data["player_data"].get("currency", 0)
	save_data["player_data"]["currency"] = current + amount
	print("💰 Валюта добавлена: +", amount, " = ", current + amount)

func get_trader_items() -> Array:
	return save_data.get("npc_items_trader", [])

func set_trader_items(items: Array):
	save_data["npc_items_trader"] = items.duplicate(true)

func get_purchased_items() -> Dictionary:
	return save_data.get("purchased_items", {})

func set_purchased_items(items: Dictionary):
	save_data["purchased_items"] = items.duplicate(true)

func save_tutorial_progress(tutorial_node):
	"""Сохраняет прогресс обучения из TutorialQuests"""
	if not tutorial_node or not tutorial_node.has_method("get_tutorial_state"):
		print("❌ TutorialQuests не найден или не имеет метода get_tutorial_state")
		return
	
	var tutorial_state = tutorial_node.get_tutorial_state()
	save_data["tutorial_data"] = tutorial_state
	print("💾 Прогресс обучения сохранен:", tutorial_state)

func load_tutorial_progress():
	"""Загружает прогресс обучения"""
	print("📂 Загружаем прогресс обучения:", save_data.get("tutorial_data", {}))
	return save_data.get("tutorial_data", {}).duplicate()

func get_tutorial_data() -> Dictionary:
	"""Получает данные обучения"""
	return save_data.get("tutorial_data", {
		"tutorial_completed": false,
		"need_tutorial": true,
		"tutorial_skipped": false,
		"quests_completed": {},
		"quests_progress": {}
	})

func set_tutorial_completed(value: bool):
	"""Устанавливает флаг завершения обучения"""
	save_data["tutorial_data"]["tutorial_completed"] = value
	print("💾 tutorial_completed установлен:", value)

func set_need_tutorial(value: bool):
	"""Устанавливает флаг необходимости обучения"""
	save_data["tutorial_data"]["need_tutorial"] = value
	print("💾 need_tutorial установлен:", value)

func set_tutorial_skipped(value: bool):
	"""Устанавливает флаг пропуска обучения"""
	save_data["tutorial_data"]["tutorial_skipped"] = value
	print("💾 tutorial_skipped установлен:", value)

func clear_save_for_new_game():
	"""Очищает только прогресс, но сохраняет сыр и валюту"""
	print("🧹 Очищаем сохранение для новой игры...")
	
	# Сохраняем важные данные игрока
	var old_player_data = save_data.get("player_data", {}).duplicate()
	var old_inventory = save_data.get("inventory_data", {}).duplicate()
	var old_talismans = save_data.get("talisman_data", {}).duplicate()
	var old_npc_data = save_data.get("npc_data", {}).duplicate()
	
	# Очищаем основные данные
	save_data = {
		"player_data": {},
		"inventory_data": {},
		"talisman_data": {"equipped_talismans": ["", "", ""]},
		"npc_data": {},
		"scene_name": "",
		"last_save_type": "manual",
		"campfire_id": "",
		"enemies_killed": {},
		"items_collected": {},
		"campfire_restore_points": {},
		# Сбрасываем обучение
		"tutorial_data": {
			"tutorial_completed": false,
			"need_tutorial": true,
			"tutorial_skipped": false,
			"quests_completed": {},
			"quests_progress": {}
		}
	}
	
	# Восстанавливаем сыр, валюту и т.д.
	if old_player_data.has("cheese_bites"):
		save_data["player_data"]["cheese_bites"] = old_player_data["cheese_bites"].duplicate()
	if old_player_data.has("currency"):
		save_data["player_data"]["currency"] = old_player_data["currency"]
	if old_player_data.has("current_hit_count"):
		save_data["player_data"]["current_hit_count"] = old_player_data["current_hit_count"]
	if old_player_data.has("max_cheese_slots"):
		save_data["player_data"]["max_cheese_slots"] = old_player_data["max_cheese_slots"]
	if old_player_data.has("salli_extra_slots"):
		save_data["player_data"]["salli_extra_slots"] = old_player_data["salli_extra_slots"]
	
	# Сохраняем талисманы
	save_data["talisman_data"] = old_talismans.duplicate()
	
	# Сохраняем инвентарь (только кристаллы и важные предметы)
	if old_inventory.has("crystals"):
		save_data["inventory_data"]["crystals"] = old_inventory["crystals"]
	
	# Сохраняем улучшения NPC (особенно Salli)
	save_data["npc_data"] = old_npc_data.duplicate()
	
	print("🧹 Сырь сохранен: ", save_data["player_data"].get("cheese_bites", []))
	print("🧹 Валюта сохранена: ", save_data["player_data"].get("currency", 0))
	print("🧹 Талисманы сохранены: ", save_data["talisman_data"]["equipped_talismans"])
	print("🧹 NPC данные сохранены: ", save_data["npc_data"])
