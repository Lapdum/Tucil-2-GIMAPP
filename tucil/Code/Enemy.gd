class_name Enemy
extends Entity

@export var sight: Area2D
@export var attack_range: Area2D
@export var attack_cooldown: float = 0.5
@export var lose_target_time : float = 3.0

var target: Player = null
var player_in_range: bool = false
var cooldown_left: float = 0.0
var player_in_sight: bool = false
var lose_timer: float = 0.0


func _ready() -> void:
	super()

func _physics_process(delta: float) -> void:
	cooldown_left = max(cooldown_left - delta, 0.0)

	if target and not is_instance_valid(target):
		target = null

	if target and not player_in_sight:
		lose_timer -= delta
		if lose_timer <= 0.0:
			target = null

	if is_attacking:
		velocity = Vector2.ZERO
	elif target and player_in_range:
		velocity = Vector2.ZERO
		if cooldown_left == 0.0:
			attack(direction_to_target())
		else:
			face(direction_to_target())
			play_idle()
	elif target:
		var dir := direction_to_target()
		face(dir)
		play_walk()
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
		play_idle()

	move_with_knockback(delta)


func direction_to_target() -> Vector2:
	return (target.global_position - global_position).normalized()

func _on_animation_finished(anim_name: StringName) -> void:
	var was_attacking := is_attacking
	super(anim_name)
	if was_attacking and not is_attacking:
		cooldown_left = attack_cooldown


#-----------------------------------------------
# DETECTION
#-----------------------------------------------

func _on_sight_body_entered(body: Node2D) -> void:
	if body is Player:
		target = body
		player_in_sight = true
		
func _on_sight_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_sight = false
		lose_timer = lose_target_time

func _on_hitbox_body_entered(body: Node2D) -> void:
	pass

func _on_hitbox_body_exited(body: Node2D) -> void:
	pass


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	pass # Replace with function body.


func _on_attack_range_body_entered(body: Node2D) -> void:
	print("I see something")
	if body is Player:
		player_in_range = true


func _on_attack_range_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
