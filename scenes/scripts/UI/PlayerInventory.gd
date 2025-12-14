extends Node

const NUM_INVENTORY_SLOTS = 20
var inventory = {
	0: ["Key", 1],
}

signal inventory_changed

func add_item(item_name, item_quantity):
	if item_name == "Crystal":
		add_crystal(item_quantity)
		return
	
	for item in inventory:
		if inventory[item][0] == item_name:
			var stack_size = int(JsonData.item_data[item_name]["StackSize"])
			var able_to_add = stack_size - inventory[item][1]
			if able_to_add >= item_quantity:
				inventory[item][1] += item_quantity
				inventory_changed.emit()
				return
			else:
				inventory[item][1] += able_to_add
				item_quantity -= able_to_add
	
	for i in range(NUM_INVENTORY_SLOTS):
		if inventory.has(i) == false:
			inventory[i] = [item_name, item_quantity]
			inventory_changed.emit()
			return

func remove_item(slot):
	inventory.erase(slot.slot_index)
	inventory_changed.emit()

func add_item_to_empty_slot(item, slot):
	inventory[slot.slot_index] = [item.item_name, item.item_quantity]
	inventory_changed.emit()

func add_item_quantity(slot, quantity_to_add):
	inventory[slot.slot_index][1] += quantity_to_add
	inventory_changed.emit()

func get_currency_amount() -> int:
	var total = 0
	for slot in inventory:
		if inventory[slot][0] == "Trash":
			total += inventory[slot][1]
	return total

func spend_currency(amount: int) -> bool:
	var total_trash = get_currency_amount()
	if total_trash >= amount:
		var amount_to_remove = amount
		var slots_to_remove = []
		for slot in inventory:
			if inventory[slot][0] == "Trash":
				var slot_amount = inventory[slot][1]
				if slot_amount <= amount_to_remove:
					amount_to_remove -= slot_amount
					slots_to_remove.append(slot)
				else:
					inventory[slot][1] -= amount_to_remove
					amount_to_remove = 0
					break
		for slot in slots_to_remove:
			inventory.erase(slot)
		inventory_changed.emit()
		return true
	return false

func add_crystal(amount: int = 1):
	for slot in inventory:
		if inventory[slot][0] == "Crystal":
			inventory[slot][1] += amount
			inventory_changed.emit()
			return true
	
	for i in range(NUM_INVENTORY_SLOTS):
		if not inventory.has(i):
			inventory[i] = ["Crystal", amount]
			inventory_changed.emit()
			return true
	return false

func get_crystal_count() -> int:
	for slot in inventory:
		if inventory[slot][0] == "Crystal":
			return inventory[slot][1]
	return 0

# В PlayerInventory.gd добавь:

func spend_crystals(amount: int) -> bool:
	# Ищем кристаллы в инвентаре
	for slot in inventory:
		if inventory[slot][0] == "Crystal":
			var current_amount = inventory[slot][1]
			if current_amount >= amount:
				inventory[slot][1] -= amount
				
				# Если кристаллов не осталось, удаляем слот
				if inventory[slot][1] <= 0:
					inventory.erase(slot)
				
				inventory_changed.emit()
				print("Кристаллов потрачено:", amount)
				return true
	
	print("Недостаточно кристаллов! Нужно:", amount)
	return false
