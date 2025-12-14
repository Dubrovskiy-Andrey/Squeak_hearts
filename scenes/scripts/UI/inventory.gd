extends Node2D

@onready var slots = $GridContainer.get_children()

func _ready():
	refresh_inventory()
	if PlayerInventory:
		PlayerInventory.inventory_changed.connect(refresh_inventory)

func refresh_inventory():
	print("=== ОБНОВЛЕНИЕ ИНВЕНТАРЯ ===")
	
	var inventory = PlayerInventory.inventory
	
	# Проверяем что получили
	print("Данные инвентаря:", inventory)
	
	# Очищаем все слоты
	for slot in slots:
		if slot.has_method("clear_item"):
			slot.clear_item()
	
	# Заполняем слоты ТОЛЬКО если есть предметы
	for slot_index in inventory:
		var item_data = inventory[slot_index]
		var item_name = item_data[0]
		var item_quantity = item_data[1]
		
		# Показываем только если количество > 0
		if item_quantity > 0:
			print("Слот", slot_index, ":", item_name, " x", item_quantity)
			
			if slot_index < slots.size():
				var slot = slots[slot_index]
				if slot.has_method("initialize_item"):
					slot.initialize_item(item_name, item_quantity)
	
	var stats_panel = get_node_or_null("StatsPanel")
	if stats_panel and stats_panel.has_method("refresh_stats"):
		stats_panel.refresh_stats()

func add_item(item_name: String, quantity: int):
	if PlayerInventory:
		PlayerInventory.add_item(item_name, quantity)

func get_crystal_count() -> int:
	if PlayerInventory:
		return PlayerInventory.get_crystal_count()
	return 0
