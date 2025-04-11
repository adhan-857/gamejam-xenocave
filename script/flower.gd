extends CharacterBody2D

@onready var anim_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: CollisionShape2D = $Area2D/CollisionShape2D2
@onready var detect_area: Area2D = $Area2D

@export var damage_amount: int = 2  # Damage dealt to player
@export var damage_cooldown: float = 1.5  # Time between damage applications

var player: Node2D = null
var player_in_attack_range: bool = false
var is_dying: bool = false
var damage_timer: float = 0.0  # Timer for damage frequency control
var gas_sound: AudioStreamPlayer

func _ready() -> void:
	# Start with "Idle" animation
	anim_player.play("Idle")
	
	# Disable attack hitbox by default
	attack_hitbox.disabled = true
	
	# Connect signals from Area2D
	detect_area.body_entered.connect(_on_area_2d_body_entered)
	detect_area.body_exited.connect(_on_area_2d_body_exited)
	
	# Always connect the animation finished signal
	anim_player.animation_finished.connect(_on_animation_finished)
	
	# Get reference to player at start - following Spider's approach
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		# Try by name if not using groups
		player = get_node("/root").find_child("Player", true, false)
	
	print("Flower initialized, player reference: ", player)
	
	# Initialize gas sound flower
	gas_sound = AudioStreamPlayer.new()
	gas_sound.stream = load("res://assets/SFX/gas.mp3")
	gas_sound.volume_db = -20
	add_child(gas_sound)

func _process(delta: float) -> void:
	# Skip processing if dying
	if is_dying:
		return
		
	# Update Flower direction based on Player position
	if player:
		if player.global_position.x < global_position.x:
			anim_player.flip_h = true
		else:
			anim_player.flip_h = false

func _physics_process(delta: float) -> void:
	# Skip physics if dying
	if is_dying:
		return
		
	# Handle damage timer
	if damage_timer > 0:
		damage_timer -= delta
		
	# Apply damage if player is in attack range and cooldown is complete
	# KEY FIX: This is how Spider does it and it works
	if player_in_attack_range and damage_timer <= 0:
		Global.take_damage(damage_amount)
		damage_timer = damage_cooldown
		print("Player damaged by Flower! Health: ", Global.health)

# Called when Flower is hit by player's attack
func die():
	if is_dying:
		return  # Prevent multiple death calls
		
	is_dying = true
	
	# Disable collisions and hitbox
	attack_hitbox.set_deferred("disabled", true)
	
	# Play death animation if it exists, otherwise just remove
	if anim_player.sprite_frames.has_animation("Death"):
		anim_player.play("Death")
	else:
		# If no death animation, just queue_free
		queue_free()

# Called when a body enters the Area2D
func _on_area_2d_body_entered(body: Node2D) -> void:
	# KEY FIX: Using the same pattern as Spider for consistency
	if body == player:
		print("Player entered flower attack range")
		player_in_attack_range = true
		
		# Play Attack animation
		anim_player.play("Attack")

		# Make gas sound loop and play continuously
		gas_sound.stream.loop = true
		gas_sound.play()
		
		# Enable attack hitbox
		attack_hitbox.disabled = false

# Called when a body exits the Area2D
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		print("Player left flower attack range")
		player_in_attack_range = false
		
		# Return to Idle animation
		anim_player.play("Idle")

		# Stop the gas sound when player exits
		gas_sound.stop()

		# Disable attack hitbox
		attack_hitbox.disabled = true

# Handle animation finished
func _on_animation_finished() -> void:
	if is_dying and anim_player.animation == "Death":
		queue_free()
