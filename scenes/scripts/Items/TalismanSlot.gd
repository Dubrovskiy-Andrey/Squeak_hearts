extends Panel

signal slot_right_clicked(slot)
signal slot_clicked(slot)

@export var slot_index: int = -1
@export var is_equip_slot: bool = false

var item = null
var item_icon: TextureRect
var count_label: Label

func _ready():
	item_icon = $ItemIcon if has_node("ItemIcon") else null
	count_label = $CountLabel if has_node("CountLabel") else null
	
	if item_icon == null or count_label == null:
		_setup_children()
	
	_refresh_style()
	mouse_filter = MOUSE_FILTER_PASS

func _setup_children():
	if item_icon == null:
		item_icon = TextureRect.new()
		item_icon.name = "ItemIcon"
		item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.position = Vector2(4, 4)
		item_icon.visible = false
		add_child(item_icon)
	
	if count_label == null:
		count_label = Label.new()
		count_label.name = "CountLabel"
		count_label.position = Vector2(28, 28)
		
		var font = LabelSettings.new()
		font.font_size = 12
		count_label.label_settings = font
		
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.visible = false
		add_child(count_label)

func _refresh_style():
	if item == null:
		self_modulate = Color(1, 1, 1, 0.5)
	else:
		self_modulate = Color(1, 1, 1, 1)

func initialize_item(item_name, item_quantity):
	if item_name == null or item_name == "":
		clear_item()
		return
	
	item = {
		"name": item_name,
		"quantity": item_quantity
	}
	
	var texture_path = "res://assets/Items_icon/" + item_name + ".png"
	if ResourceLoader.exists(texture_path):
		item_icon.texture = load(texture_path)
		item_icon.visible = true
		
		# УВЕЛИЧИВАЕМ ИКОНКУ ТОЛЬКО ДЛЯ ТАЛИСМАНОВ
		if item_name.begins_with("Ring") or item_name == "RingOfHealth" or item_name == "RingOfDamage" or item_name == "RingOfBalance":
			item_icon.custom_minimum_size = Vector2(48, 48)
			item_icon.position = Vector2(8, 8)
		else:
			item_icon.custom_minimum_size = Vector2(32, 32)
			item_icon.position = Vector2(4, 4)
	else:
		var image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
		if item_name == "RingOfHealth":
			image.fill(Color(1, 0, 0, 1))
		elif item_name == "RingOfDamage":
			image.fill(Color(0, 0, 1, 1))
		elif item_name == "RingOfBalance":
			image.fill(Color(0, 1, 0, 1))
		else:
			image.fill(Color(0.5, 0.5, 0.5, 1))
		
		var texture = ImageTexture.create_from_image(image)
		item_icon.texture = texture
		item_icon.visible = true
		item_icon.custom_minimum_size = Vector2(48, 48)
	
	if item_quantity > 1:
		count_label.text = str(item_quantity)
		count_label.visible = true
	else:
		count_label.visible = false
	
	_refresh_style()

func clear_item():
	item = null
	if item_icon:
		item_icon.texture = null
		item_icon.visible = false
	if count_label:
		count_label.visible = false
	_refresh_style()

func get_item_name():
	if item and "name" in item:
		return item["name"]
	return ""

func get_item_data():
	return item

func has_item():
	return item != null

func get_slot_index():
	return slot_index

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("slot_clicked", self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			emit_signal("slot_right_clicked", self)
