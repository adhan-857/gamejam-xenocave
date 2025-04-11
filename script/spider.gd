extends CharacterBody2D

@export var speed: float = 50.0
@export var detection_range: float = 150.0
@export var gravity: float = 980.0
@export var jump_force: float = -150.0
@export var damage_amount: int = 5  # Damage dealt to player
@export var damage_cooldown: float = 2.0  # Time between damage applications
@onready var animplayer: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Area2D
@onready var attack_shape: CollisionShape2D = $Area2D/CollisionShape2D2
@onready var area_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var original_collision_pos: Vector2 = Vector2.ZERO
@onready var original_area_shape_pos: Vector2 = Vector2.ZERO
@onready var original_attack_shape_pos: Vector2 = Vector2.ZERO

var player = null
var player_in_attack_range = false
var is_attacking = false
var attack_timer = 0.0
var can_attack = true
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var unstuck_direction: int = 1
var is_dying: bool = false
var damage_timer: float = 0.0  # Timer for damage frequency control
var flash_sound: AudioStreamPlayer

func _ready():
	attack_shape.disabled = true
	attack_area.body_entered.connect(_on_area_2d_body_entered)
	attack_area.body_exited.connect(_on_area_2d_body_exited)
	animplayer.animation_finished.connect(_on_animation_finished)
	animplayer.play("Walk")
	
	# Store original positions of collision shapes
	original_collision_pos = collision.position
	original_area_shape_pos = area_shape.position
	original_attack_shape_pos = attack_shape.position
	
	# Initialize last position
	last_position = global_position
	
	# Get reference to player at start
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		# Try by name if not using groups
		player = get_node("/root").find_child("Player", true, false)
		
	# Initialize flash sound spider
	flash_sound = AudioStreamPlayer.new()
	flash_sound.stream = load("res://assets/SFX/flash.mp3")
	flash_sound.volume_db = -20
	add_child(flash_sound)

func _physics_process(delta):
	# Skip logic if spider is dying
	if is_dying:
		return
		
	# Apply gravity
	velocity.y += gravity * delta
	
	if player:
		# Calculate distance and direction to player
		var distance = global_position.distance_to(player.global_position)
		var direction = sign(player.global_position.x - global_position.x)
		
		# Check for stuck condition (when on top of player)
		check_if_stuck(delta, direction)
		
		# Handle direction flip and collision shape positions
		if direction < 0:  # Facing left
			animplayer.flip_h = true
			collision.position.x = original_collision_pos.x + 7
			area_shape.position.x = original_area_shape_pos.x - 14
			attack_shape.position.x = original_attack_shape_pos.x - 14
		else:  # Facing right
			animplayer.flip_h = false
			collision.position = original_collision_pos
			area_shape.position = original_area_shape_pos
			attack_shape.position = original_attack_shape_pos
		
		# Decrement damage timer
		if damage_timer > 0:
			damage_timer -= delta
		
		# Apply continuous damage if player is in range and cooldown is complete
		if player_in_attack_range and damage_timer <= 0:
			Global.take_damage(damage_amount)
			damage_timer = damage_cooldown
			print("Player damaged! Health: ", Global.health)
		
		if is_attacking:
			# Handle attack behavior
			velocity.x = 0
			attack_timer -= delta
			if attack_timer <= 0 && can_attack:
				# Start attack
				attack_shape.disabled = false
				animplayer.play("Attack")
				can_attack = false
		else:
			# Always walk toward player when not attacking
			if distance < detection_range:  # Only chase within detection range
				velocity.x = direction * speed
				animplayer.play("Walk")
			else:
				# Optional: Spider is idle when player is too far away
				velocity.x = 0
				animplayer.play("Walk")  # Using Walk as idle
	else:
		# No player found
		velocity.x = 0
		animplayer.play("Walk")
		
		# Try to find player again
		player = get_tree().get_first_node_in_group("Player")

	# Save position for stuck detection in next frame
	last_position = global_position
	
	move_and_slide()

# Called when spider is hit by player's attack
func die():
	if is_dying:
		return  # Prevent multiple death calls
		
	is_dying = true
	velocity = Vector2.ZERO  # Stop movement
	
	# Disable collisions
	collision.set_deferred("disabled", true)
	attack_shape.set_deferred("disabled", true)
	area_shape.set_deferred("disabled", true)
	
	# Play death animation if it exists
	if animplayer.sprite_frames.has_animation("Death"):
		animplayer.play("Death")
	else:
		# If no death animation, just queue_free
		queue_free()

func check_if_stuck(delta: float, direction_to_player: int) -> void:
	# Check if we're directly above the player
	var vertical_alignment = abs(global_position.x - player.global_position.x) < 20
	var above_player = global_position.y < player.global_position.y
	
	# Check if we haven't moved much
	var not_moving = global_position.distance_to(last_position) < 1.0
	
	# Detect collision with player
	var touching_player = false
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player:
			touching_player = true
			break
	
	# Increment stuck timer if we think we're stuck
	if (vertical_alignment and above_player and not_moving) or touching_player:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
	
	# If stuck for too long, try to get unstuck
	if stuck_timer > 0.5:
		get_unstuck(direction_to_player)

func get_unstuck(direction_to_player: int) -> void:
	# Jump with slight horizontal velocity to get off the player
	velocity.y = jump_force
	
	# Choose a direction to jump (alternate sides if still stuck)
	unstuck_direction = -unstuck_direction
	velocity.x = unstuck_direction * speed * 1.5
	
	# Reset stuck timer
	stuck_timer = 0.0

# Area2D is now used only for attack range detection
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		print("Player entered attack range")
		player_in_attack_range = true
		is_attacking = true
		attack_timer = 1.0
		can_attack = true
		flash_sound.play()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		print("Player left attack range")
		player_in_attack_range = false
		is_attacking = false
		attack_shape.disabled = true

func _on_animation_finished():
	if animplayer.animation == "Death":
		# Remove spider after death animation completes
		queue_free()
	elif animplayer.animation == "Attack":
		attack_shape.disabled = true
		is_attacking = false
		
		# Start another attack cycle if player is still in range
		if player_in_attack_range:
			is_attacking = true
			attack_timer = 1.0
			can_attack = true
			flash_sound.play()
