extends Panel

signal slot_right_clicked(slot)
signal slot_clicked(slot)

@export var slot_index: int = -1
@export var is_equip_slot: bool = false

var item = null
var item_icon: TextureRect
var count_label: Label

func _ready():

	
	# Создание иконки, если нет
	if not has_node("ItemIcon"):
		item_icon = TextureRect.new()
		item_icon.name = "ItemIcon"
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.custom_minimum_size = Vector2(120, 120)  # большая иконка
		item_icon.visible = false
		add_child(item_icon)
	else:
		item_icon = $ItemIcon
	
	# Создание Label для количества, если нет
	if not has_node("CountLabel"):
		count_label = Label.new()
		count_label.name = "CountLabel"
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.visible = false
		add_child(count_label)
	else:
		count_label = $CountLabel
	
	_refresh_style()
	mouse_filter = MOUSE_FILTER_PASS

func _refresh_style():
	self_modulate = Color(1, 1, 1, 1) if item else Color(1, 1, 1, 0.5)

func initialize_item(item_name: String, item_quantity: int):
	if item_name == null or item_name == "":
		clear_item()
		return
	
	item = {
		"name": item_name,
		"quantity": item_quantity
	}
	
	# Загружаем текстуру
	var texture_path = "res://assets/Items_icon/" + item_name + ".png"
	if ResourceLoader.exists(texture_path):
		item_icon.texture = load(texture_path)
	else:
		# Плейсхолдер
		var image = Image.create(120, 120, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.5, 0.5, 0.5, 1))
		item_icon.texture = ImageTexture.create_from_image(image)
	
	item_icon.visible = true
	item_icon.custom_minimum_size = Vector2(120, 120)

	# Сдвиг вправо для колец/амулетов
	var offset := Vector2(4, 0)  # 4 пикселей вправо
	if not (item_name.begins_with("Ring") or item_name.begins_with("Amulet")):
		offset = Vector2.ZERO  # остальные предметы без смещения

	# Позиция иконки внутри слота
	item_icon.position = ((size - item_icon.custom_minimum_size) / 2) + offset
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Отображение количества, если больше 1
	if item_quantity > 1:
		count_label.text = str(item_quantity)
		count_label.visible = true
	else:
		count_label.visible = false


func clear_item():
	item = null
	if item_icon:
		item_icon.texture = null
		item_icon.visible = false
	if count_label:
		count_label.visible = false
	_refresh_style()

func get_item_name() -> String:
	return item["name"] if item and "name" in item else ""

func get_item_data():
	return item

func has_item() -> bool:
	return item != null

func get_slot_index() -> int:
	return slot_index

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("slot_clicked", self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			emit_signal("slot_right_clicked", self)
