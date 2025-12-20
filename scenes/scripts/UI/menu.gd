extends Control

# Ноды UI
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var confirm_popup: ConfirmationDialog = $ConfirmPopup
@onready var dark_overlay: ColorRect

# Сложность
@onready var difficulty_container: HBoxContainer = $VBoxContainer/DifficultyContainer
@onready var kitten_button: Button = $VBoxContainer/DifficultyContainer/KittenButton
@onready var cat_button: Button = $VBoxContainer/DifficultyContainer/CatButton
@onready var scary_button: Button = $VBoxContainer/DifficultyContainer/ScaryButton

# Настройки
var settings_popup: Window
var brightness_slider: HSlider
var volume_slider: HSlider
var brightness_percent_label: Label
var volume_percent_label: Label

var current_brightness: float = 1.0
var current_volume: float = 0.8
var new_game_dialog: ConfirmationDialog = null

@onready var save_system: Node = get_node("/root/save_system")
@onready var game_manager: Node = get_node("/root/game_manager")

# Словарь для кнопок сложности
var difficulty_buttons: Dictionary = {}

func _ready():
	print("ИНИЦИАЛИЗАЦИЯ МЕНЮ")
	_create_dark_overlay()
	_load_settings()
	_check_save_file()
	_setup_confirm_popup()
	_init_settings_popup()
	_apply_brightness(current_brightness)
	_apply_volume(current_volume)
	_init_difficulty_buttons()
	print("Меню готово")

func _create_dark_overlay():
	dark_overlay = get_node_or_null("DarkOverlay")
	if not dark_overlay:
		dark_overlay = ColorRect.new()
		dark_overlay.name = "DarkOverlay"
		dark_overlay.color = Color.BLACK
		dark_overlay.modulate.a = 0.0
		dark_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dark_overlay)
		move_child(dark_overlay, get_child_count() - 1)

func _init_difficulty_buttons():
	# Инициализируем словарь кнопок сложности
	difficulty_buttons = {
		"kitten": kitten_button,
		"cat": cat_button,
		"scary": scary_button
	}
	
	# Подключаем сигналы
	if kitten_button:
		kitten_button.pressed.connect(_on_difficulty_button_pressed.bind("kitten"))
	if cat_button:
		cat_button.pressed.connect(_on_difficulty_button_pressed.bind("cat"))
	if scary_button:
		scary_button.pressed.connect(_on_difficulty_button_pressed.bind("scary"))
	
	# Устанавливаем визуальное состояние по умолчанию
	_update_difficulty_visuals()

func _update_difficulty_visuals():
	# Обновляем внешний вид кнопок в зависимости от выбранной сложности
	if not game_manager:
		print("⚠️ GameManager не найден!")
		return
	
	var current_diff = game_manager.current_difficulty
	
	for diff_name in difficulty_buttons:
		var button = difficulty_buttons[diff_name]
		if button:
			# Определяем, активна ли эта кнопка
			var is_active = false
			match diff_name:
				"kitten": is_active = (current_diff == game_manager.Difficulty.KITTEN)
				"cat": is_active = (current_diff == game_manager.Difficulty.CAT)
				"scary": is_active = (current_diff == game_manager.Difficulty.SCARY)
			
			# Обновляем визуал
			if is_active:
				button.modulate = Color(1, 1, 1, 1.0)
				button.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
				print("Кнопка", diff_name, "активна")
			else:
				button.modulate = Color(1, 1, 1, 0.6)
				button.add_theme_color_override("font_color", Color(1, 1, 1))
				print("Кнопка", diff_name, "неактивна")

func _on_difficulty_button_pressed(diff_name: String):
	if not game_manager:
		print("❌ GameManager не найден!")
		return
	
	print("🎮 Выбрана сложность:", diff_name)
	
	# Устанавливаем сложность
	match diff_name:
		"kitten":
			game_manager.set_difficulty(game_manager.Difficulty.KITTEN)
		"cat":
			game_manager.set_difficulty(game_manager.Difficulty.CAT)
		"scary":
			game_manager.set_difficulty(game_manager.Difficulty.SCARY)
	
	# Обновляем визуал кнопок
	_update_difficulty_visuals()
	
	# Сохраняем настройки сложности
	_save_settings()

func _apply_brightness(brightness_percent: float):
	var brightness = clamp(brightness_percent, 0.5, 1.5)
	var alpha: float
	if brightness <= 1.0:
		alpha = (1.0 - brightness) * 0.5
		dark_overlay.color = Color.BLACK
	else:
		alpha = -(brightness - 1.0) * 0.3
		dark_overlay.color = Color.WHITE
	dark_overlay.modulate.a = abs(alpha)

func _apply_volume(volume_percent: float):
	var volume = clamp(volume_percent, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	AudioServer.set_bus_mute(0, volume == 0)

func _load_settings():
	var config = ConfigFile.new()
	if config.load("user://game_settings.cfg") == OK:
		current_brightness = config.get_value("Settings", "brightness", 1.0)
		current_volume = config.get_value("Settings", "volume", 0.8)
		
		# Загружаем сложность
		var saved_difficulty = config.get_value("Settings", "difficulty", "kitten")
		if game_manager:
			match saved_difficulty:
				"kitten": game_manager.set_difficulty(game_manager.Difficulty.KITTEN)
				"cat": game_manager.set_difficulty(game_manager.Difficulty.CAT)
				"scary": game_manager.set_difficulty(game_manager.Difficulty.SCARY)
		
		print("Загружены настройки. Сложность:", saved_difficulty)
	else:
		_save_settings()

func _save_settings():
	var config = ConfigFile.new()
	config.set_value("Settings", "brightness", current_brightness)
	config.set_value("Settings", "volume", current_volume)
	
	# Сохраняем сложность
	if game_manager:
		var diff_to_save = "kitten"
		match game_manager.current_difficulty:
			game_manager.Difficulty.KITTEN: diff_to_save = "kitten"
			game_manager.Difficulty.CAT: diff_to_save = "cat"
			game_manager.Difficulty.SCARY: diff_to_save = "scary"
		config.set_value("Settings", "difficulty", diff_to_save)
		print("Сложность сохранена:", diff_to_save)
	
	config.save("user://game_settings.cfg")

func _check_save_file():
	if save_system:
		continue_button.disabled = not save_system.has_save()

func _on_new_game_button_pressed():
	if new_game_dialog != null and is_instance_valid(new_game_dialog):
		new_game_dialog.queue_free()
		new_game_dialog = null
	
	if save_system and save_system.has_save():
		new_game_dialog = ConfirmationDialog.new()
		new_game_dialog.title = "НОВАЯ ИГРА"
		new_game_dialog.dialog_text = "Текущее сохранение будет удалено. Продолжить?"
		new_game_dialog.get_ok_button().text = "ДА"
		new_game_dialog.get_cancel_button().text = "НЕТ"
		new_game_dialog.confirmed.connect(func():
			print("🧹 Очищаем сохранение для новой игры")
			save_system.clear_save()
			if PlayerInventory:
				PlayerInventory.reset_for_new_game()
			
			# Сбрасываем сложность на стандартную
			if game_manager:
				game_manager.set_difficulty(game_manager.Difficulty.KITTEN)
				_update_difficulty_visuals()
			
			get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")
		)
		add_child(new_game_dialog)
		new_game_dialog.popup_centered()
	else:
		print("🎮 Начинаем новую игру без сохранения")
		if PlayerInventory:
			PlayerInventory.reset_for_new_game()
		
		# Убеждаемся, что сложность установлена
		if game_manager:
			game_manager.set_difficulty(game_manager.Difficulty.KITTEN)
			_update_difficulty_visuals()
		
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_continue_game_button_pressed():
	if save_system and save_system.has_save():
		print("📂 Меню: Загружаем сохранение перед переходом в сцену")
		save_system.load_game()  # ЗАГРУЖАЕМ СОХРАНЕНИЕ ЗДЕСЬ
		var scene = save_system.get_saved_scene_path()
		if scene != "" and ResourceLoader.exists(scene):
			get_tree().change_scene_to_file(scene)
		else:
			get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")
	else:
		print("⚠️ Сохранение не найдено, начинаем новую игру")
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_settings_button_pressed():
	if settings_popup:
		brightness_slider.value = current_brightness * 100
		volume_slider.value = current_volume * 100
		brightness_percent_label.text = str(int(current_brightness * 100)) + "%"
		volume_percent_label.text = str(int(current_volume * 100)) + "%"
		settings_popup.visible = true
		settings_popup.grab_focus()

func _on_quit_button_pressed():
	confirm_popup.popup_centered()

func close_all_dialogs():
	if new_game_dialog != null and is_instance_valid(new_game_dialog):
		new_game_dialog.queue_free()
		new_game_dialog = null
	if settings_popup:
		settings_popup.visible = false
	confirm_popup.hide()

func _setup_confirm_popup():
	if confirm_popup:
		confirm_popup.title = "ВЫХОД"
		confirm_popup.dialog_text = "Вы уверены, что хотите выйти?"
		confirm_popup.get_ok_button().text = "ДА"
		confirm_popup.get_cancel_button().text = "НЕТ"
		confirm_popup.confirmed.connect(func():
			_save_settings()
			await get_tree().create_timer(0.3).timeout
			get_tree().quit()
		)
		confirm_popup.canceled.connect(func(): pass)
		confirm_popup.hide()

# Остальной код инициализации окна настроек остаётся без изменений
func _init_settings_popup():
	settings_popup = Window.new()
	settings_popup.name = "SettingsPopup"
	settings_popup.title = "НАСТРОЙКИ"
	settings_popup.size = Vector2(450, 350)
	settings_popup.unresizable = true
	settings_popup.visible = false
	settings_popup.close_requested.connect(_on_close_settings)

	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 30)
	main_container.add_theme_constant_override("separation", 20)

	var brightness_container = VBoxContainer.new()
	brightness_container.add_theme_constant_override("separation", 10)
	var brightness_title = Label.new()
	brightness_title.text = "ЯРКОСТЬ ЭКРАНА"
	brightness_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brightness_title.add_theme_font_size_override("font_size", 18)
	brightness_container.add_child(brightness_title)

	var brightness_hbox = HBoxContainer.new()
	brightness_hbox.add_spacer(false)
	var dark_label = Label.new()
	dark_label.text = "ТЕМНО"
	brightness_hbox.add_child(dark_label)

	brightness_slider = HSlider.new()
	brightness_slider.min_value = 50
	brightness_slider.max_value = 150
	brightness_slider.value = current_brightness * 100
	brightness_slider.custom_minimum_size = Vector2(250, 25)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	brightness_hbox.add_child(brightness_slider)

	var bright_label = Label.new()
	bright_label.text = "ЯРКО"
	brightness_hbox.add_child(bright_label)
	brightness_hbox.add_spacer(false)
	brightness_container.add_child(brightness_hbox)

	brightness_percent_label = Label.new()
	brightness_percent_label.text = str(int(current_brightness * 100)) + "%"
	brightness_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brightness_container.add_child(brightness_percent_label)
	main_container.add_child(brightness_container)

	var volume_container = VBoxContainer.new()
	volume_container.add_theme_constant_override("separation", 10)
	var volume_title = Label.new()
	volume_title.text = "ГРОМКОСТЬ ЗВУКА"
	volume_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_title.add_theme_font_size_override("font_size", 18)
	volume_container.add_child(volume_title)

	var volume_hbox = HBoxContainer.new()
	volume_hbox.add_spacer(false)
	var quiet_label = Label.new()
	quiet_label.text = "ТИХО"
	volume_hbox.add_child(quiet_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = current_volume * 100
	volume_slider.custom_minimum_size = Vector2(250, 25)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_hbox.add_child(volume_slider)

	var loud_label = Label.new()
	loud_label.text = "ГРОМКО"
	volume_hbox.add_child(loud_label)
	volume_hbox.add_spacer(false)
	volume_container.add_child(volume_hbox)

	volume_percent_label = Label.new()
	volume_percent_label.text = str(int(current_volume * 100)) + "%"
	volume_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_container.add_child(volume_percent_label)
	main_container.add_child(volume_container)

	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_spacer(false)
	var apply_button = Button.new()
	apply_button.text = "ПРИМЕНИТЬ"
	apply_button.custom_minimum_size = Vector2(120, 35)
	apply_button.pressed.connect(_on_apply_settings)
	buttons_hbox.add_child(apply_button)

	var close_button = Button.new()
	close_button.text = "ЗАКРЫТЬ"
	close_button.custom_minimum_size = Vector2(120, 35)
	close_button.pressed.connect(_on_close_settings)
	buttons_hbox.add_child(close_button)
	buttons_hbox.add_spacer(false)

	main_container.add_child(buttons_hbox)
	settings_popup.add_child(main_container)
	add_child(settings_popup)
	_center_window(settings_popup)

func _center_window(window: Window):
	var screen_size = DisplayServer.window_get_size()
	window.position = (screen_size - window.size) / 2

func _on_brightness_changed(value: float):
	current_brightness = value / 100.0
	brightness_percent_label.text = str(int(value)) + "%"
	_apply_brightness(current_brightness)

func _on_volume_changed(value: float):
	current_volume = value / 100.0
	volume_percent_label.text = str(int(value)) + "%"
	_apply_volume(current_volume)

func _on_apply_settings():
	_save_settings()
	settings_popup.visible = false

func _on_close_settings():
	settings_popup.visible = false
