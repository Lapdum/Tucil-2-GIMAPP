extends Node2D

@export var vision_angle: float = 90.0
@export var vision_range: float = 90.0
@export var segments: int = 24

func _draw() -> void:
	var points := PackedVector2Array([Vector2.ZERO])
	var half_angle := deg_to_rad(vision_angle / 2.0)
	
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle : float = lerp(-half_angle, half_angle, t)
		points.append(Vector2(cos(angle) * vision_range, sin(angle) * vision_range))
	
	draw_colored_polygon(points, Color(1.0, 0.65, 0.0, 0.20))
