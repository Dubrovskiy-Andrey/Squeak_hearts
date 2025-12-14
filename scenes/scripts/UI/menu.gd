extends Control

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var confirm_popup: ConfirmationDialog = $ConfirmPopup

# Для затемнения экрана
@onready var dark_overlay: ColorRect

# Для настроек
var settings_popup: Window
var brightness_slider: HSlider
var volume_slider: HSlider
var brightness_percent_label: Label
var volume_percent_label: Label

# Текущие настройки
var current_brightness: float = 1.0  # 100%
var current_volume: float = 0.8      # 80%

func _ready():
	print("=== ИНИЦИАЛИЗАЦИЯ МЕНЮ ===")
	
	# Создаем затемняющий слой если его нет
	_create_dark_overlay()
	
	# Загружаем сохраненные настройки
	_load_settings()
	
	# Проверяем сохранение игры
	_check_save_file()
	
	# Настраиваем попап выхода
	_setup_confirm_popup()
	
	# Создаем окно настроек
	_init_settings_popup()
	
	# Применяем настройки
	_apply_brightness(current_brightness)
	_apply_volume(current_volume)
	
	print("✅ Меню готово")

# ==================== СОЗДАЕМ ТЕМНЫЙ СЛОЙ ====================

func _create_dark_overlay():
	# Ищем существующий
	dark_overlay = get_node_or_null("DarkOverlay")
	
	if not dark_overlay:
		# Создаем новый слой затемнения
		dark_overlay = ColorRect.new()
		dark_overlay.name = "DarkOverlay"
		dark_overlay.color = Color.BLACK
		dark_overlay.modulate.a = 0.0  # Прозрачный по умолчанию
		
		# Растягиваем на весь экран
		dark_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Добавляем ПОВЕРХ всего (самый верхний слой)
		add_child(dark_overlay)
		move_child(dark_overlay, get_child_count() - 1)  # Перемещаем наверх
		
		print("✅ Слой затемнения создан")

# ==================== НАСТРОЙКИ ЯРКОСТИ ====================

func _apply_brightness(brightness_percent: float):
	# brightness_percent от 0.5 до 1.5 (50% до 150%)
	var brightness = clamp(brightness_percent, 0.5, 1.5)
	
	# Рассчитываем затемнение:
	# 50% → очень темно (альфа = 0.5)
	# 100% → нормально (альфа = 0.0)
	# 150% → очень ярко (альфа = -0.3, делаем белый оверлей)
	
	var alpha: float
	
	if brightness <= 1.0:
		# Затемнение (от 0.0 до 0.5 альфы)
		alpha = (1.0 - brightness) * 0.5
		dark_overlay.color = Color.BLACK
	else:
		# Осветление (отрицательная альфа - белый оверлей)
		alpha = -(brightness - 1.0) * 0.3
		dark_overlay.color = Color.WHITE
	
	# Применяем прозрачность
	dark_overlay.modulate.a = abs(alpha)
	
	print("🔆 Яркость: " + str(int(brightness * 100)) + "% | Альфа: " + str(snapped(alpha, 0.01)))

# ==================== НАСТРОЙКИ ГРОМКОСТИ ====================

func _apply_volume(volume_percent: float):
	var volume = clamp(volume_percent, 0.0, 1.0)
	
	# Громкость работает всегда
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	AudioServer.set_bus_mute(0, volume == 0)
	
	print("🔊 Громкость: " + str(int(volume * 100)) + "%")

# ==================== ЗАГРУЗКА/СОХРАНЕНИЕ НАСТРОЕК ====================

func _load_settings():
	var config = ConfigFile.new()
	if config.load("user://game_settings.cfg") == OK:
		current_brightness = config.get_value("Settings", "brightness", 1.0)
		current_volume = config.get_value("Settings", "volume", 0.8)
		print("✅ Настройки загружены")
	else:
		_save_settings()
		print("📁 Создан файл настроек")

func _save_settings():
	var config = ConfigFile.new()
	config.set_value("Settings", "brightness", current_brightness)
	config.set_value("Settings", "volume", current_volume)
	config.save("user://game_settings.cfg")
	print("💾 Настройки сохранены")

# ==================== ОКНО НАСТРОЕК (ИСПРАВЛЕННОЕ) ====================

func _init_settings_popup():
	settings_popup = Window.new()
	settings_popup.name = "SettingsPopup"
	settings_popup.title = "НАСТРОЙКИ"
	settings_popup.size = Vector2(450, 350)
	settings_popup.unresizable = true
	settings_popup.visible = false
	settings_popup.close_requested.connect(_on_close_settings)
	
	# Основной контейнер
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 30)
	main_container.add_theme_constant_override("separation", 20)
	
	# === ЯРКОСТЬ ===
	var brightness_container = VBoxContainer.new()
	brightness_container.name = "BrightnessContainer"
	brightness_container.add_theme_constant_override("separation", 10)
	
	# Заголовок
	var brightness_title = Label.new()
	brightness_title.text = "ЯРКОСТЬ ЭКРАНА"
	brightness_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brightness_title.add_theme_font_size_override("font_size", 18)
	brightness_container.add_child(brightness_title)
	
	# Горизонтальный контейнер для слайдера
	var brightness_hbox = HBoxContainer.new()
	brightness_hbox.add_spacer(false)
	
	# Метки "Темно" и "Ярко"
	var dark_label = Label.new()
	dark_label.text = "ТЕМНО"
	brightness_hbox.add_child(dark_label)
	
	# СЛАЙДЕР ЯРКОСТИ
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
	
	# Лейбл с процентами
	brightness_percent_label = Label.new()
	brightness_percent_label.name = "BrightnessPercent"
	brightness_percent_label.text = str(int(current_brightness * 100)) + "%"
	brightness_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brightness_percent_label.add_theme_font_size_override("font_size", 16)
	brightness_container.add_child(brightness_percent_label)
	
	main_container.add_child(brightness_container)
	
	# Разделитель
	var separator1 = HSeparator.new()
	separator1.add_theme_constant_override("separation", 20)
	main_container.add_child(separator1)
	
	# === ГРОМКОСТЬ ===
	var volume_container = VBoxContainer.new()
	volume_container.name = "VolumeContainer"
	volume_container.add_theme_constant_override("separation", 10)
	
	# Заголовок
	var volume_title = Label.new()
	volume_title.text = "ГРОМКОСТЬ ЗВУКА"
	volume_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_title.add_theme_font_size_override("font_size", 18)
	volume_container.add_child(volume_title)
	
	# Горизонтальный контейнер
	var volume_hbox = HBoxContainer.new()
	volume_hbox.add_spacer(false)
	
	var quiet_label = Label.new()
	quiet_label.text = "ТИХО"
	volume_hbox.add_child(quiet_label)
	
	# СЛАЙДЕР ГРОМКОСТИ
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
	
	# Лейбл с процентами
	volume_percent_label = Label.new()
	volume_percent_label.name = "VolumePercent"
	volume_percent_label.text = str(int(current_volume * 100)) + "%"
	volume_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_percent_label.add_theme_font_size_override("font_size", 16)
	volume_container.add_child(volume_percent_label)
	
	main_container.add_child(volume_container)
	
	# Разделитель
	var separator2 = HSeparator.new()
	separator2.add_theme_constant_override("separation", 20)
	main_container.add_child(separator2)
	
	# === КНОПКИ ===
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
	
	# Добавляем всё в окно
	settings_popup.add_child(main_container)
	add_child(settings_popup)
	
	# Центрируем окно
	_center_window(settings_popup)
	
	print("✅ Окно настроек создано")

func _center_window(window: Window):
	var screen_size = DisplayServer.window_get_size()
	var window_size = window.size
	window.position = (screen_size - window_size) / 2

# ==================== ОБРАБОТЧИКИ СЛАЙДЕРОВ ====================

func _on_brightness_changed(value: float):
	current_brightness = value / 100.0
	
	# Обновляем лейбл с процентами
	if brightness_percent_label:
		brightness_percent_label.text = str(int(value)) + "%"
	else:
		# Ищем лейбл в окне
		var label = settings_popup.get_node("VBoxContainer/BrightnessContainer/BrightnessPercent")
		if label:
			label.text = str(int(value)) + "%"
	
	# Применяем яркость СРАЗУ
	_apply_brightness(current_brightness)
	
	print("🎚️ Яркость изменена: " + str(int(value)) + "%")

func _on_volume_changed(value: float):
	current_volume = value / 100.0
	
	# Обновляем лейбл с процентами
	if volume_percent_label:
		volume_percent_label.text = str(int(value)) + "%"
	else:
		# Ищем лейбл в окне
		var label = settings_popup.get_node("VBoxContainer/VolumeContainer/VolumePercent")
		if label:
			label.text = str(int(value)) + "%"
	
	# Применяем громкость СРАЗУ
	_apply_volume(current_volume)
	
	print("🎚️ Громкость изменена: " + str(int(value)) + "%")

func _on_apply_settings():
	_save_settings()
	settings_popup.visible = false
	print("✅ Настройки применены")

func _on_close_settings():
	settings_popup.visible = false
	print("🔒 Настройки закрыты")

# ==================== КНОПКИ МЕНЮ ====================

func _on_new_game_button_pressed():
	print("🎮 НОВАЯ ИГРА")
	if save_system and save_system.has_save():
		var popup = ConfirmationDialog.new()
		popup.title = "НОВАЯ ИГРА"
		popup.dialog_text = "Текущее сохранение будет удалено. Продолжить?"
		popup.get_ok_button().text = "ДА"
		popup.get_cancel_button().text = "НЕТ"
		
		popup.confirmed.connect(func():
			save_system.clear_save()
			get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")
			popup.queue_free()
		)
		
		popup.canceled.connect(func():
			popup.queue_free()
		)
		
		add_child(popup)
		popup.popup_centered()
	else:
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _on_continue_game_button_pressed():
	print("🎮 ПРОДОЛЖИТЬ")
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
	if settings_popup:
		# Обновляем слайдеры перед показом
		brightness_slider.value = current_brightness * 100
		volume_slider.value = current_volume * 100
		
		if brightness_percent_label:
			brightness_percent_label.text = str(int(current_brightness * 100)) + "%"
		if volume_percent_label:
			volume_percent_label.text = str(int(current_volume * 100)) + "%"
		
		settings_popup.visible = true
		settings_popup.grab_focus()
	else:
		print("❌ Окно настроек не создано!")

func _on_quit_button_pressed():
	print("🚪 ВЫХОД")
	if confirm_popup:
		confirm_popup.popup_centered()

# ==================== ВЫХОД ИЗ ИГРЫ ====================

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
