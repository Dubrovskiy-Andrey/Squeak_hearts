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
	
	_switch_to_tab("backpack")
	refresh_inventory()
	
	if PlayerInventory:
		PlayerInventory.inventory_changed.connect(refresh_inventory)
		PlayerInventory.talisman_inventory_changed.connect(refresh_inventory)

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
			print("Переключено на вкладку: Рюкзак")
		
		"talismans":
			backpack_panel.visible = false
			talismans_panel.visible = true
			backpack_button.disabled = false
			talismans_button.disabled = true
			print("Переключено на вкладку: Талисманы")
			
			refresh_talismans()

func refresh_inventory():
	print("=== ОБНОВЛЕНИЕ ИНТЕРФЕЙСА ===")
	
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
	print("Обновление инвентаря талисманов")
	
	for slot in talismans_slots:
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
	print("Обновление экипированных талисманов")
	
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
		print("❌ Неверный слот для талисмана!")
		return
	
	if equipped_talismans[slot_index] != null:
		unequip_talisman(slot_index)
	
	equipped_talismans[slot_index] = talisman_data
	print("✅ Талисман экипирован в слот", slot_index)
	
	_apply_talisman_bonuses()
	
	refresh_equipped_talismans()

func unequip_talisman(slot_index: int):
	if slot_index < 0 or slot_index >= equipped_talismans.size():
		return
	
	var talisman = equipped_talismans[slot_index]
	if talisman == null:
		return
	
	print("📤 Талисман снят со слота", slot_index)
	
	_remove_talisman_bonuses(talisman)
	
	equipped_talismans[slot_index] = null
	
	refresh_equipped_talismans()

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
	
	print("💎 Бонусы талисманов применены")

func _remove_talisman_bonuses(talisman):
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		return
	
	if "stats" in talisman:
		var stats = talisman["stats"]
		player.talisman_hp_bonus -= stats.get("HPBonus", 0)
		player.talisman_damage_bonus -= stats.get("DamageBonus", 0)
		player.talisman_speed_bonus -= stats.get("SpeedBonus", 0)
	
	print("💎 Бонусы талисмана убраны")

func add_item(item_name: String, quantity: int):
	if PlayerInventory:
		PlayerInventory.add_item(item_name, quantity)

func get_crystal_count() -> int:
	if PlayerInventory:
		return PlayerInventory.get_crystal_count()
	return 0
