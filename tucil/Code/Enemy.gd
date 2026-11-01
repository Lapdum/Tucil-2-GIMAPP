class_name Enemy
extends Entity

@export var sight: Area2D
@export var los_ray: RayCast2D
@export var attack_range: Area2D
@export var attack_cooldown: float = 0.5
@export var lose_target_time : float = 3.0
@export var vision_angle: float = 90.0
@export var vision_cone: Node2D
@export_group("Idle Vision")
@export var idle_scan_angle: float = 45.0
@export var idle_scan_speed: float = 1.0


var target: Player = null
var player_in_range: bool = false
var cooldown_left: float = 0.0
var player_in_sight: bool = false
var lose_timer: float = 0.0
var scan_time: float = 0.0

func _ready() -> void:
	super()

func _physics_process(delta: float) -> void:
	cooldown_left = max(cooldown_left - delta, 0.0)
	find_player_in_sight()
	if target and not is_instance_valid(target):
		target = null

	if target and is_instance_valid(target):
		player_in_sight = can_see_target()
		if player_in_sight:
			lose_timer = lose_target_time
		else:
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
	elif target and player_in_sight:
		var dir := direction_to_target()
		face(dir)
		play_walk()
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
		play_idle()

	move_with_knockback(delta)
	
	if vision_cone:
		if player_in_sight:
			vision_cone.rotation = direction_facing.angle()
		else:
			scan_time += delta * idle_scan_speed
			
			var scan_offset: float = deg_to_rad(idle_scan_angle) * sin(scan_time)
			vision_cone.rotation = direction_facing.angle() + scan_offset

func direction_to_target() -> Vector2:
	return (target.global_position - global_position).normalized()

func is_target_in_vision_cone() -> bool:
	if not is_instance_valid(target):
		return false
	
	var dir_to_target : Vector2 = direction_to_target()
	var angle_to_target : float = abs(rad_to_deg(direction_facing.angle_to(dir_to_target)))
	return angle_to_target <= vision_angle / 2.0
	
func can_see_target() -> bool:
	if not is_instance_valid(target):
		return false
		
	los_ray.target_position = los_ray.to_local(target.global_position)
	los_ray.force_raycast_update()
	
	if not is_target_in_vision_cone():
		return false
	
	if not los_ray.is_colliding():
		return false
	return los_ray.get_collider() == target
	
func _on_animation_finished(anim_name: StringName) -> void:
	var was_attacking := is_attacking
	super(anim_name)
	if was_attacking and not is_attacking:
		cooldown_left = attack_cooldown

func find_player_in_sight() -> void:
	if is_instance_valid(target):
		return
	for body in sight.get_overlapping_bodies():
		if body is Player:
			target = body
			lose_timer = lose_target_time
			break

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
