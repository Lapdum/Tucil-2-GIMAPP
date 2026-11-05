extends Area2D

@export_file("*.tscn") var target_scene: String

func _on_body_entered(body: Player) -> void:
	if body:
		set_deferred("monitoring", false)
		SceneManager.change_scene(target_scene)
