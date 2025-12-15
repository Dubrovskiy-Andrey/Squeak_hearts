extends Node2D

@onready var backpack_button: Button = $TabButtons/BackpackButton
@onready var talismans_button: Button = $TabButtons/TalismansButton
@onready var backpack_panel: Panel = $RightPanel/BackpackPanel
@onready var talismans_panel: Panel = $RightPanel/TalismansPanel
@onready var backpack_slots = $RightPanel/BackpackPanel/BackpackGrid.get_children()
@onready var talismans_slots = $RightPanel/TalismansPanel/TalismansGrid.get_children()
@onready var talisman_equip_slots = $LeftPanel/TalismanSlots.get_children()

var current_tab := "backpack"
var equipped_talismans: Array = [null, null, null]

func _ready():
	backpack_button.pressed.connect(func(): _switch_to_tab("backpack"))
	talismans_button.pressed.connect(func(): _switch_to_tab("talismans"))
	
	for slot in talismans_slots:
		slot.slot_right_clicked.connect(_on_talisman_slot_right_clicked)
	
	for slot in talisman_equip_slots:
		slot.slot_right_clicked.connect(_on_equip_slot_right_clicked)
	
	_switch_to_tab("backpack")
	call_deferred("_initialize_after_load")

func _initialize_after_load():
	await get_tree().process_frame
	load_equipped_talismans()
	refresh_inventory()
	PlayerInventory.inventory_changed.connect(refresh_inventory)
	PlayerInventory.talisman_inventory_changed.connect(refresh_inventory)

func _switch_to_tab(tab: String):
	current_tab = tab
	backpack_panel.visible = tab == "backpack"
	talismans_panel.visible = tab == "talismans"
	backpack_button.disabled = tab == "backpack"
	talismans_button.disabled = tab == "talismans"
	if tab == "talismans":
		refresh_talismans()

func _on_talisman_slot_right_clicked(slot):
	var name = slot.get_item_name()
	if name == "":
		return
	
	for i in range(3):
		if equipped_talismans[i] == null:
			var data = PlayerInventory.get_talisman_data(name)
			if data:
				equip_talisman(data, i)
				PlayerInventory.remove_talisman(_find_talisman_slot_index(slot))
			return

func _on_equip_slot_right_clicked(slot):
	var index := talisman_equip_slots.find(slot)
	if index == -1:
		return
	
	var talisman = equipped_talismans[index]
	if talisman:
		unequip_talisman(index)
		PlayerInventory.add_talisman(talisman["name"])

func equip_talisman(data: Dictionary, index: int):
	equipped_talismans[index] = data
	_apply_talisman_bonuses()
	refresh_equipped_talismans()
	save_equipped_talismans()

func unequip_talisman(index: int):
	var talisman = equipped_talismans[index]
	if not talisman:
		return
	_remove_talisman_bonuses(talisman)
	equipped_talismans[index] = null
	refresh_equipped_talismans()
	save_equipped_talismans()

func save_equipped_talismans():
	var arr := ["", "", ""]
	for i in range(3):
		if equipped_talismans[i]:
			arr[i] = equipped_talismans[i]["name"]
	save_system.set_equipped_talismans(arr)

func load_equipped_talismans():
	var names := save_system.get_equipped_talismans()
	for i in range(3):
		equipped_talismans[i] = null
	
	for i in range(3):
		if names[i] != "":
			var data = PlayerInventory.get_talisman_data(names[i])
			if data:
				equipped_talismans[i] = data
				for slot in PlayerInventory.talisman_inventory:
					if PlayerInventory.talisman_inventory[slot][0] == names[i]:
						PlayerInventory.remove_talisman(slot)
						break
	
	_apply_talisman_bonuses()
	refresh_equipped_talismans()

func refresh_inventory():
	refresh_equipped_talismans()
	if current_tab == "backpack":
		_refresh_backpack()
	else:
		refresh_talismans()

func _refresh_backpack():
	for slot in backpack_slots:
		slot.clear_item()
	for i in PlayerInventory.inventory:
		var data = PlayerInventory.inventory[i]
		if i < backpack_slots.size():
			backpack_slots[i].initialize_item(data[0], data[1])

func refresh_talismans():
	for slot in talismans_slots:
		slot.clear_item()
	for i in PlayerInventory.talisman_inventory:
		if i < talismans_slots.size():
			talismans_slots[i].initialize_item(
				PlayerInventory.talisman_inventory[i][0], 1
			)

func refresh_equipped_talismans():
	for slot in talisman_equip_slots:
		slot.clear_item()
	for i in range(3):
		if equipped_talismans[i]:
			talisman_equip_slots[i].initialize_item(
				equipped_talismans[i]["name"], 1
			)

func _apply_talisman_bonuses():
	var p = get_tree().get_first_node_in_group("players")
	if not p:
		return
	
	p.talisman_hp_bonus = 0
	p.talisman_damage_bonus = 0
	p.talisman_speed_bonus = 0
	
	for t in equipped_talismans:
		if t:
			var s = t["stats"]
			p.talisman_hp_bonus += s.get("HPBonus", 0)
			p.talisman_damage_bonus += s.get("DamageBonus", 0)
			p.talisman_speed_bonus += s.get("SpeedBonus", 0)
	
	p._refresh_inventory_stats()

func _remove_talisman_bonuses(t):
	var p = get_tree().get_first_node_in_group("players")
	if not p:
		return
	
	var s = t["stats"]
	p.talisman_hp_bonus -= s.get("HPBonus", 0)
	p.talisman_damage_bonus -= s.get("DamageBonus", 0)
	p.talisman_speed_bonus -= s.get("SpeedBonus", 0)
	p._refresh_inventory_stats()

func _find_talisman_slot_index(slot):
	return talismans_slots.find(slot)

func get_equipped_talisman(i: int):
	return equipped_talismans[i]
