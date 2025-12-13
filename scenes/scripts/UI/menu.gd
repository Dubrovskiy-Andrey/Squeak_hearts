extends Control  # Или Node2D

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button =$VBoxContainer/ContinueGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready():
	# Проверяем наличие сохранения
	_check_save_file()

func _check_save_file():
	if save_system:
		if save_system.has_save():
			continue_button.disabled = false
			continue_button.text = "Продолжить"
		else:
			continue_button.disabled = true
			continue_button.text = "Нет сохранения"
	else:
		continue_button.disabled = true
		continue_button.text = "Система сохранения недоступна"

func _on_new_game_button_pressed():
	print("=== НОВАЯ ИГРА ===")
	
	if save_system:
		# Очищаем сохранение
		save_system.clear_save()
		print("Сохранение очищено")
	
	# Загружаем стартовую сцену
	get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_continue_game_button_pressed():
	print("=== ПРОДОЛЖИТЬ ИГРУ ===")
	
	if not save_system:
		print("Ошибка: SaveSystem не найден!")
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")
		return
	
	if not save_system.has_save():
		print("Ошибка: сохранение не найдено!")
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")
		return
	
	# Загружаем сохраненную сцену
	var scene_path = save_system.get_saved_scene_path()
	if scene_path and ResourceLoader.exists(scene_path):
		print("Загружаем сохраненную сцену: ", scene_path)
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Сохраненной сцены нет, загружаем стандартную")
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_settings_button_pressed():
	print("Настройки (в разработке)")

func _on_quit_button_pressed():
	get_tree().quit()
