class_name Entity
extends CharacterBody2D

@export var speed : float
@export var anim_tree : AnimationTree
@export var health : HealthComponent
@export var hitbox : Hitbox
@export var hitbox_pivot : Node2D

@export_group("Animation")
@export var idle_state : StringName = &"Idle"
@export var walk_state : StringName = &"Walk"
@export var attack_state : StringName = &"Attack"
@export var attack_anim_prefix : StringName = "Attack"
@export var hurtbox: Hurtbox
@export var knockback_friction: float = 1500.0

var knockback_velocity: Vector2 = Vector2.ZERO
var state_machine: AnimationNodeStateMachinePlayback
var direction_facing: Vector2 = Vector2.DOWN
var is_attacking: bool = false

func _ready() -> void:
	state_machine = anim_tree.get("parameters/playback")
	anim_tree.animation_finished.connect(_on_animation_finished)
	if health:
		health.died.connect(die)
	if hitbox:
		hitbox.disable()
		
#-----------------------------------------------
# FACING & ANIMATION
#-----------------------------------------------

func face(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	direction_facing = dir.normalized()
	_set_blend(idle_state)
	_set_blend(walk_state)
	_set_blend(attack_state)
	if hitbox_pivot:
		hitbox_pivot.rotation = direction_facing.angle()
 
func _set_blend(state: StringName) -> void:
	anim_tree.set("parameters/%s/blend_position" % state, direction_facing)
 
func play_idle() -> void:
	state_machine.travel(idle_state)
 
func play_walk() -> void:
	state_machine.travel(walk_state)
 
#-----------------------------------------------
# ATTACK
#-----------------------------------------------
 
func attack(dir: Vector2 = Vector2.ZERO) -> void:
	if is_attacking:
		return
	is_attacking = true
	face(dir)
	state_machine.start(attack_state)
	_on_attack_started()
	
func _on_attack_started() -> void:
	pass

func enable_hitbox() -> void:
	if hitbox:
		hitbox.enable()

func disable_hitbox() -> void:
	if hitbox:
		hitbox.disable()
 
func _on_animation_finished(anim_name: StringName) -> void:
	if String(anim_name).begins_with(attack_anim_prefix):
		is_attacking = false
		disable_hitbox()
 
func _on_hurt(hitbox: Hitbox) -> void:
	var source := hitbox.owner as Node2D
	var from: Vector2 = source.global_position if source else hitbox.global_position
	var dir := (global_position - from).normalized()
	knockback_velocity = dir * hitbox.knockback

func move_with_knockback(delta: float) -> void:
	velocity += knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
 
#-----------------------------------------------
# DEATH
#-----------------------------------------------

func die() -> void:
	queue_free()
