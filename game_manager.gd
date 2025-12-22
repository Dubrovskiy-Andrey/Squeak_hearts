# game_manager.gd
extends Node

enum Difficulty { KITTEN, CAT, SCARY }

var current_difficulty: Difficulty = Difficulty.KITTEN
var wave_number: int = 0
var enemies_alive: int = 0
var game_time: float = 0.0
var is_game_active: bool = false

# Настройки сложности
# game_manager.gd - ДОБАВИТЬ В difficulty_settings:
var difficulty_settings = {
	Difficulty.KITTEN: {
		"enemy_hp_multiplier": 0.8,
		"enemy_damage_multiplier": 0.7,
		"spawn_rate_multiplier": 0.8,
		"reward_multiplier": 1.0,
		"max_waves": 8,  # ← ДОБАВЛЕНО
		"index": 0,
		"name": "Котенок"
	},
	Difficulty.CAT: {
		"enemy_hp_multiplier": 1.0,
		"enemy_damage_multiplier": 1.0,
		"spawn_rate_multiplier": 1.0,
		"reward_multiplier": 1.2,
		"max_waves": 10,  # ← ДОБАВЛЕНО
		"index": 1,
		"name": "Кот"
	},
	Difficulty.SCARY: {
		"enemy_hp_multiplier": 1.5,
		"enemy_damage_multiplier": 1.3,
		"spawn_rate_multiplier": 1.5,
		"reward_multiplier": 1.5,
		"max_waves": 12,  # ← ДОБАВЛЕНО
		"index": 2,
		"name": "Страшный"
	}
}

signal wave_started(wave_number)
signal wave_completed(wave_number)
signal game_over(survival_time, waves_survived)
signal difficulty_changed(difficulty)

func _ready():
	print("GameManager готов")
	_load_difficulty()

func set_difficulty(diff: Difficulty) -> void:
	current_difficulty = diff
	difficulty_changed.emit(diff)
	_save_difficulty()
	print("Установлена сложность: ", difficulty_settings[diff]["name"])

func get_difficulty_multiplier(setting: String) -> float:
	return difficulty_settings[current_difficulty].get(setting, 1.0)

func get_difficulty_name() -> String:
	return difficulty_settings[current_difficulty]["name"]

func get_difficulty_index() -> int:
	return difficulty_settings[current_difficulty]["index"]

func _save_difficulty():
	var save_sys = get_node_or_null("/root/save_system")
	if save_sys:
		var player_data = save_sys.get_player_data()
		player_data["difficulty"] = current_difficulty
		save_sys.save_data["player_data"] = player_data
		print("💾 Сложность сохранена: ", current_difficulty)

func _load_difficulty():
	var save_sys = get_node_or_null("/root/save_system")
	if save_sys:
		var player_data = save_sys.get_player_data()
		if player_data.has("difficulty"):
			current_difficulty = player_data["difficulty"]
			print("📂 Сложность загружена: ", difficulty_settings[current_difficulty]["name"])
		else:
			# Устанавливаем по умолчанию "Кот"
			current_difficulty = Difficulty.CAT
			print("📂 Сложность не найдена, установлена по умолчанию: Кот")

func start_game():
	wave_number = 0
	game_time = 0.0
	is_game_active = true
	
	# Восстанавливаем ресурсы игроку при старте игры
	var player = get_tree().get_first_node_in_group("players")
	if player:
		# Восстанавливаем сыр
		if player.has_method("restore_all_cheese_to_full"):
			player.restore_all_cheese_to_full()
			print("🧀 Сыр восстановлен при старте игры")
		
		# Восстанавливаем здоровье
		if player.has_method("heal_to_full"):
			player.heal_to_full()
			print("❤️ Здоровье восстановлено при старте игры")
	
	print("Игра началась! Сложность: ", difficulty_settings[current_difficulty]["name"])

func end_game():
	is_game_active = false
	var survival_time = game_time
	var waves = wave_number
	game_over.emit(survival_time, waves)
	print("Игра окончена. Выжили: ", survival_time, " сек, волн: ", waves)

func _process(delta):
	if is_game_active:
		game_time += delta
