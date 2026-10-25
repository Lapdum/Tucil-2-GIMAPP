class_name HealthBar
extends TextureProgressBar

@export var health: HealthComponent

func _ready() -> void:
	max_value = health.max_health
	value = health.max_health
	health.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, maximum: int) -> void:
	max_value = maximum
	value = current
