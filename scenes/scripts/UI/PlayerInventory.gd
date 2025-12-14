extends Node

const NUM_INVENTORY_SLOTS = 20
const NUM_TALISMAN_SLOTS = 20

var inventory = {
	0: ["Key", 1],
}

var talisman_inventory = {
	0: ["RingOfHealth", 1],
	1: ["RingOfDamage", 1],
	2: ["RingOfBalance", 1]
}

signal inventory_changed
signal talisman_inventory_changed

func save_inventory_data() -> Dictionary:
	return {
		"inventory": inventory.duplicate(true),
		"talisman_inventory": talisman_inventory.duplicate(true)
	}

func load_inventory_data(data: Dictionary):
	inventory.clear()
	talisman_inventory.clear()
	
	if data.has("inventory"):
		inventory = data["inventory"].duplicate(true)
	
	if data.has("talisman_inventory"):
		talisman_inventory = data["talisman_inventory"].duplicate(true)
	
	inventory_changed.emit()
	talisman_inventory_changed.emit()

func add_item(item_name, item_quantity):
	if JsonData.item_data.has(item_name):
		var item_category = JsonData.item_data[item_name]["ItemCategory"]
		
		if item_category == "Talisman":
			for _i in range(item_quantity):
				add_talisman(item_name)
			return
	
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

func spend_crystals(amount: int) -> bool:
	for slot in inventory:
		if inventory[slot][0] == "Crystal":
			var current_amount = inventory[slot][1]
			if current_amount >= amount:
				inventory[slot][1] -= amount
				
				if inventory[slot][1] <= 0:
					inventory.erase(slot)
				
				inventory_changed.emit()
				return true
	
	return false

func add_talisman(talisman_name: String):
	for i in range(NUM_TALISMAN_SLOTS):
		if not talisman_inventory.has(i):
			talisman_inventory[i] = [talisman_name, 1]
			talisman_inventory_changed.emit()
			return true
	return false

func get_talisman_count() -> int:
	return talisman_inventory.size()

func remove_talisman(slot_index: int):
	if talisman_inventory.has(slot_index):
		talisman_inventory.erase(slot_index)
		talisman_inventory_changed.emit()
		return true
	return false

func get_talisman_data(talisman_name: String) -> Dictionary:
	if JsonData.item_data.has(talisman_name):
		var data = JsonData.item_data[talisman_name]
		return {
			"name": talisman_name,
			"category": data["ItemCategory"],
			"description": data["Description"],
			"stats": data.get("Stats", {})
		}
	return {}

func get_all_talismans() -> Dictionary:
	return talisman_inventory.duplicate()

func clear_talisman_inventory():
	talisman_inventory.clear()
	talisman_inventory_changed.emit()

func reset_for_new_game():
	inventory = {
		0: ["Key", 1]
	}
	
	talisman_inventory = {
		0: ["RingOfHealth", 1],
		1: ["RingOfDamage", 1],
		2: ["RingOfBalance", 1]
	}
	
	inventory_changed.emit()
	talisman_inventory_changed.emit()
