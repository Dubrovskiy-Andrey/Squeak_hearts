# save_system.gd
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
	"inventory_data": {},
	"campfire_data": {},
	"game_time": 0,
	"scene_name": ""
}

# Загрузить сохранение при старте игры
func _ready():
	load_game()

# Сохранить игру
func save_game(player_node = null, campfire_id = ""):
	print("=== СОХРАНЕНИЕ ИГРЫ ===")
	
	# Обновляем данные игрока
	if player_node:
		update_player_data(player_node)
	
	# Обновляем данные костра
	if campfire_id != "":
		save_data["campfire_data"] = {
			"active_campfire": campfire_id,
			"last_save_time": Time.get_unix_time_from_system()
		}
	
	# Сохраняем текущую сцену
	save_data["scene_name"] = get_tree().current_scene.scene_file_path
	
	# Сохраняем время игры
	save_data["game_time"] = save_data.get("game_time", 0) + 1  # Просто для примера
	
	# Сохраняем в файл
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Игра сохранена успешно!")
		print("Данные:", save_data)
		return true
	else:
		print("Ошибка сохранения!")
		return false

# Загрузить игру
func load_game():
	print("=== ЗАГРУЗКА СОХРАНЕНИЯ ===")
	
	if not FileAccess.file_exists(SAVE_PATH):
		print("Сохранение не найдено, создаем новое")
		save_game()  # Создаем пустое сохранение
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		save_data = file.get_var()
		file.close()
		print("Сохранение загружено!")
		print("Данные:", save_data)
		return true
	else:
		print("Ошибка загрузки сохранения!")
		return false

# Обновить данные игрока
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

# Получить сохраненные данные игрока
func get_player_data():
	return save_data.get("player_data", {})

# Получить сохраненную валюту
func get_saved_currency():
	return save_data.get("player_data", {}).get("currency", 0)

# Установить валюту
func set_currency(amount: int):
	if "player_data" not in save_data:
		save_data["player_data"] = {}
	save_data["player_data"]["currency"] = amount

# Добавить валюту
func add_currency(amount: int):
	var current = get_saved_currency()
	set_currency(current + amount)

# Удалить файл сохранения
func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Сохранение удалено")

# Проверить есть ли сохранение
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# === ДОБАВЛЕННЫЕ МЕТОДЫ ===

# Получить путь к сохраненной сцене
func get_saved_scene_path() -> String:
	return save_data.get("scene_name", "")

# Установить сцену для сохранения
func set_saved_scene(scene_path: String):
	save_data["scene_name"] = scene_path

# Полная очистка сохранения (для новой игры)
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
		"inventory_data": {},
		"campfire_data": {},
		"game_time": 0,
		"scene_name": "res://scenes/world/labaratory/lab_scene.tscn"  # Стартовая сцена
	}
	
	# Сохраняем очищенные данные
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Сохранение очищено для новой игры")

# Получить все данные сохранения (для отладки)
func get_all_data():
	return save_data
