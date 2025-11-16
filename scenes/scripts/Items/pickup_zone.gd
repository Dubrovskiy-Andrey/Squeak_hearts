extends Area2D

const ItemDrop = preload("res://scenes/scripts/Items/item_drop.gd")

var items_in_range = {}

func _on_body_entered(body):
	if body is ItemDrop:
		items_in_range[body] = body

func _on_body_exited(body):
	if items_in_range.has(body):
		items_in_range.erase(body)
