extends PanelContainer

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var quantity_label: Label = $QuantityLabel


func set_slot_data(slot_data: SlotData) -> void:
	var item_data = slot_data.item_data
	texture_rect.texture = item_data.icon
	tooltip_text = "%s\n%s" % [item_data.item_name, item_data.item_description]
	
	if slot_data.quantity > 0:
		quantity_label.text = "x" + str(slot_data.quantity)
		quantity_label.show()
