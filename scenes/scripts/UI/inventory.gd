extends Node2D

@onready var backpack_button: Button = $TabButtons/BackpackButton
@onready var talismans_button: Button = $TabButtons/TalismansButton
@onready var backpack_panel: Panel = $RightPanel/BackpackPanel
@onready var talismans_panel: Panel = $RightPanel/TalismansPanel
@onready var backpack_slots = $RightPanel/BackpackPanel/BackpackGrid.get_children()
@onready var talismans_slots = $RightPanel/TalismansPanel/TalismansGrid.get_children()
@onready var talisman_equip_slots = $LeftPanel/TalismanSlots.get_children()

var current_tab: String = "backpack"
var equipped_talismans: Array = [null, null, null]

func _ready():
	backpack_button.pressed.connect(_on_backpack_tab_pressed)
	talismans_button.pressed.connect(_on_talismans_tab_pressed)
	
	var talisman_slots_container = $LeftPanel/TalismanSlots
	if talisman_slots_container is VBoxContainer:
		talisman_slots_container.add_theme_constant_override("separation", 15)
	
	for slot in talismans_slots:
		if slot.has_signal("slot_right_clicked"):
			slot.slot_right_clicked.connect(_on_talisman_slot_right_clicked)
		if slot.has_signal("slot_clicked"):
			slot.slot_clicked.connect(_on_talisman_slot_clicked)
	
	for slot in talisman_equip_slots:
		if slot.has_signal("slot_right_clicked"):
			slot.slot_right_clicked.connect(_on_equip_slot_right_clicked)
		if slot.has_signal("slot_clicked"):
			slot.slot_clicked.connect(_on_equip_slot_clicked)
	
	_switch_to_tab("backpack")
	call_deferred("_initialize_after_load")

func _initialize_after_load():
	await get_tree().process_frame
	
	load_equipped_talismans()
	refresh_inventory()
	
	if PlayerInventory:
		PlayerInventory.inventory_changed.connect(refresh_inventory)
		PlayerInventory.talisman_inventory_changed.connect(refresh_inventory)

func _get_equipped_names() -> Array:
	var names = []
	for talisman in equipped_talismans:
		if talisman != null:
			names.append(talisman["name"])
		else:
			names.append("")
	return names

func get_save_system():
	if has_node("/root/SaveSystem"):
		return get_node("/root/SaveSystem")
	
	var root = get_tree().root
	for node in root.get_children():
		if node is Node and node.name == "SaveSystem":
			return node
	
	return null

func save_equipped_talismans():
	var equipped_names = _get_equipped_names()
	
	var save_system = get_save_system()
	if save_system:
		save_system.set_equipped_talismans(equipped_names)

func load_equipped_talismans():
	var save_system = get_save_system()
	if not save_system:
		return
	
	var equipped_names = save_system.get_equipped_talismans()
	_apply_loaded_talismans(equipped_names)

func _apply_loaded_talismans(equipped_names: Array):
	for i in range(equipped_talismans.size()):
		equipped_talismans[i] = null
	
	for i in range(min(equipped_names.size(), 3)):
		var talisman_name = equipped_names[i]
		
		if talisman_name != "" and talisman_name != null:
			if PlayerInventory:
				var talisman_data = PlayerInventory.get_talisman_data(talisman_name)
				if talisman_data:
					equipped_talismans[i] = talisman_data
	
	_apply_talisman_bonuses()
	refresh_equipped_talismans()

func get_equipped_talisman(slot_index: int):
	if slot_index >= 0 and slot_index < equipped_talismans.size():
		return equipped_talismans[slot_index]
	return null

func _on_backpack_tab_pressed():
	_switch_to_tab("backpack")

func _on_talismans_tab_pressed():
	_switch_to_tab("talismans")

func _switch_to_tab(tab_name: String):
	current_tab = tab_name
	
	match tab_name:
		"backpack":
			backpack_panel.visible = true
			talismans_panel.visible = false
			backpack_button.disabled = true
			talismans_button.disabled = false
		
		"talismans":
			backpack_panel.visible = false
			talismans_panel.visible = true
			backpack_button.disabled = false
			talismans_button.disabled = true
			refresh_talismans()

func _on_talisman_slot_right_clicked(slot):
	var item_name = slot.get_item_name()
	if item_name == "":
		return
	
	for i in range(equipped_talismans.size()):
		if equipped_talismans[i] == null:
			var talisman_data = PlayerInventory.get_talisman_data(item_name)
			if talisman_data:
				equip_talisman(talisman_data, i)
				
				var slot_index = _find_talisman_slot_index(slot)
				if slot_index != -1:
					PlayerInventory.remove_talisman(slot_index)
				
				save_equipped_talismans()
				return

func _on_equip_slot_right_clicked(slot):
	var slot_index = -1
	for i in range(talisman_equip_slots.size()):
		if talisman_equip_slots[i] == slot:
			slot_index = i
			break
	
	if slot_index == -1:
		return
	
	if equipped_talismans[slot_index] != null:
		var talisman_name = equipped_talismans[slot_index]["name"]
		unequip_talisman(slot_index)
		
		var success = PlayerInventory.add_talisman(talisman_name)
		save_equipped_talismans()

func _on_talisman_slot_clicked(slot):
	pass

func _on_equip_slot_clicked(slot):
	pass

func _find_talisman_slot_index(clicked_slot):
	for i in range(talismans_slots.size()):
		if talismans_slots[i] == clicked_slot:
			return i
	return -1

func refresh_inventory():
	var stats_panel = $LeftPanel/StatsPanel
	if stats_panel and stats_panel.has_method("refresh_stats"):
		stats_panel.refresh_stats()
	
	refresh_equipped_talismans()
	
	if current_tab == "backpack":
		_refresh_backpack()
	elif current_tab == "talismans":
		refresh_talismans()

func _refresh_backpack():
	if not PlayerInventory:
		return
	
	var inventory = PlayerInventory.inventory
	
	for slot in backpack_slots:
		if slot.has_method("clear_item"):
			slot.clear_item()
	
	for slot_index in inventory:
		var item_data = inventory[slot_index]
		var item_name = item_data[0]
		var item_quantity = item_data[1]
		
		if item_quantity > 0:
			if slot_index < backpack_slots.size():
				var slot = backpack_slots[slot_index]
				if slot.has_method("initialize_item"):
					slot.initialize_item(item_name, item_quantity)

func refresh_talismans():
	for i in range(talismans_slots.size()):
		var slot = talismans_slots[i]
		if slot.has_method("clear_item"):
			slot.clear_item()
	
	if PlayerInventory:
		var talismans = PlayerInventory.talisman_inventory
		
		for slot_index in talismans:
			var talisman_data = talismans[slot_index]
			var talisman_name = talisman_data[0]
			
			if slot_index < talismans_slots.size():
				var slot = talismans_slots[slot_index]
				if slot.has_method("initialize_item"):
					slot.initialize_item(talisman_name, 1)

func refresh_equipped_talismans():
	for slot in talisman_equip_slots:
		if slot.has_method("clear_item"):
			slot.clear_item()
	
	for i in range(equipped_talismans.size()):
		if equipped_talismans[i] != null and i < talisman_equip_slots.size():
			var slot = talisman_equip_slots[i]
			var talisman_data = equipped_talismans[i]
			
			if slot.has_method("initialize_item"):
				slot.initialize_item(talisman_data["name"], 1)

func equip_talisman(talisman_data, slot_index: int):
	if slot_index < 0 or slot_index >= equipped_talismans.size():
		return
	
	if equipped_talismans[slot_index] != null:
		unequip_talisman(slot_index)
	
	equipped_talismans[slot_index] = talisman_data
	
	_apply_talisman_bonuses()
	refresh_equipped_talismans()
	save_equipped_talismans()

func unequip_talisman(slot_index: int):
	if slot_index < 0 or slot_index >= equipped_talismans.size():
		return
	
	var talisman = equipped_talismans[slot_index]
	if talisman == null:
		return
	
	_remove_talisman_bonuses(talisman)
	equipped_talismans[slot_index] = null
	refresh_equipped_talismans()
	save_equipped_talismans()

func _apply_talisman_bonuses():
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		return
	
	player.talisman_hp_bonus = 0
	player.talisman_damage_bonus = 0
	player.talisman_speed_bonus = 0
	
	for talisman in equipped_talismans:
		if talisman != null and "stats" in talisman:
			var stats = talisman["stats"]
			player.talisman_hp_bonus += stats.get("HPBonus", 0)
			player.talisman_damage_bonus += stats.get("DamageBonus", 0)
			player.talisman_speed_bonus += stats.get("SpeedBonus", 0)
	
	if player.has_method("_refresh_inventory_stats"):
		player._refresh_inventory_stats()
	
	if player.has_signal("health_changed"):
		player.emit_signal("health_changed", 
			player.current_health + player.talisman_hp_bonus, 
			player.max_health + player.talisman_hp_bonus
		)

func _remove_talisman_bonuses(talisman):
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		return
	
	if "stats" in talisman:
		var stats = talisman["stats"]
		player.talisman_hp_bonus -= stats.get("HPBonus", 0)
		player.talisman_damage_bonus -= stats.get("DamageBonus", 0)
		player.talisman_speed_bonus -= stats.get("SpeedBonus", 0)
	
	if player.has_method("_refresh_inventory_stats"):
		player._refresh_inventory_stats()
	
	if player.has_signal("health_changed"):
		player.emit_signal("health_changed", 
			player.current_health + player.talisman_hp_bonus, 
			player.max_health + player.talisman_hp_bonus
		)

func add_item(item_name: String, quantity: int):
	if PlayerInventory:
		PlayerInventory.add_item(item_name, quantity)

func get_crystal_count() -> int:
	if PlayerInventory:
		return PlayerInventory.get_crystal_count()
	return 0
