extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	hide()

func change_scene(path: String) -> void:
	show()
	await 1
	print("play")
	anim.play("rev_transition")
	await anim.animation_finished
	await 1
	get_tree().change_scene_to_file(path)
	anim.play("transition")
	await 1
	hide()
	
