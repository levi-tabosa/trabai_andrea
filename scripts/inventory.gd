extends Node
var inventory = []

func add_item(item_name, item_icon, item_quantity):
	for item in inventory:
		if item["name"] == item_name:
			item["quantity"] += item_quantity
			return
	inventory.append({
		"name": item_name,
		"icon": item_icon,
		"quantity": item_quantity
	})

func remove_item(item_name, item_quantity):
	for i in range(inventory.size()):
		if inventory[i]["name"] == item_name:
			inventory[i]["quantity"] -= item_quantity
			if inventory[i]["quantity"] <= 0:
				inventory.remove_at(i)
			return
