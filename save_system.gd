extends Node

const SAVE_PATH := "user://save_game.dat"

var save_data := {
	"player_data": {},
	"inventory_data": {},
	"talisman_data": {"equipped_talismans": ["", "", ""]},
	"npc_data": {},
	"scene_name": ""
}

func _ready():
	print("Save system готово")

# ---------------------- Сохранение игры ----------------------
func save_game(player: Node = null):
	if player:
		update_player_data(player)
	
	if PlayerInventory:
		save_data["inventory_data"] = PlayerInventory.save_inventory_data()
	
	if get_tree().current_scene:
		save_data["scene_name"] = get_tree().current_scene.scene_file_path
	
	var inv = _find_inventory()
	if inv:
		var arr := ["", "", ""]
		var equipped = inv.get_equipped_talismans()
		for i in range(min(3, equipped.size())):
			if equipped[i]:
				arr[i] = equipped[i]["name"]
		save_data["talisman_data"]["equipped_talismans"] = arr
	
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(save_data)
		f.close()
		print("Игра сохранена")
	else:
		push_error("Не удалось открыть файл для сохранения!")

# ---------------------- Загрузка игры ----------------------
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("Файл сохранения не найден")
		return
	
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		save_data = f.get_var()
		f.close()
		print("Сохранение загружено")
		if PlayerInventory and save_data.has("inventory_data"):
			PlayerInventory.load_inventory_data(save_data["inventory_data"])
	else:
		push_error("Не удалось открыть файл для загрузки!")

# ---------------------- Игровые данные ----------------------
func update_player_data(p: Node):
	save_data["player_data"] = {
		"currency": p.currency,
		"health": p.current_health,
		"max_health": p.max_health,
		"damage": p.attack_damage,
		"position_x": p.global_position.x,
		"position_y": p.global_position.y
	}

func get_player_data() -> Dictionary:
	return save_data.get("player_data", {})

# ---------------------- Талисманы ----------------------
func get_equipped_talismans() -> Array:
	return save_data["talisman_data"].get("equipped_talismans", ["", "", ""])

func set_equipped_talismans(arr: Array):
	save_data["talisman_data"]["equipped_talismans"] = arr

# ---------------------- NPC ----------------------
func set_npc_upgrade_level(npc_name: String, level: int):
	save_data["npc_data"][npc_name + "_upgrade_level"] = level

func get_npc_upgrade_level(npc_name: String) -> int:
	return save_data["npc_data"].get(npc_name + "_upgrade_level", 0)

# ---------------------- Файл сохранения ----------------------
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save():
	if FileAccess.file_exists(SAVE_PATH):
		var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f:
			f.close()
		save_data = {
			"player_data": {},
			"inventory_data": {},
			"talisman_data": {"equipped_talismans": ["", "", ""]},
			"npc_data": {},
			"scene_name": ""
		}
		print("Сохранение очищено")
	else:
		push_error("Файл сохранения не найден для удаления!")

func get_saved_scene_path() -> String:
	return save_data.get("scene_name", "")

func _find_inventory():
	var root = get_tree().current_scene
	if root:
		for n in root.get_children():
			if n.has_method("get_equipped_talismans"):
				return n
	return null

# ---------------------- Валюта ----------------------
func add_currency(amount: int):
	var current: int = save_data["player_data"].get("currency", 0)
	save_data["player_data"]["currency"] = current + amount

# ---------------------- Торговец ----------------------
func get_trader_items() -> Array:
	return save_data.get("npc_items_trader", [])

func set_trader_items(items: Array):
	save_data["npc_items_trader"] = items.duplicate(true)

func get_purchased_items() -> Dictionary:
	return save_data.get("purchased_items", {})

func set_purchased_items(items: Dictionary):
	save_data["purchased_items"] = items.duplicate(true)
