extends Control

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var confirm_popup: ConfirmationDialog = $ConfirmPopup

@onready var dark_overlay: ColorRect

var settings_popup: Window
var brightness_slider: HSlider
var volume_slider: HSlider
var brightness_percent_label: Label
var volume_percent_label: Label

var current_brightness: float = 1.0
var current_volume: float = 0.8

# Добавляем переменную для хранения диалога новой игры
var new_game_dialog: ConfirmationDialog = null

func _ready():
	print("=== ИНИЦИАЛИЗАЦИЯ МЕНЮ ===")
	
	_create_dark_overlay()
	_load_settings()
	_check_save_file()
	_setup_confirm_popup()
	_init_settings_popup()
	
	_apply_brightness(current_brightness)
	_apply_volume(current_volume)
	
	print("✅ Меню готово")

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
	else:
		_save_settings()

func _save_settings():
	var config = ConfigFile.new()
	config.set_value("Settings", "brightness", current_brightness)
	config.set_value("Settings", "volume", current_volume)
	config.save("user://game_settings.cfg")

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
	brightness_container.name = "BrightnessContainer"
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
	brightness_percent_label.name = "BrightnessPercent"
	brightness_percent_label.text = str(int(current_brightness * 100)) + "%"
	brightness_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brightness_percent_label.add_theme_font_size_override("font_size", 16)
	brightness_container.add_child(brightness_percent_label)
	
	main_container.add_child(brightness_container)
	
	var separator1 = HSeparator.new()
	separator1.add_theme_constant_override("separation", 20)
	main_container.add_child(separator1)
	
	var volume_container = VBoxContainer.new()
	volume_container.name = "VolumeContainer"
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
	volume_percent_label.name = "VolumePercent"
	volume_percent_label.text = str(int(current_volume * 100)) + "%"
	volume_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_percent_label.add_theme_font_size_override("font_size", 16)
	volume_container.add_child(volume_percent_label)
	
	main_container.add_child(volume_container)
	
	var separator2 = HSeparator.new()
	separator2.add_theme_constant_override("separation", 20)
	main_container.add_child(separator2)
	
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
	var window_size = window.size
	window.position = (screen_size - window_size) / 2

func _on_brightness_changed(value: float):
	current_brightness = value / 100.0
	
	if brightness_percent_label:
		brightness_percent_label.text = str(int(value)) + "%"
	
	_apply_brightness(current_brightness)

func _on_volume_changed(value: float):
	current_volume = value / 100.0
	
	if volume_percent_label:
		volume_percent_label.text = str(int(value)) + "%"
	
	_apply_volume(current_volume)

func _on_apply_settings():
	_save_settings()
	settings_popup.visible = false

func _on_close_settings():
	settings_popup.visible = false

# ИСПРАВЛЕННЫЙ МЕТОД ДЛЯ НОВОЙ ИГРЫ
func _on_new_game_button_pressed():
	print("🎮 НОВАЯ ИГРА")
	
	# Проверяем, есть ли уже открытый диалог
	if new_game_dialog != null and is_instance_valid(new_game_dialog):
		new_game_dialog.queue_free()
		new_game_dialog = null
	
	if save_system and save_system.has_save():
		# Создаем диалог подтверждения
		new_game_dialog = ConfirmationDialog.new()
		new_game_dialog.name = "NewGameConfirm"
		new_game_dialog.title = "НОВАЯ ИГРА"
		new_game_dialog.dialog_text = "Текущее сохранение будет удалено. Продолжить?"
		new_game_dialog.get_ok_button().text = "ДА"
		new_game_dialog.get_cancel_button().text = "НЕТ"
		
		new_game_dialog.confirmed.connect(func():
			print("Начинаем новую игру...")
			
			# Сбрасываем сохранение
			save_system.clear_save()
			
			# Сбрасываем инвентарь
			if PlayerInventory:
				PlayerInventory.reset_for_new_game()
			
			# Удаляем диалог
			if new_game_dialog != null:
				new_game_dialog.queue_free()
				new_game_dialog = null
			
			# Загружаем сцену
			get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")
		)
		
		new_game_dialog.canceled.connect(func():
			print("Отмена новой игры")
			if new_game_dialog != null:
				new_game_dialog.queue_free()
				new_game_dialog = null
		)
		
		# Закрываем все другие окна перед открытием нового
		settings_popup.visible = false
		confirm_popup.hide()
		
		add_child(new_game_dialog)
		new_game_dialog.popup_centered()
	else:
		# Нет сохранения, сразу начинаем новую игру
		print("Сохранение не найдено, начинаем новую игру...")
		
		# Сбрасываем инвентарь
		if PlayerInventory:
			PlayerInventory.reset_for_new_game()
		
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_continue_game_button_pressed():
	print("🎮 ПРОДОЛЖИТЬ")
	
	# Закрываем все открытые диалоги
	close_all_dialogs()
	
	if save_system and save_system.has_save():
		var scene = save_system.get_saved_scene_path()
		if scene and ResourceLoader.exists(scene):
			get_tree().change_scene_to_file(scene)
		else:
			get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_settings_button_pressed():
	print("⚙️ НАСТРОЙКИ")
	
	# Закрываем все открытые диалоги
	close_all_dialogs()
	
	if settings_popup:
		brightness_slider.value = current_brightness * 100
		volume_slider.value = current_volume * 100
		
		if brightness_percent_label:
			brightness_percent_label.text = str(int(current_brightness * 100)) + "%"
		if volume_percent_label:
			volume_percent_label.text = str(int(current_volume * 100)) + "%"
		
		settings_popup.visible = true
		settings_popup.grab_focus()

func _on_quit_button_pressed():
	print("🚪 ВЫХОД")
	
	# Закрываем все открытые диалоги
	close_all_dialogs()
	
	if confirm_popup:
		confirm_popup.popup_centered()

func close_all_dialogs():
	# Закрываем диалог новой игры
	if new_game_dialog != null and is_instance_valid(new_game_dialog):
		new_game_dialog.queue_free()
		new_game_dialog = null
	
	# Закрываем окно настроек
	if settings_popup:
		settings_popup.visible = false
	
	# Скрываем попап выхода
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
		confirm_popup.canceled.connect(func():
			print("Выход отменен")
		)
		confirm_popup.hide()

func _check_save_file():
	if save_system:
		continue_button.disabled = not save_system.has_save()
