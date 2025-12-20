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
@onready var save_system = get_node_or_null("/root/save_system")

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
	if save_system:
		load_equipped_talismans()
	else:
		print("❌ save_system не найден в инвентаре")
	
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
	var talisman_name = slot.get_item_name()
	if talisman_name == "":
		return
	
	# Ищем свободный слот для экипировки
	for i in range(3):
		if equipped_talismans[i] == null:
			var data = PlayerInventory.get_talisman_data(talisman_name)
			if data:
				equip_talisman(data, i)
				PlayerInventory.remove_talisman(_find_talisman_slot_index(slot))
			return
	
	# Если все слоты заняты, предлагаем заменить первый
	if equipped_talismans[0]:
		var data = PlayerInventory.get_talisman_data(talisman_name)
		if data:
			# Возвращаем старый талисман в инвентарь
			var old_talisman = equipped_talismans[0]
			PlayerInventory.add_talisman(old_talisman["name"])
			
			# Экипируем новый
			equip_talisman(data, 0)
			PlayerInventory.remove_talisman(_find_talisman_slot_index(slot))

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
	
	print("✅ Талисман экипирован: ", data["name"], " в слот ", index)

func unequip_talisman(index: int):
	var talisman = equipped_talismans[index]
	if not talisman:
		return
	
	_remove_talisman_bonuses(talisman)
	equipped_talismans[index] = null
	refresh_equipped_talismans()
	save_equipped_talismans()
	
	print("📤 Талисман снят: ", talisman["name"], " из слота ", index)

func save_equipped_talismans():
	if not save_system:
		print("❌ save_system не найден для сохранения талисманов")
		return
	
	var arr := ["", "", ""]
	for i in range(3):
		if equipped_talismans[i]:
			arr[i] = equipped_talismans[i]["name"]
	save_system.set_equipped_talismans(arr)
	print("💾 Талисманы сохранены: ", arr)

func load_equipped_talismans():
	if not save_system:
		print("❌ save_system не найден для загрузки талисманов")
		return
	
	# ИСПРАВЛЕННАЯ СТРОКА 121: Явно указываем тип
	var names: Array = save_system.get_equipped_talismans()
	print("📂 Загружаю талисманы: ", names)
	
	# Сначала очищаем все слоты
	for i in range(3):
		equipped_talismans[i] = null
	
	# Загружаем талисманы
	for i in range(3):
		if names[i] != "" and names[i] != null:
			var data = PlayerInventory.get_talisman_data(names[i])
			if data:
				equipped_talismans[i] = data
				print("📂 Талисман загружен: ", names[i], " в слот ", i)
			else:
				print("⚠️ Талисман не найден в инвентаре: ", names[i])
	
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
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		return
	
	# Сбрасываем все бонусы
	player.talisman_hp_bonus = 0
	player.talisman_damage_bonus = 0
	player.talisman_speed_bonus = 0
	player.talisman_cooldown_bonus = 0
	player.talisman_cheese_bonus = 0
	
	# Применяем бонусы всех экипированных талисманов
	for talisman in equipped_talismans:
		if talisman:
			var stats = talisman["stats"]
			player.talisman_hp_bonus += stats.get("HPBonus", 0)
			player.talisman_damage_bonus += stats.get("DamageBonus", 0)
			player.talisman_speed_bonus += stats.get("SpeedBonus", 0)
			player.talisman_cooldown_bonus += stats.get("CooldownBonus", 0)
			player.talisman_cheese_bonus += stats.get("CheeseBonus", 0)
	
	player.update_cheese_bonus()
	player._refresh_inventory_stats()
	
	print("✨ Бонусы талисманов применены")

func _remove_talisman_bonuses(talisman):
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		return
	
	var stats = talisman["stats"]
	player.talisman_hp_bonus -= stats.get("HPBonus", 0)
	player.talisman_damage_bonus -= stats.get("DamageBonus", 0)
	player.talisman_speed_bonus -= stats.get("SpeedBonus", 0)
	player.talisman_cooldown_bonus -= stats.get("CooldownBonus", 0)
	player.talisman_cheese_bonus -= stats.get("CheeseBonus", 0)
	
	player.update_cheese_bonus()
	player._refresh_inventory_stats()

func _find_talisman_slot_index(slot):
	return talismans_slots.find(slot)

func get_equipped_talismans() -> Array:
	return equipped_talismans
