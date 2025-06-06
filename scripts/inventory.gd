extends PanelContainer

const Slot = preload("res://scenes/inventory_slot.tscn")

@onready var item_grid: GridContainer = $MarginContainer/GridContainer

func set_inventory_data(inventory_data: InventoryData) -> void:
	populate_inventory(inventory_data)

func populate_inventory(inventory_data: InventoryData) -> void:
	for child in item_grid.get_children():
		child.queue_free()  # Free the old slots to avoid memory leaks
	for data in inventory_data.slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)

		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		if data:
			slot.set_slot_data(data)
