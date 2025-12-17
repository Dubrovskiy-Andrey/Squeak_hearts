extends Panel

@onready var texture_rect = $TextureRect
@onready var amount_label = $AmountLabel
@onready var price_label = $PriceLabel

signal slot_clicked(slot_index, item_name, item_amount)

var slot_index: int = 0
var item_name: String = ""
var item_amount: int = 0
var item_price: int = 0
var item_icon: String = ""
var is_clickable: bool = true
var is_currency_slot: bool = false

func _ready():
	custom_minimum_size = Vector2(160, 160)
	
	# ИСПОЛЬЗУЕМ ТВОЮ ТЕКСТУРУ slot.png КАК ФОН
	var slot_texture = load("res://assets/slot.png")
	if slot_texture:
		var style_box = StyleBoxTexture.new()
		style_box.texture = slot_texture
		style_box.texture_margin_left = 8
		style_box.texture_margin_top = 8
		style_box.texture_margin_right = 8
		style_box.texture_margin_bottom = 8
		
		add_theme_stylebox_override("panel", style_box)
	else:
		# Запасной вариант
		var fallback_style = StyleBoxFlat.new()
		fallback_style.bg_color = Color(0.3, 0.3, 0.35, 0.8)
		fallback_style.border_color = Color(0.8, 0.6, 0.3, 1)
		fallback_style.border_width_left = 2
		fallback_style.border_width_top = 2
		fallback_style.border_width_right = 2
		fallback_style.border_width_bottom = 2
		add_theme_stylebox_override("panel", fallback_style)
	
	# Инициализируем лейблы как невидимые
	if amount_label:
		amount_label.visible = false
	
	if price_label:
		price_label.visible = false
	
	call_deferred("update_display")

# Включает/выключает возможность клика
func set_clickable(clickable: bool):
	is_clickable = clickable
	if not clickable:
		self_modulate = Color(1, 1, 1, 0.8)
	else:
		self_modulate = Color(1, 1, 1, 1.0)

func set_data(idx: int, name: String, amount: int, price: int, icon: String):
	slot_index = idx
	item_name = name
	item_amount = amount
	item_price = price
	item_icon = icon
	
	# Определяем тип слота
	if name == "Trash" or name == "Crystal" or icon == "trash" or icon == "crystal":
		is_currency_slot = true
	else:
		is_currency_slot = false
	
	print("🎴 Слот", slot_index, " данные:")
	print("  Имя:", name, " Количество:", amount, " Цена:", price, " Иконка:", icon)
	print("  Это валюта?:", is_currency_slot)
	
	update_display()

func update_display():
	print("🔄 Обновляю слот", slot_index)
	
	# 1. ИКОНКА - УВЕЛИЧИВАЕМ НА 15%
	if texture_rect:
		if (item_name != "" and item_icon != "") or is_currency_slot:
			var icon_path = ""
			
			if is_currency_slot:
				# ПРАВЫЕ СЛОТЫ: Trash или Crystal
				if item_name == "Trash" or item_icon == "trash":
					icon_path = "res://assets/Items_icon/trash.png"
					print("  🗑️ Ищу trash.png")
				elif item_name == "Crystal" or item_icon == "crystal":
					icon_path = "res://assets/Items_icon/crystal.png"
					print("  💎 Ищу crystal.png")
			else:
				# ЛЕВЫЕ СЛОТЫ: Кольца
				icon_path = "res://assets/Items_icon/%s.png" % item_icon
				print("  💍 Ищу:", icon_path)
			
			if icon_path != "":
				var icon_texture = load(icon_path)
				if icon_texture:
					texture_rect.texture = icon_texture
					texture_rect.visible = true
					# УВЕЛИЧИВАЕМ ИКОНКУ НА 15% - 120 * 1.15 = 138
					texture_rect.size = Vector2(138, 138)  # Было 120x120
					# Центрируем увеличенную иконку
					texture_rect.position = Vector2((size.x - texture_rect.size.x) / 2, 10)
					print("  ✅ Иконка загружена, размер увеличен на 15%")
				else:
					print("  ❌ Иконка не найдена! Создаю цветную...")
					_create_color_icon()
			else:
				_create_color_icon()
		else:
			texture_rect.visible = false
			print("  ⬜ Нет иконки для отображения")
	
	# 2. AMOUNTLABEL - ДЛЯ КОЛИЧЕСТВА КОЛЕЦ (если > 1)
	if amount_label:
		if not is_currency_slot and item_amount > 1:
			# ЛЕВЫЕ СЛОТЫ: количество колец если > 1
			amount_label.text = "x" + str(item_amount)
			amount_label.visible = true
			amount_label.position = size - amount_label.size - Vector2(5, 5)  # Правый нижний угол
			amount_label.add_theme_font_size_override("font_size", 16)
			amount_label.add_theme_color_override("font_color", Color(1, 1, 1))
			print("  🔢 Количество колец:", item_amount)
		else:
			amount_label.visible = false
	
	# 3. PRICELABEL - ДЛЯ ЦЕНЫ ВАЛЮТЫ (правые слоты)
	if price_label:
		if is_currency_slot and item_amount > 0:
			# ПРАВЫЕ СЛОТЫ: показываем цену товара
			price_label.text = str(item_amount)  # item_amount = цена товара
			price_label.visible = true
			
			# УСТАНАВЛИВАЕМ РАЗМЕР ШРИФТА
			price_label.add_theme_font_size_override("font_size", 28)
			price_label.add_theme_font_override("font", load("res://Fonts/m5x7.ttf"))  # Если есть шрифт
			
			# ЦВЕТА
			if item_name == "Trash" or item_icon == "trash":
				price_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))  # Золотой
				print("  💰 Цена Trash:", item_amount)
			elif item_name == "Crystal" or item_icon == "crystal":
				# ИЗМЕНЕНИЕ #2: КРАСНЫЙ ЦВЕТ ДЛЯ CRYSTAL - "crystal карсным"
				price_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # КРАСНЫЙ вместо голубого
				print("  🔴 Цена Crystal (красный):", item_amount)
			
			# ЖДЁМ ОБНОВЛЕНИЯ РАЗМЕРА ТЕКСТА
			await get_tree().process_frame
			
			# ПОЗИЦИЯ: ЦЕНТРИРУЕМ И ПОДНИМАЕМ ЧУТЬ ВЫШЕ
			var label_width = price_label.size.x
			var label_height = price_label.size.y
			var center_x = (size.x - label_width) / 2
			
			# ЧУТЬ ВЫШЕ ОТ НИЗА - не size.y - 30, а size.y - 40 (на 10 пикселей выше)
			var pos_y = size.y - 40
			
			price_label.position = Vector2(center_x, pos_y)
			print("  📍 Цена отцентрирована. Позиция: X=", center_x, " Y=", pos_y)
		else:
			price_label.visible = false

func _create_color_icon():
	# Создаем цветную иконку как заглушку
	# УВЕЛИЧИВАЕМ РАЗМЕР НА 15%
	var new_size = 120 * 1.15  # 138 пикселей
	var image = Image.create(int(new_size), int(new_size), false, Image.FORMAT_RGBA8)
	
	if is_currency_slot:
		if item_name == "Trash" or item_icon == "trash":
			image.fill(Color(0.6, 0.4, 0.1))  # Коричневый для Trash
			print("  🎨 Создана коричневая иконка для Trash (увеличена на 15%)")
		elif item_name == "Crystal" or item_icon == "crystal":
			image.fill(Color(0.2, 0.7, 0.9))  # Голубой для Crystal
			print("  🎨 Создана голубая иконка для Crystal (увеличена на 15%)")
	elif item_name.begins_with("Ring"):
		image.fill(Color(0.8, 0.2, 0.2))  # Красный для колец
		print("  🎨 Создана красная иконка для кольца (увеличена на 15%)")
	else:
		image.fill(Color(0.7, 0.5, 0.3))  # Коричневый для других
		print("  🎨 Создана коричневая иконка (увеличена на 15%)")
	
	var tex = ImageTexture.create_from_image(image)
	texture_rect.texture = tex
	texture_rect.visible = true
	texture_rect.size = Vector2(new_size, new_size)
	texture_rect.position = Vector2((size.x - texture_rect.size.x) / 2, 10)

func _gui_input(event):
	# Проверяем можно ли кликать на этот слот
	# НЕ ДАЕМ КЛИКАТЬ НА ВАЛЮТНЫЕ СЛОТЫ И НЕКЛИКАБЕЛЬНЫЕ СЛОТЫ
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_clickable and item_name != "" and not is_currency_slot:
			print("🖱️ Клик на слоте", slot_index, ":", item_name)
			slot_clicked.emit(slot_index, item_name, item_amount)
	
	# Эффект при наведении (только для кликабельных НЕвалютных слотов)
	if event is InputEventMouseMotion and is_clickable and not is_currency_slot:
		if item_name != "":
			self_modulate = Color(1, 1, 1, 1.2)
		else:
			self_modulate = Color(1, 1, 1, 1.0)
