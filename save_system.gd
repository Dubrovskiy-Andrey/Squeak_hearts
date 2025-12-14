extends Node

const SAVE_PATH = "user://save_game.dat"

var save_data: Dictionary = {
	"player_data": {
		"currency": 0,
		"health": 100,
		"max_health": 100,
		"damage": 20,
		"position_x": 0,
		"position_y": 0
	},
	"npc_data": {},
	"inventory_data": {},
	"talisman_data": {},
	"campfire_data": {},
	"game_time": 0,
	"scene_name": ""
}

func _ready():
	load_game()

func save_game(player_node = null, campfire_id = ""):
	if player_node:
		update_player_data(player_node)
	
	if PlayerInventory:
		var inventory_data = PlayerInventory.save_inventory_data()
		save_data["inventory_data"] = inventory_data
	
	if campfire_id != "":
		if "campfire_data" not in save_data:
			save_data["campfire_data"] = {}
		save_data["campfire_data"]["last_campfire"] = campfire_id
	
	var equipped_names = ["", "", ""]
	var inventory_node = _find_inventory_node_in_scene()
	
	if inventory_node and inventory_node.has_method("get_equipped_talisman"):
		for i in range(3):
			var talisman_data = inventory_node.get_equipped_talisman(i)
			if talisman_data:
				equipped_names[i] = talisman_data["name"]
	
	save_data["talisman_data"] = {
		"equipped_talismans": equipped_names
	}
	
	save_data["game_time"] = Time.get_ticks_msec()
	save_data["scene_name"] = get_tree().current_scene.scene_file_path
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func _find_inventory_node_in_scene():
	var current_scene = get_tree().current_scene
	
	if current_scene.has_method("get_equipped_talisman"):
		return current_scene
	
	for child in current_scene.get_children():
		if child.has_method("get_equipped_talisman"):
			return child
		
		var result = _find_inventory_recursive(child)
		if result:
			return result
	
	return null

func _find_inventory_recursive(node):
	for child in node.get_children():
		if child.has_method("get_equipped_talisman"):
			return child
		
		var result = _find_inventory_recursive(child)
		if result:
			return result
	
	return null

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		save_data = file.get_var()
		file.close()
		
		if PlayerInventory and save_data.has("inventory_data"):
			PlayerInventory.load_inventory_data(save_data["inventory_data"])
			
			restore_talismans_to_inventory()
		
		return true
	else:
		return false

func restore_talismans_to_inventory():
	if not PlayerInventory:
		return
	
	var equipped_names = get_equipped_talismans()
	
	PlayerInventory.clear_talisman_inventory()
	
	for talisman_name in equipped_names:
		if talisman_name != "" and talisman_name != null:
			PlayerInventory.add_talisman(talisman_name)

func update_player_data(player_node):
	if not player_node:
		return
	
	save_data["player_data"] = {
		"currency": player_node.get_player_currency(),
		"health": player_node.current_health,
		"max_health": player_node.max_health,
		"damage": player_node.attack_damage,
		"position_x": player_node.global_position.x,
		"position_y": player_node.global_position.y
	}

func get_equipped_talismans() -> Array:
	return save_data.get("talisman_data", {}).get("equipped_talismans", ["", "", ""])

func set_equipped_talismans(talismans: Array):
	if "talisman_data" not in save_data:
		save_data["talisman_data"] = {}
	save_data["talisman_data"]["equipped_talismans"] = talismans

func set_npc_upgrade_level(npc_name: String, level: int):
	if "npc_data" not in save_data:
		save_data["npc_data"] = {}
	
	save_data["npc_data"][npc_name + "_upgrade_level"] = level

func get_npc_upgrade_level(npc_name: String = "salli") -> int:
	return save_data.get("npc_data", {}).get(npc_name + "_upgrade_level", 0)

func get_npc_data() -> Dictionary:
	return save_data.get("npc_data", {})

func get_player_data():
	return save_data.get("player_data", {})

func get_saved_currency():
	return save_data.get("player_data", {}).get("currency", 0)

func set_currency(amount: int):
	if "player_data" not in save_data:
		save_data["player_data"] = {}
	save_data["player_data"]["currency"] = amount

func add_currency(amount: int):
	var current = get_saved_currency()
	set_currency(current + amount)

func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_saved_scene_path() -> String:
	return save_data.get("scene_name", "")

func set_saved_scene(scene_path: String):
	save_data["scene_name"] = scene_path

func clear_save():
	save_data = {
		"player_data": {
			"currency": 0,
			"health": 100,
			"max_health": 100,
			"damage": 20,
			"position_x": 0,
			"position_y": 0
		},
		"npc_data": {},
		"inventory_data": {
			"inventory": {
				0: ["Key", 1]
			},
			"talisman_inventory": {
				0: ["RingOfHealth", 1],
				1: ["RingOfDamage", 1],
				2: ["RingOfBalance", 1]
			}
		},
		"talisman_data": {"equipped_talismans": ["", "", ""]},
		"campfire_data": {},
		"game_time": 0,
		"scene_name": "res://scenes/world/labaratory/lab_scene.tscn"
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func get_all_data():
	return save_data
