extends Area2D

var items_in_range: Dictionary = {}
var crystals_in_range: Dictionary = {}

func _ready():
	pass

func _on_body_entered(body):
	if body.is_in_group("item_drop") and is_instance_valid(body):
		body.pick_up_item(get_parent())
		items_in_range[body.get_instance_id()] = body
	
	if body.is_in_group("crystals") and is_instance_valid(body):
		body.pick_up(get_parent())
		crystals_in_range[body.get_instance_id()] = body

func _on_body_exited(body):
	if items_in_range.has(body.get_instance_id()):
		items_in_range.erase(body.get_instance_id())
	
	if crystals_in_range.has(body.get_instance_id()):
		crystals_in_range.erase(body.get_instance_id())
