extends PanelContainer

const Slot = preload("res://scenes/inventory_slot.tscn")

@onready var item_grid: GridContainer = $MarginContainer/GridContainer

func set_inventory_data(inventory_data: InventoryData) -> void:
	populate_inventory(inventory_data.slot_datas)

func populate_inventory(slot_datas: Array[SlotData]) -> void:
	for child in item_grid.get_children():
		child.queue_free()  # Free the old slots to avoid memory leaks
	for data in slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)

		if data:
			slot.set_slot_data(data)
