extends CanvasLayer
@onready var progress_bar = $TextureProgressBar

func update_health(current: int, max: int) -> void:
	progress_bar.max_value = max
	progress_bar.value = current
