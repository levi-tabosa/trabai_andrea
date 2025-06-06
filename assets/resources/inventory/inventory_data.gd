extends Resource
class_name InventoryData

@export var slot_datas: Array[SlotData]

signal inventory_interact(inventory_data: InventoryData, index: int, button_index: int)

func on_slot_clicked(slot_index: int, button_index: int) -> void:
	inventory_interact.emit(self, slot_index, button_index)
	# Handle slot click events here
	# This function can be connected to the slot_clicked signal in inventory_slot.gd
	print("Slot clicked:", slot_index, "Button index:", button_index)
	
	# Example logic for left-click and right-click actions
	if button_index == MOUSE_BUTTON_LEFT:
		print("Left click on slot", slot_index)
	elif button_index == MOUSE_BUTTON_RIGHT:
		print("Right click on slot", slot_index)
