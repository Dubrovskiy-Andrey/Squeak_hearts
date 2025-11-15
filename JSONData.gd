extends Node

var item_data: Dictionary

func _ready():
	item_data = LoadData("res://Data/ItemData.json")

func LoadData(file_path):
	var file_data  = FileAccess.open(file_path, FileAccess.READ)
	var json_data  = JSON.new()
	json_data .parse(file_data .get_as_text())
	file_data .close()
	return json_data .get_data()
