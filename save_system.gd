extends Node

const SAVE_PATH = "user://save_game.dat"

var save_data: Dictionary = {
	"player_data": {
		"currency": 0,
		"health": 100,
		"max_health": 100,
		"damage": 20,
		"position_x": 0,
		"position_y": 0
	},
	"npc_data": {},
	"inventory_data": {},
	"campfire_data": {},
	"game_time": 0,
	"scene_name": ""
}

func _ready():
	load_game()

func save_game(player_node = null, campfire_id = ""):
	print("=== СОХРАНЕНИЕ ИГРЫ ===")
	
	if player_node:
		update_player_data(player_node)
	
	if campfire_id != "":
		save_data["campfire_data"] = {
			"active_campfire": campfire_id,
			"last_save_time": Time.get_unix_time_from_system()
		}
	
	save_data["scene_name"] = get_tree().current_scene.scene_file_path
	save_data["game_time"] = save_data.get("game_time", 0) + 1
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Игра сохранена успешно!")
		return true
	else:
		print("Ошибка сохранения!")
		return false

func load_game():
	print("=== ЗАГРУЗКА СОХРАНЕНИЯ ===")
	
	if not FileAccess.file_exists(SAVE_PATH):
		print("Сохранение не найдено, создаем новое")
		save_game()
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		save_data = file.get_var()
		file.close()
		print("Сохранение загружено!")
		return true
	else:
		print("Ошибка загрузки сохранения!")
		return false

# === ИСПРАВЛЕННЫЙ МЕТОД: только данные игрока ===
func update_player_data(player_node):
	if not player_node:
		return
	
	save_data["player_data"] = {
		"currency": player_node.get_player_currency(),
		"health": player_node.current_health,
		"max_health": player_node.max_health,
		"damage": player_node.attack_damage,
		"position_x": player_node.global_position.x,
		"position_y": player_node.global_position.y
	}
	
	print("Данные игрока обновлены")

# === НОВЫЙ МЕТОД: Установить уровень NPC ===
func set_npc_upgrade_level(npc_name: String, level: int):
	if "npc_data" not in save_data:
		save_data["npc_data"] = {}
	
	save_data["npc_data"][npc_name + "_upgrade_level"] = level
	print("Установлен уровень NPC", npc_name, ":", level)

# === НОВЫЙ МЕТОД: Получить уровень NPC ===
func get_npc_upgrade_level(npc_name: String = "salli") -> int:
	return save_data.get("npc_data", {}).get(npc_name + "_upgrade_level", 0)

# === НОВЫЙ МЕТОД: Получить все данные NPC ===
func get_npc_data() -> Dictionary:
	return save_data.get("npc_data", {})

func get_player_data():
	return save_data.get("player_data", {})

func get_saved_currency():
	return save_data.get("player_data", {}).get("currency", 0)

func set_currency(amount: int):
	if "player_data" not in save_data:
		save_data["player_data"] = {}
	save_data["player_data"]["currency"] = amount

func add_currency(amount: int):
	var current = get_saved_currency()
	set_currency(current + amount)

func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Сохранение удалено")

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_saved_scene_path() -> String:
	return save_data.get("scene_name", "")

func set_saved_scene(scene_path: String):
	save_data["scene_name"] = scene_path

func clear_save():
	save_data = {
		"player_data": {
			"currency": 0,
			"health": 100,
			"max_health": 100,
			"damage": 20,
			"position_x": 0,
			"position_y": 0
		},
		"npc_data": {},
		"inventory_data": {},
		"campfire_data": {},
		"game_time": 0,
		"scene_name": "res://scenes/world/labaratory/lab_scene.tscn"
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Сохранение очищено для новой игры")

func get_all_data():
	return save_data
