extends CharacterBody2D

@export var speed: float = 50.0
@export var detection_range: float = 250.0
@export var gravity: float = 980.0
@export var damage_amount: int = 4  # Damage dealt to player
@export var damage_cooldown: float = 3  # Time between damage applications
@export var max_hit_points: int = 10  # Number of hits Boss can take before dying

@onready var animplayer: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Area2D
@onready var attack_shape: CollisionShape2D = $Area2D/CollisionShape2D2
@onready var area_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var original_collision_pos: Vector2 = Vector2.ZERO
@onready var original_attack_shape_pos: Vector2 = Vector2.ZERO
@onready var original_area_shape_pos: Vector2 = Vector2.ZERO
@onready var original_offset: Vector2 = Vector2.ZERO
@onready var boss_bar = $BossBar

var player = null
var player_in_attack_range = false
var is_attacking = false
var attack_timer = 0.0
var can_attack = true
var is_dying = false
var damage_timer: float = 0.0  # Timer for damage frequency control
var hit_points: int = 0  # Current hit points
var death_delay_timer: float = 0.0  # Timer for death animation delay
var saber_sound: AudioStreamPlayer
var saber_sound_timer: Timer
var defeat_sound: AudioStreamPlayer

func _ready():
	# Initialize hit points
	hit_points = max_hit_points
	
	# Initialize boss bar
	if boss_bar:
		boss_bar.max_value = max_hit_points
		boss_bar.value = hit_points
	
	attack_shape.disabled = true
	attack_area.body_entered.connect(_on_area_2d_body_entered)
	attack_area.body_exited.connect(_on_area_2d_body_exited)
	
	# Make sure the animation_finished signal is properly connected
	if not animplayer.animation_finished.is_connected(_on_animation_finished):
		animplayer.animation_finished.connect(_on_animation_finished)
	
	# Default animation is Idle
	animplayer.play("Idle")
	
	# Store original positions for later adjustment
	original_collision_pos = collision.position
	original_attack_shape_pos = attack_shape.position
	original_area_shape_pos = area_shape.position
	original_offset = animplayer.offset
	
	# Get reference to player at start
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		player = get_node("/root").find_child("Player", true, false)
	
	print("Boss initialized, player reference: ", player)
	
	# Initialize saber sound boss
	saber_sound = AudioStreamPlayer.new()
	saber_sound.stream = load("res://assets/SFX/saber.mp3")
	saber_sound.volume_db = -17.5
	add_child(saber_sound)
	
	# Create saber sound timer
	saber_sound_timer = Timer.new()
	saber_sound_timer.wait_time = 1.75
	saber_sound_timer.one_shot = false
	saber_sound_timer.connect("timeout", _on_saber_sound_timer_timeout)
	add_child(saber_sound_timer)
	
	# Initialize defeat sound boss
	defeat_sound = AudioStreamPlayer.new()
	defeat_sound.stream = load("res://assets/SFX/defeat.mp3")
	defeat_sound.volume_db = -17.5
	add_child(defeat_sound)

func _on_saber_sound_timer_timeout():
	if player_in_attack_range:
		saber_sound.play()

func _physics_process(delta):
	# Handle death delay timer
	if is_dying and death_delay_timer > 0:
		death_delay_timer -= delta
		if death_delay_timer <= 0:
			# Now play the death animation after delay
			if animplayer.sprite_frames.has_animation("Death"):
				print("Playing Death animation after delay")
				animplayer.play("Death")
				defeat_sound.play()
			else:
				print("No Death animation found, removing after delay")
				queue_free()
		return
		
	# Skip further logic if Boss is dying
	if is_dying:
		return
		
	# Apply gravity regardless of other states
	velocity.y += gravity * delta
	
	# Handle damage timer
	if damage_timer > 0:
		damage_timer -= delta
		
	# Apply damage if player is in attack range and cooldown is complete
	if player_in_attack_range and damage_timer <= 0:
		Global.take_damage(damage_amount)
		damage_timer = damage_cooldown
		print("Player damaged by Boss! Health: ", Global.health)
	
	if player:
		# Calculate distance to player
		var distance = global_position.distance_to(player.global_position)
		
		# Only chase if player is within detection range
		if distance <= detection_range:
			# Calculate direction to player
			var direction = sign(player.global_position.x - global_position.x)
			
			# Handle direction and flip
			if direction < 0:  # Facing left
				animplayer.flip_h = true
				area_shape.position.x = original_area_shape_pos.x - 46
				attack_shape.position.x = original_attack_shape_pos.x - 46
			else:  # Facing right
				animplayer.flip_h = false
				area_shape.position = original_area_shape_pos
				attack_shape.position = original_attack_shape_pos
			
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
				velocity.x = direction * speed
				animplayer.play("Walk")
				print("Moving toward player, velocity.x: ", velocity.x)
		else:
			# Player out of detection range, stay idle
			velocity.x = 0
			animplayer.play("Idle")
	else:
		# No player found, still apply gravity but stop horizontal movement
		velocity.x = 0
		animplayer.play("Idle")
		
		# Try to find player again
		player = get_tree().get_first_node_in_group("Player")
		if player == null:
			player = get_node("/root").find_child("Player", true, false)

	move_and_slide()

# Called when Boss is hit by player's attack
func die():
	# Reduce hit points when hit
	hit_points -= 1
	print("Boss hit! Hit points remaining: ", hit_points)

	# Update boss bar
	if boss_bar:
		boss_bar.value = hit_points
	
	# Only die if hit points are depleted
	if hit_points <= 0:
		if is_dying:
			return  # Prevent multiple death calls
			
		print("Boss die() called - no more hit points")
		is_dying = true
		velocity = Vector2.ZERO  # Stop movement
		
		# Set the global boss_defeated variable
		Global.boss_defeated = true
		print("Boss defeated! Portal activated.")
		
		# Disable collisions
		collision.set_deferred("disabled", true)
		attack_shape.set_deferred("disabled", true)
		area_shape.set_deferred("disabled", true)
		
		# First play hit/stun animation or just pause before death
		animplayer.play("Idle")  # Use Idle as a temporary "stunned" state
		
		# Set the death delay timer
		death_delay_timer = 0.3  # 0.3 second delay before death animation
		print("Death delay timer started: 0.3 seconds")
		
		# The actual death animation will play when the timer runs out
	else:
		# Optional: play a "hit" animation or flash effect to show damage
		print("Boss was hit but survived")

# Handle animation finished
func _on_animation_finished():
	print("Animation finished: ", animplayer.animation)
	
	if animplayer.animation == "Death":
		print("Death animation finished, removing Boss")
		queue_free()
		
	elif animplayer.animation == "Attack":
		attack_shape.disabled = true
		is_attacking = false
		
		# Start another attack cycle if player is still in range
		if player_in_attack_range:
			is_attacking = true
			attack_timer = 1.0
			can_attack = true
		else:
			# Return to walking if not in attack range
			animplayer.play("Walk")

# Area2D is used for attack range detection
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		print("Player entered Boss attack range")
		player_in_attack_range = true
		is_attacking = true
		attack_timer = 1.0
		can_attack = true
		
		# Start the timer
		saber_sound_timer.start()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		print("Player left Boss attack range")
		player_in_attack_range = false
		is_attacking = false
		attack_shape.disabled = true
		
		# Stop the timer
		saber_sound_timer.stop()
		
		# Stop the laser sound when player exits
		saber_sound.stop()
		
		# Return to walking when player exits attack range (if not dying)
		if not is_dying:
			animplayer.play("Walk")
