extends Panel

# Загружаем данные из JSON
var item_data: Dictionary = {}
var item_data_loaded: bool = false
var current_item: String = ""

# UI элементы
var title_label: Label = null
var desc_label: Label = null
var stats_label: Label = null

func _ready():
	# 1. Загружаем данные из JSON СРАЗУ
	_load_item_data()
	
	# 2. Стилизуем панель
	_create_panel_style()
	
	# 3. Создаем контейнер и лейблы
	_create_ui_elements()
	
	# 4. Скрываем по умолчанию
	visible = false
	z_index = 1000  # Чтобы был поверх всего

func _load_item_data():
	print("🔄 Начинаю загрузку ItemData.json...")

	
	if not FileAccess.file_exists(	"res://Data/ItemData.json"):
		print("❌ Файл ItemData.json не найден!")
		return
	
	var file = FileAccess.open(	"res://Data/ItemData.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			item_data = json.data
			item_data_loaded = true
			print("✅ JSON загружен успешно! Записей:", item_data.size())
		else:
			print("❌ Ошибка парсинга JSON:", json.get_error_message())
		file.close()
	else:
		print("❌ Не удалось открыть файл")

func _create_panel_style():
	# Устанавливаем минимальный размер
	custom_minimum_size = Vector2(320, 230)
	
	# Стиль для тултипа
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.98)  # Темный фон
	style.border_color = Color(1, 0.8, 0.2, 0.9)    # Золотая рамка
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 15
	style.shadow_offset = Vector2(4, 4)
	
	add_theme_stylebox_override("panel", style)

func _create_ui_elements():
	# Создаем вертикальный контейнер
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 15)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	# 1. Заголовок
	title_label = Label.new()
	title_label.text = "НАЗВАНИЕ"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))  # Золотой
	title_label.add_theme_constant_override("outline_size", 4)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	vbox.add_child(title_label)
	
	# Разделитель
	var separator1 = HSeparator.new()
	separator1.add_theme_constant_override("separation", 5)
	vbox.add_child(separator1)
	
	# 2. Описание
	desc_label = Label.new()
	desc_label.text = "Описание предмета..."
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))  # Бело-голубой
	desc_label.add_theme_constant_override("line_spacing", 3)
	vbox.add_child(desc_label)
	
	# Разделитель
	var separator2 = HSeparator.new()
	separator2.add_theme_constant_override("separation", 5)
	vbox.add_child(separator2)
	
	# 3. Статистика
	stats_label = Label.new()
	stats_label.text = "+50 HP\n+10% Урон"
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))  # Светло-зеленый
	stats_label.add_theme_constant_override("line_spacing", 5)
	vbox.add_child(stats_label)

# Преобразуем название предмета в читаемое имя
func _get_display_name(item_key: String) -> String:
	match item_key:
		"RingOfHealth": return "КОЛЬЦО ЗДОРОВЬЯ"
		"RingOfDamage": return "КОЛЬЦО УРОНА"
		"RingOfBalance": return "КОЛЬЦО БАЛАНСА"
		"RingOfSpeed": return "КОЛЬЦО СКОРОСТИ"
		"RingOfSwiftStrike": return "КОЛЬЦО БЫСТРОГО УДАРА"
		"Trash": return "МУСОР"
		"Crystal": return "МАГИЧЕСКИЙ КРИСТАЛЛ"
		"Key": return "КЛЮЧ"
		"MapScroll": return "СВИТОК С КАРТОЙ"
		"HunterMedallion": return "МЕДАЛЬОН ОХОТНИКА"
		"SkullShard": return "ОСКОЛОК ЧЕРЕПА"
		"TalismanSlotExample": return "ПРИМЕР ТАЛИСМАНА"
		_: 
			# Преобразуем "RingOfHealth" в "Кольцо Здоровья"
			if item_key.begins_with("RingOf"):
				var words = item_key.replace("RingOf", "").replace("Of", " ")
				return "КОЛЬЦО " + words.to_upper()
			return item_key.to_upper()

# Преобразуем статистику в читаемый текст
func _stats_to_text(stats_dict: Dictionary) -> String:
	var text = ""
	
	if stats_dict.has("HPBonus") and stats_dict["HPBonus"] > 0:
		text += "❤️ +" + str(stats_dict["HPBonus"]) + " к максимальному HP\n"
	
	if stats_dict.has("DamageBonus") and stats_dict["DamageBonus"] > 0:
		text += "⚔️ +" + str(stats_dict["DamageBonus"]) + " к урону\n"
	
	if stats_dict.has("SpeedBonus") and stats_dict["SpeedBonus"] > 0:
		text += "🏃 +" + str(stats_dict["SpeedBonus"]) + "% к скорости\n"
	
	# Если нет статистики, показываем тип предмета
	if text == "":
		if item_data.has(current_item) and item_data[current_item].has("ItemCategory"):
			var category = item_data[current_item]["ItemCategory"]
			match category:
				"Currency": text = "💰 Основная валюта"
				"Resource": text = "💎 Редкий ресурс"
				"StoryItem": text = "📜 Сюжетный предмет"
				"StatItem": text = "📊 Статистический предмет"
				"Talisman": text = "✨ Талисман"
				_: text = "📦 Обычный предмет"
	
	return text.strip_edges()

# Показываем тултип с информацией о предмете
func show_tooltip(item_key: String, position: Vector2 = Vector2.ZERO):
	print("🔄 Показываю тултип для:", item_key)
	print("📊 Данные загружены:", item_data_loaded)
	print("📊 Предмет в данных:", item_data.has(item_key))
	
	current_item = item_key
	
	# Проверяем наличие данных
	if not item_data_loaded:
		print("⚠️ Данные не загружены, загружаю...")
		_load_item_data()
	
	# Проверяем есть ли такой предмет
	var item_info = {}
	if item_data.has(item_key):
		item_info = item_data[item_key]
		print("✅ Предмет найден:", item_info)
	else:
		print("❌ Предмет НЕ найден в данных!")
		item_info = {
			"Description": "Предмет не найден в базе данных",
			"Stats": {},
			"ItemCategory": "Unknown"
		}
	
	# Получаем заголовок
	var display_name = _get_display_name(item_key)
	
	# Получаем описание
	var description = item_info.get("Description", "Описание отсутствует.")
	
	# Получаем статистику
	var stats_dict = item_info.get("Stats", {})
	var stats_text = _stats_to_text(stats_dict)
	
	print("📝 Отображаю:")
	print("  Название:", display_name)
	print("  Описание:", description)
	print("  Статистика:", stats_text)
	
	# Обновляем текст
	if title_label:
		title_label.text = display_name
	
	if desc_label:
		desc_label.text = description
	
	if stats_label:
		stats_label.text = stats_text
	
	# Позиционируем (с небольшим смещением от мыши)
	if position != Vector2.ZERO:
		global_position = position + Vector2(20,-100)
	
	# Показываем с анимацией
	visible = true
	modulate.a = 0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25).from(Vector2(0.9, 0.9)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# Скрываем тултип
func hide_tooltip():
	if not visible:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	
	await tween.finished
	visible = false

# Обновляем позицию, чтобы тултип следовал за мышью
func update_position(new_position: Vector2):
	if visible:
		global_position = new_position + Vector2(20, -100)
