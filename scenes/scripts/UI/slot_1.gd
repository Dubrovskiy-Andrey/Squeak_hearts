extends Panel
var default_tex = preload("res://assets/slot.png")
var empty_tex = preload("res://assets/slot.png")

var default_style: StyleBoxTexture = null
var empty_style: StyleBoxTexture = null
var ItemClass = preload("res://scenes/ui/item.tscn")
var item = null
var slot_index
func _ready():
	default_style = StyleBoxTexture.new()
	empty_style = StyleBoxTexture.new()
	default_style.texture = default_tex
	empty_style.texture = empty_tex
	#if randi() % 2 == 0:
		#item = ItemClass.instantiate()
		#add_child(item)
	refresh_style()

func refresh_style():
	if item == null:
		set('theme_override_styles/panel', empty_style)
	else:
		set('theme_override_styles/panel', default_style)

func pickFromSlot():
	remove_child(item)
	var inventoryNode = find_parent("Inventory")
	inventoryNode.add_child(item)
	item = null
	refresh_style()

func putIntoSlot(new_item):
	item = new_item
	item.position = Vector2(0,0)
	var inventoryNode = find_parent("Inventory")
	inventoryNode.remove_child(item)
	add_child(item)
	refresh_style()

func initialize_item(item_name, item_quantity):
	if item == null:
		item = ItemClass.instantiate()
		add_child(item)
		item.set_item(item_name, item_quantity)
	else:
		item.set_item(item_name, item_quantity)
	refresh_style()
	
	
