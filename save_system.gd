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
	"tutorial_data": {
		"tutorial_completed": false,
		"need_tutorial": true,
		"tutorial_skipped": false,
		"quests_completed": {}, 
		"quests_progress": {} 
	}
}

func _ready():
	print("save_system готов")

func save_game(player: Node = null):
	
	if player:
		update_player_data(player)
	if PlayerInventory:
		save_data["inventory_data"] = PlayerInventory.save_inventory_data()
	if get_tree().current_scene:
		save_data["scene_name"] = get_tree().current_scene.scene_file_path
	var inv = _find_inventory()
	if inv:
		var arr := ["", "", ""]
		var equipped = inv.get_equipped_talismans()
		for i in range(min(3, equipped.size())):
			if equipped[i]:
				arr[i] = equipped[i]["name"]
		save_data["talisman_data"]["equipped_talismans"] = arr
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		return true
	else:
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
	if not FileAccess.file_exists(SAVE_PATH):
		print("📂 Файл сохранения не найден")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		file.close()
		
		if loaded_data is Dictionary:
			save_data = loaded_data
			
			if PlayerInventory and save_data.has("inventory_data"):
				PlayerInventory.load_inventory_data(save_data["inventory_data"])
			
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
	var player_data = {}
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
	player_data["position_x"] = p.global_position.x
	player_data["position_y"] = p.global_position.y
	if p.has_method("get_cheese_data"):
		var cheese_data = p.get_cheese_data()
		player_data["cheese_bites"] = cheese_data.get("bites", [0, 0, 0])
		player_data["max_cheese_slots"] = cheese_data.get("max_slots", 3)
		player_data["salli_extra_slots"] = cheese_data.get("salli_slots", 0)
	elif "cheese_bites" in p:
		player_data["cheese_bites"] = p.cheese_bites.duplicate()
		if "base_max_cheese" in p:
			player_data["base_max_cheese"] = p.base_max_cheese
		if "salli_extra_cheese_slots" in p:
			player_data["salli_extra_slots"] = p.salli_extra_cheese_slots
	else:
		player_data["cheese_bites"] = [3, 3, 3]
		player_data["max_cheese_slots"] = 3
		player_data["salli_extra_slots"] = 0
	
	if "current_hit_count" in p:
		player_data["current_hit_count"] = p.current_hit_count
	else:
		player_data["current_hit_count"] = 0
	save_data["player_data"] = player_data

func get_player_data() -> Dictionary:
	return save_data.get("player_data", {}).duplicate()
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

func clear_collected_items():
	if save_data.has("items_collected"):
		save_data["items_collected"].clear()

func restore_from_campfire(campfire_id: String = ""):
	if campfire_id != "" and save_data["campfire_restore_points"].has(campfire_id):
		var restore_point = save_data["campfire_restore_points"][campfire_id]
		save_data["enemies_killed"] = restore_point["enemies_killed"].duplicate()
		save_data["items_collected"] = restore_point["items_collected"].duplicate()
	else:
		clear_killed_enemies()
		clear_collected_items()

func get_equipped_talismans() -> Array:
	return save_data["talisman_data"].get("equipped_talismans", ["", "", ""]).duplicate()

func set_equipped_talismans(arr: Array):
	save_data["talisman_data"]["equipped_talismans"] = arr.duplicate()

func set_npc_upgrade_level(npc_name: String, level: int):
	save_data["npc_data"][npc_name + "_upgrade_level"] = level

func get_npc_upgrade_level(npc_name: String) -> int:
	var key = npc_name + "_upgrade_level"
	var level = save_data["npc_data"].get(key, 0)
	return level

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
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
		return
	
	var tutorial_state = tutorial_node.get_tutorial_state()
	save_data["tutorial_data"] = tutorial_state

func load_tutorial_progress():
	"""Загружает прогресс обучения"""
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

func set_need_tutorial(value: bool):
	"""Устанавливает флаг необходимости обучения"""
	save_data["tutorial_data"]["need_tutorial"] = value

func set_tutorial_skipped(value: bool):
	"""Устанавливает флаг пропуска обучения"""
	save_data["tutorial_data"]["tutorial_skipped"] = value

func clear_save_for_new_game():
	"""Очищает только прогресс, но сохраняет сыр и валюту"""
	var old_player_data = save_data.get("player_data", {}).duplicate()
	var old_inventory = save_data.get("inventory_data", {}).duplicate()
	var old_talismans = save_data.get("talisman_data", {}).duplicate()
	var old_npc_data = save_data.get("npc_data", {}).duplicate()
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
		"tutorial_data": {
			"tutorial_completed": false,
			"need_tutorial": true,
			"tutorial_skipped": false,
			"quests_completed": {},
			"quests_progress": {}
		}
	}
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
	save_data["talisman_data"] = old_talismans.duplicate()
	if old_inventory.has("crystals"):
		save_data["inventory_data"]["crystals"] = old_inventory["crystals"]
	save_data["npc_data"] = old_npc_data.duplicate()
