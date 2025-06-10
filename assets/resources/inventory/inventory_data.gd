extends Resource
class_name InventoryData

@export var slot_datas: Array[SlotData]

signal inventory_interact(inventory_data: InventoryData, index: int, button_index: int)
signal inventory_update(inventory_data: InventoryData)


func on_slot_clicked(slot_index: int, button_index: int) -> void:
	inventory_interact.emit(self, slot_index, button_index)

func grab_slot_data(slot_index: int) -> SlotData:
	var slot_data = slot_datas[slot_index]
	if slot_data: 
		# slot_datas[slot_index].quantity -= 1
		# inventory_update.emit(self)
		return slot_data
	return null

func drop_slot_data(slot_data: SlotData, slot_index: int) -> SlotData:
	return null
