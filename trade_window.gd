extends Node2D

signal window_closed

@onready var texture_rect = $TextureRect
@onready var left_slots = [
	$TextureRect/MainContainer/LeftGrid/LeftSlot1,
	$TextureRect/MainContainer/LeftGrid/LeftSlot2,
	$TextureRect/MainContainer/LeftGrid/LeftSlot3,
	$TextureRect/MainContainer/LeftGrid/LeftSlot4,
	$TextureRect/MainContainer/LeftGrid/LeftSlot5
]
@onready var right_slots = [
	$TextureRect/MainContainer/RightGrid/RightSlot1,
	$TextureRect/MainContainer/RightGrid/RightSlot2,
	$TextureRect/MainContainer/RightGrid/RightSlot3,
	$TextureRect/MainContainer/RightGrid/RightSlot4,
	$TextureRect/MainContainer/RightGrid/RightSlot5
]
@onready var arrows = [
	$TextureRect/ArrowGrid/Arrow1,
	$TextureRect/ArrowGrid/Arrow2,
	$TextureRect/ArrowGrid/Arrow3,
	$TextureRect/ArrowGrid/Arrow4,
	$TextureRect/ArrowGrid/Arrow5
]
@onready var close_button: Button = $TextureRect/BottomPanel/CloseButton
@onready var currency_label: Label = $TextureRect/BottomPanel/StatsPanel/CurrencyLabel
@onready var crystals_label: Label = $TextureRect/BottomPanel/StatsPanel/CrystalsLabel
@onready var trash_icon: TextureRect = $TextureRect/BottomPanel/StatsPanel/TrashIcon
@onready var crystal_icon: TextureRect = $TextureRect/BottomPanel/StatsPanel/CrystalIcon

# Товары NPC
var npc_items = []
var player_currency: int = 0
var player_crystals: int = 0
var player_node: Node = null

func _ready():
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Подключаем сигналы для ВСЕХ слотов
	for i in range(left_slots.size()):
		var slot = left_slots[i]
		if slot and slot.has_signal("slot_clicked"):
			slot.slot_clicked.connect(_on_slot_clicked)
			print("✅ Подключен левый слот", i+1)
	
	for i in range(right_slots.size()):
		var slot = right_slots[i]
		if slot and slot.has_signal("slot_clicked"):
			slot.slot_clicked.connect(_on_slot_clicked)
			print("✅ Подключен правый слот", i+1)
	
	# Загружаем товары из сохранения ИЛИ по умолчанию
	_load_npc_items_from_save()
	
	# Инициализируем все как невидимые
	for slot in left_slots + right_slots:
		if slot:
			slot.visible = false
	
	for arrow in arrows:
		if arrow:
			arrow.visible = false
	
	hide()

func setup(player_data: Dictionary):
	player_currency = player_data.get("currency", 0)
	player_crystals = player_data.get("crystals", 0)
	player_node = player_data.get("player_node", null)
	
	# ОБНОВЛЯЕМ СТАТИСТИКУ В ОКНЕ
	_update_currency_display()
	_load_items()
	_position_at_player_camera()
	show()
	
	print("💰 Окно торговли: Trash =", player_currency, ", Crystals =", player_crystals)

func _load_npc_items_from_save():
	# Стандартные товары если сохранения нет
	var default_items = [
		{"name": "RingOfHealth", "price": 300, "currency": "Trash", "icon": "RingOfHealth"},
		{"name": "RingOfDamage", "price": 450, "currency": "Trash", "icon": "RingOfDamage"},
		{"name": "RingOfBalance", "price": 3, "currency": "Crystal", "icon": "RingOfBalance"},
		{"name": "RingOfSpeed", "price": 600, "currency": "Trash", "icon": "RingOfSpeed"},
		{"name": "RingOfSwiftStrike", "price": 5, "currency": "Crystal", "icon": "RingOfSwiftStrike"}
	]
	
	npc_items = default_items.duplicate(true)
	
	# Пытаемся загрузить из сохранения
	if save_system and save_system.save_data.has("npc_items_trader"):
		var saved_items = save_system.save_data["npc_items_trader"]
		if saved_items is Array and saved_items.size() == default_items.size():
			npc_items = saved_items.duplicate(true)
			print("✅ Товары торговца загружены из сохранения")
		else:
			print("⚠️ Некорректные данные товаров в сохранении, используем стандартные")
	else:
		print("ℹ️ Товары торговца не найдены в сохранении, используем стандартные")
	
	# Проверяем купленные предметы и удаляем их
	if save_system and save_system.save_data.has("purchased_items"):
		var purchased_items = save_system.save_data["purchased_items"]
		for i in range(npc_items.size()):
			var item_name = npc_items[i]["name"]
			if item_name != "" and purchased_items.get(item_name, false):
				print("ℹ️", item_name, " уже куплен, удаляем из ассортимента")
				npc_items[i] = {"name": "", "price": 0, "currency": "", "icon": ""}

func _position_at_player_camera():
	var player = player_node if player_node else get_tree().get_first_node_in_group("players")
	if not player:
		return
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		return

	# Получаем текущий вид камеры
	var camera_center = camera.get_screen_center_position() if camera.has_method("get_screen_center_position") else camera.global_position
	
	# УМЕНЬШАЕМ ОРИГИНАЛЬНЫЙ РАЗМЕР ОКНА НА 150 ПИКСЕЛЕЙ
	# Исходный размер окна (800x600) уменьшаем на 150 пикселей
	var original_window_size = Vector2(650, 450)  # Было 800x600, стало 650x450
	
	# Простой фиксированный масштаб 0.6 (вместо 0.5)
	var scale_ratio = 0.53
	texture_rect.scale = Vector2(scale_ratio, scale_ratio)
	
	# Получаем новый размер окна с учетом масштаба
	var scaled_window_size = original_window_size * scale_ratio
	
	# Позиционируем окно по центру камеры, НО ПОДНИМАЕМ НА 100 ПИКСЕЛЕЙ ВВЕРХ
	texture_rect.position = camera_center - (scaled_window_size / 2) - Vector2(0, 180)
	
	print("📐 Позиция окна торговли:")
	print("  Центр камеры:", camera_center)
	print("  Оригинальный размер:", original_window_size)
	print("  Масштаб:", scale_ratio)
	print("  Финальный размер:", scaled_window_size)
	print("  Позиция окна (с подъемом на 100 пикселей):", texture_rect.position)

func _update_currency_display():
	# ОБНОВЛЯЕМ ЛЕЙБЛЫ И ИКОНКИ В STATSPANEL
	if currency_label:
		currency_label.text = str(player_currency)
	
	if crystals_label:
		crystals_label.text = str(player_crystals)
	
	# ЗАГРУЖАЕМ ИКОНКИ ДЛЯ STATSPANEL
	if trash_icon:
		var trash_texture = load("res://assets/Items_icon/trash.png")
		if trash_texture:
			trash_icon.texture = trash_texture
			trash_icon.visible = true
		else:
			# Создаем простую иконку
			var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
			image.fill(Color(0.6, 0.4, 0.1))
			var tex = ImageTexture.create_from_image(image)
			trash_icon.texture = tex
			trash_icon.visible = true
	
	if crystal_icon:
		var crystal_texture = load("res://assets/Items_icon/crystal.png")
		if crystal_texture:
			crystal_icon.texture = crystal_texture
			crystal_icon.visible = true
		else:
			# Создаем простую иконку
			var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
			image.fill(Color(0.2, 0.7, 0.9))
			var tex = ImageTexture.create_from_image(image)
			crystal_icon.texture = tex
			crystal_icon.visible = true

func _load_items():
	# Очищаем видимость всего
	for slot in left_slots + right_slots:
		if slot:
			slot.visible = false
	
	for arrow in arrows:
		if arrow:
			arrow.visible = false
			arrow.scale = Vector2(0.5, 0.5)
	
	for i in range(left_slots.size()):
		var item = npc_items[i]
		var left = left_slots[i]
		var right = right_slots[i]
		var arrow = arrows[i]
		
		# Если предмет существует - показываем строку
		if item["name"] != "":
			# Левый слот (предмет)
			if left and left.has_method("set_data"):
				left.set_data(i, item["name"], 1, 0, item["icon"])
				left.visible = true
				# Включаем кликабельность для левых слотов
				if left.has_method("set_clickable"):
					left.set_clickable(true)
			
			# Правый слот (валюта)
			if right and right.has_method("set_data"):
				# Определяем иконку валюты
				var currency_icon = ""
				if item["currency"] == "Trash":
					currency_icon = "trash"
				elif item["currency"] == "Crystal":
					currency_icon = "crystal"
				
				# Передаем данные для отображения
				right.set_data(i, item["currency"], item["price"], 0, currency_icon)
				right.visible = true
				# Отключаем кликабельность для правых слотов
				if right.has_method("set_clickable"):
					right.set_clickable(false)
			
			# Стрелка
			if arrow and left and right:
				arrow.visible = true
				var left_pos = left.global_position if left.visible else Vector2.ZERO
				var right_pos = right.global_position if right.visible else Vector2.ZERO
				
				if left.visible and right.visible:
					arrow.global_position = (left_pos + right_pos) / 2
					arrow.global_position -= arrow.size * arrow.scale / 2
		else:
			# Пустой слот - скрываем всё
			if left:
				left.set_data(i, "", 0, 0, "")
				left.visible = false
			if right:
				right.set_data(i, "", 0, 0, "")
				right.visible = false
			if arrow:
				arrow.visible = false

func _on_slot_clicked(slot_index: int, item_name: String, item_amount: int):
	print("🖱️ Клик на слоте", slot_index, ":", item_name)
	
	# НЕ ДАЕМ КЛИКАТЬ НА ВАЛЮТУ (Trash/Crystal)
	if item_name == "Trash" or item_name == "Crystal" or item_name == "":
		print("⚠️ Клик на валюте или пустом слоте - игнорируем")
		return

	# Ищем товар по имени в npc_items
	var item_index = -1
	var item = null
	
	for i in range(npc_items.size()):
		if npc_items[i]["name"] == item_name:
			item_index = i
			item = npc_items[i]
			break
	
	if item_index == -1 or item == null:
		print("❌ Товар не найден в npc_items:", item_name)
		return
	
	var price = item["price"]
	var currency_type = item["currency"]
	
	print("🛒 Покупка:", item_name, " за", price, currency_type)

	if currency_type == "Trash":
		if player_currency < price:
			print("❌ Недостаточно Trash! Нужно:", price, " есть:", player_currency)
			return
		player_currency -= price
		# Обновляем валюту у игрока
		if player_node:
			player_node.currency = player_currency
			if player_node.has_signal("currency_changed"):
				player_node.emit_signal("currency_changed", player_currency)
	elif currency_type == "Crystal":
		if player_crystals < price:
			print("❌ Недостаточно Crystals! Нужно:", price, " есть:", player_crystals)
			return
		player_crystals -= price
		if PlayerInventory:
			PlayerInventory.spend_crystals(price)

	# Покупаем талисман
	if PlayerInventory and PlayerInventory.add_talisman(item_name):
		print("✅ Куплено:", item_name, " добавлено в инвентарь")
		
		# СОХРАНЯЕМ ДАННЫЕ:
		# 1. Помечаем как купленный
		if save_system:
			if not save_system.save_data.has("purchased_items"):
				save_system.save_data["purchased_items"] = {}
			save_system.save_data["purchased_items"][item_name] = true
			print("💾 Покупка сохранена в purchased_items:", item_name)
		
		# 2. Обновляем ассортимент торговца (удаляем купленный товар)
		npc_items[item_index] = {"name": "", "price": 0, "currency": "", "icon": ""}
		
		# 3. Сохраняем обновленный ассортимент
		if save_system:
			save_system.save_data["npc_items_trader"] = npc_items.duplicate(true)
			print("💾 Ассортимент торговца сохранен")
		
		# 4. Сохраняем инвентарь
		if PlayerInventory:
			var inventory_data = PlayerInventory.save_inventory_data()
			if save_system:
				save_system.save_data["inventory_data"] = inventory_data
				print("💾 Инвентарь сохранен")
		
		# 5. Сохраняем всю игру
		if save_system and player_node:
			save_system.save_game(player_node)
			print("💾 Игра сохранена полностью")
		
		# Обновляем отображение
		_update_currency_display()
		_load_items()  # обновляем слоты и стрелки
		
		print("🎉 Покупка завершена и сохранена!")
	else:
		print("❌ Не удалось добавить талисман в инвентарь")

func _on_close_button_pressed():
	print("🛒 Закрываю TradeWindow")
	window_closed.emit()
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
		
