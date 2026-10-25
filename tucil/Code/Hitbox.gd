class_name Hitbox
extends Area2D

@export var damage: int = 10
@export var knockback: float = 300.0

@onready var shape: CollisionShape2D = $CollisionShape2D

func enable() -> void:
	shape.set_deferred("disabled", false)
	print("hitbox is on")

func disable() -> void:
	shape.set_deferred("disabled", true)
	print("hitbox is off")
