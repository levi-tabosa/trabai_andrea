extends Control

var grabbed_slot_data: SlotData

@onready var player_inventory: PanelContainer = $HBoxContainer/PlayerInventory
@onready var grabbed_slot: PanelContainer = $HBoxContainer/Slot

func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func on_inventory_interact(inventory_data: InventoryData, index: int, button_index: int) -> void:
	match [grabbed_slot_data, button_index]:
		[null, MOUSE_BUTTON_LEFT]:
			# Handle left-click interaction
			grabbed_slot_data = inventory_data.grab_slot_data(index)
			print("Grabbed slot data:", grabbed_slot_data)
		[null, MOUSE_BUTTON_RIGHT]:
			# Handle right-click interaction
			print("Right-click on slot index:", index)
		[_, _]:
			# Handle other interactions, e.g., dropping or using the item
			print("Dropping or using item:", grabbed_slot_data)
			grabbed_slot_data = null  # Clear grabbed data after use
	# Handle inventory interaction here
	print("Inventory interact:", inventory_data, "Index:", index, "Button index:", button_index)
	update_grabbed_slot()

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.set_slot_data(grabbed_slot_data)
		grabbed_slot.show()
		print("Showing grabbed slot data:", grabbed_slot_data)
	else:
		print("No slot data to show", grabbed_slot_data)
		grabbed_slot.hide()
