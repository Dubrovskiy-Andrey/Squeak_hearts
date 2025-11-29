extends Panel

signal slot_clicked(slot)
signal slot_right_clicked(slot)
signal slot_begin_drag(slot)
signal slot_end_drag(slot)

@export var slot_index: int = -1

# Подгружаемые ресурсы (по желанию)
var ItemClass = preload("res://scenes/ui/item.tscn")# если нужен
var default_tex = preload("res://assets/slot.png")
var empty_tex = preload("res://assets/slot.png")

# Стили для панели
var default_style: StyleBoxTexture = null
var empty_style: StyleBoxTexture = null

# Содержимое слота: если null — слот пустой.
# Ожидаем, что это либо Node (Item instance), либо Dictionary с { "icon":Texture, "count":int, ... }
var item = null
var is_dragging = false

# Опциональные визуальные ноды внутри слота (если есть в сцене)
# Названия нодов: TextureRect для иконки — "ItemIcon", Label для количества — "CountLabel"
@onready var item_icon: TextureRect = $ItemIcon if has_node("ItemIcon") else null
@onready var count_label: Label = $CountLabel if has_node("CountLabel") else null

func _ready() -> void:
	# Инициализация стилей
	default_style = StyleBoxTexture.new()
	empty_style = StyleBoxTexture.new()
	default_style.texture = default_tex
	empty_style.texture = empty_tex
	mouse_filter = MOUSE_FILTER_PASS
	_refresh_style()
	_update_visuals()

# -------------------- ВСПОМОГАТЕЛЬНЫЕ --------------------
func _get_inventory_node():
	var p = get_parent()
	while p:
		if p.name == "Inventory":
			return p
		p = p.get_parent()
	return null

func _refresh_style():
	if item == null:
		set("theme_override_styles/panel", empty_style)
	else:
		set("theme_override_styles/panel", default_style)

func _update_visuals():
	# Обновляем иконку и количество, если у слота есть дочерние ноды для этого.
	if item_icon:
		var tex = null
		# Если item — Node и содержит TextureRect внутри, пытаемся взять его текстуру
		if item and item is Node:
			if item.has_node("TextureRect"):
				tex = item.get_node("TextureRect").texture
		# Если item — словарь с "icon"
		elif typeof(item) == TYPE_DICTIONARY and item.has("icon"):
			tex = item["icon"]
		item_icon.texture = tex
		item_icon.visible = tex != null

	if count_label:
		var cnt = ""
		if item and item is Node:
			# если предмет node имеет поле item_quantity — пробуем
			if "item_quantity" in item:
				cnt = str(item.item_quantity)
		elif typeof(item) == TYPE_DICTIONARY and item.has("count"):
			cnt = str(item["count"])
		count_label.text = cnt
		count_label.visible = cnt != ""

# -------------------- ПУТЬЫ взятия / помещения предмета --------------------
func pickFromSlot():
	if item == null:
		return
	# Удаляем предмет из слота и перемещаем его в Inventory (root Inventory node)
	var inventoryNode = _get_inventory_node()
	if inventoryNode:
		# перемещаем объект в Inventory root (чтобы он был в сцене, а не внутри слота)
		if item is Node:
			remove_child(item)
			inventoryNode.add_child(item)
	# возвращаем ссылку на предмет
	var tmp = item
	item = null
	_refresh_style()
	_update_visuals()
	return tmp

func putIntoSlot(new_item):
	if new_item == null:
		clear_item()
		return
	item = new_item
	# если new_item — Node, делаем его дочерним нодом слота
	if item is Node:
		# убедимся, что предмет не является уже ребёнком этого слота
		if item.get_parent() != self:
			var prev_parent = item.get_parent()
			if prev_parent:
				prev_parent.remove_child(item)
			add_child(item)
			# выравниваем позицию
			if item.has_method("set_position"):
				item.position = Vector2.ZERO
	_refresh_style()
	_update_visuals()

func initialize_item(item_name, item_quantity):
	# Если вызывают и предоставляют строку/количество — инстанцируем ItemClass и заполним
	if item == null and ItemClass:
		var it = ItemClass.instantiate()
		add_child(it)
		# предполагаем что у Item есть метод set_item(name, quantity)
		if it.has_method("set_item"):
			it.set_item(item_name, item_quantity)
		item = it
	elif item != null and item is Node and item.has_method("set_item"):
		item.set_item(item_name, item_quantity)
	_refresh_style()
	_update_visuals()

func clear_item():
	# Если внутри слот содержит Node, удаляем его (или перемещаем — в зависимости от логики)
	if item and item is Node:
		if item.get_parent() == self:
			remove_child(item)
			item.queue_free()
	item = null
	_refresh_style()
	_update_visuals()

# -------------------- GUI / клики --------------------
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("slot_clicked", self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			emit_signal("slot_right_clicked", self)

# -------------------- DRAG & DROP --------------------
# position параметр не используется — именуем как _position чтобы убрать предупреждения
func get_drag_data(_position):
	if item == null:
		return null

	is_dragging = true
	emit_signal("slot_begin_drag", self)

	# Создаём превью (если есть иконка)
	var preview := TextureRect.new()
	var tex = null
	if item is Node and item.has_node("TextureRect"):
		tex = item.get_node("TextureRect").texture
	elif typeof(item) == TYPE_DICTIONARY and item.has("icon"):
		tex = item["icon"]
	if tex:
		preview.texture = tex
		preview.scale = Vector2(1.2, 1.2)
		preview.modulate = Color(1, 1, 1, 0.9)
		set_drag_preview(preview)
	# Возвращаем данные о перетаскивании
	return { "slot": self, "item": item }

func can_drop_data(_position, data) -> bool:
	# принимаем только словарь с ключом "item"
	return data is Dictionary and data.has("item")

func drop_data(_position, data) -> void:
	if not (data is Dictionary and data.has("slot") and data.has("item")):
		return
	var from_slot = data["slot"]
	# Защита: если тот же слот — ничего не делаем
	if from_slot == self:
		return
	# Меняем содержимое: простая перестановка (swap)
	var temp = item
	# Если пришёл предмет (node), делаем правильное перемещение в дереве сцены
	if data["item"] is Node:
		# убираем объект-источник из его родителя и вставляем сюда
		var it = data["item"]
		if it.get_parent() != self:
			# удаляем у предыдущего родителя (обычно исходный слот)
			var prev = it.get_parent()
			if prev:
				prev.remove_child(it)
			add_child(it)
			# выравниваем
			if it.has_method("set_position"):
				it.position = Vector2.ZERO
		item = it
	else:
		# если пришли данные не Node — просто сохраняем
		item = data["item"]

	# Теперь помещаем temp обратно в from_slot
	if from_slot and from_slot is Object and from_slot.has_method("putIntoSlot"):
		from_slot.putIntoSlot(temp)
	else:
		# если from_slot не умеет принимать - пытаемся вернуть объект на место
		if temp and temp is Node:
			# попробуем вернуть в inventory root
			var inv = _get_inventory_node()
			if inv:
				if temp.get_parent() != inv:
					if temp.get_parent():
						temp.get_parent().remove_child(temp)
					inv.add_child(temp)

	# Сигналы и обновление внешнего вида
	emit_signal("slot_end_drag", self)
	if from_slot:
		from_slot.emit_signal("slot_end_drag", from_slot)
	is_dragging = false
	_refresh_style()
	_update_visuals()
