class_name Player
extends Entity
 
const ATTACK_BUFFER: float = 0.15
 
@export var sword_slash: AudioStream
 
@onready var sfx_player: AudioStreamPlayer2D = $sfx_player
 
var attack_buffer: float = 0.0
var last_x: float = -1.0
var last_y: float = 0.0
 
func _physics_process(delta: float) -> void:
	update_last_pressed()
	handle_attack_input(delta)
	handle_movement()
	move_with_knockback(delta)
 
 
#-----------------------------------------------
# INPUT
#-----------------------------------------------
 
func get_input_vector() -> Vector2:
	return Vector2(
		resolve_axis("left", "right", last_x),
		resolve_axis("forward", "backward", last_y)
	).normalized()
 
 
func update_last_pressed() -> void:
	if Input.is_action_just_pressed("left"):
		last_x = -1.0
	if Input.is_action_just_pressed("right"):
		last_x = 1.0
	if Input.is_action_just_pressed("forward"):
		last_y = -1.0
	if Input.is_action_just_pressed("backward"):
		last_y = 1.0
 
 
func resolve_axis(negative: String, positive: String, last: float) -> float:
	var neg_held := Input.is_action_pressed(negative)
	var pos_held := Input.is_action_pressed(positive)
	if neg_held and pos_held:
		return last
	if neg_held:
		return -1.0
	if pos_held:
		return 1.0
	return 0.0
 
 
#-----------------------------------------------
# MOVEMENT
#-----------------------------------------------
 
func handle_movement() -> void:
	if is_attacking:
		velocity = Vector2.ZERO
		return
 
	var input := get_input_vector()
	if input != Vector2.ZERO:
		face(input)
		play_walk()
	else:
		play_idle()
 
	velocity = input * speed
 
 
#-----------------------------------------------
# ATTACK
#-----------------------------------------------
 
func handle_attack_input(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		attack_buffer = ATTACK_BUFFER
	else:
		attack_buffer = max(attack_buffer - delta, 0.0)
		
	if is_attacking:
		return
 
	if attack_buffer > 0.0:
		attack_buffer = 0.0
		attack(get_input_vector())
 
func _on_attack_started() -> void:
	play_sfx(sword_slash)
 
func play_sfx(stream: AudioStream) -> void:
	if sfx_player.stream != stream:
		sfx_player.stop()
		sfx_player.stream = stream
	sfx_player.play()
 
#-----------------------------------------------
# DEATH
#-----------------------------------------------
 
func die() -> void:
	get_tree().reload_current_scene()
 
func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	pass # Replace with function body.
