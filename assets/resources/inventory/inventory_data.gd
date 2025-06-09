extends Resource
class_name InventoryData

@export var slot_datas: Array[SlotData]

signal inventory_update(inventory_data: InventoryData)
signal inventory_interact(inventory_data: InventoryData, index: int, button_index: int)

func on_slot_clicked(slot_index: int, button_index: int) -> void:
	inventory_interact.emit(self, slot_index, button_index)
	print("Slot clicked:", slot_index, "Button index:", button_index)
	
func grab_slot_data(slot_index: int) -> SlotData:
	var grabbed_slot_data = slot_datas[slot_index]
	if grabbed_slot_data:
		slot_datas[slot_index] = null
		inventory_update.emit(self)
	return grabbed_slot_data

func drop_slot_data(grabbed_slot_data: SlotData, slot_index: int) -> SlotData:
	var slot_data = slot_datas[slot_index]

	var returned_slot_data: SlotData = null
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	else:
		slot_datas[slot_index] = grabbed_slot_data
		returned_slot_data = slot_data
	
	inventory_update.emit(self)
	return returned_slot_data
