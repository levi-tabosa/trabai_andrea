extends Control

var grabbed_slot_data: SlotData

@onready var player_inventory: PanelContainer = $HBoxContainer/PlayerInventory
@onready var grabbed_slot: PanelContainer = $HBoxContainer/Slot

func _physics_process(_delta: float) -> void:	
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(4, 4)

func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func on_inventory_interact(inventory_data: InventoryData, index: int, button_index: int) -> void:
	match [grabbed_slot_data, button_index]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
			print("Grabbed slot data:", grabbed_slot_data)
		[null, MOUSE_BUTTON_RIGHT]:
			print("Right-click on slot index:", index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
			print(grabbed_slot_data == null)
	update_grabbed_slot()

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.set_slot_data(grabbed_slot_data)
		grabbed_slot.show()
	else:
		grabbed_slot.hide()
