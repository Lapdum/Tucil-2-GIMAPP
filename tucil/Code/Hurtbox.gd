class_name Hurtbox
extends Area2D

signal hurt(hitbox: Hitbox)

@export var health: HealthComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		health.take_damage(area.damage)
		hurt.emit(area)
