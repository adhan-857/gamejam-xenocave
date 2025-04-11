extends CharacterBody2D

@export var gravity = 750.0
@export var walk_speed = 100
@export var jump_speed = -250
@export var normal_scale = Vector2(1, 1)
@export var normal_offset = Vector2(0, 0)

@onready var animplayer : AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var attack_area : Area2D = $Area2D
@onready var attack_collision : CollisionShape2D = $Area2D/CollisionShape2D
@onready var original_attack_collision_pos : Vector2 = Vector2.ZERO

var is_dashing = false
var dash_timer = 0.0
var last_press_time = {}
var double_press_threshold = 0.5
var jump_count = 0
var was_in_air = false
var is_firing = false
var attack_active_timer = 0.0
var fire_sound: AudioStreamPlayer

func _ready():
	last_press_time["ui_left"] = 0
	last_press_time["ui_right"] = 0
	anim_set("Idle")
	
	# Connect the animation finished signal
	animplayer.animation_finished.connect(_on_animation_finished)
	
	# Connect the attack area signal
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	# Store original attack collision position
	if attack_collision:
		original_attack_collision_pos = attack_collision.position
		# Disable attack collision by default
		attack_collision.disabled = true
		
	# Initialize warp sound player
	fire_sound = AudioStreamPlayer.new()
	fire_sound.stream = load("res://assets/SFX/flamethrower.mp3")
	fire_sound.volume_db = -15
	add_child(fire_sound)

func _physics_process(delta):
	var move_dir = 0
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Handle attack collision timer
	if attack_active_timer > 0:
		attack_active_timer -= delta
		if attack_active_timer <= 0:
			# Time is up, disable the attack collision
			if attack_collision:
				attack_collision.disabled = true

	# Deteksi spacebar untuk Fire
	if Input.is_action_just_pressed("ui_select") and not is_firing:  # spacebar
		if Global.fuel >= 10:
			# Consume fuel
			Global.consume_fuel(10)
			anim_set("Fire")
			is_firing = true
			fire_sound.play()
			
			# Enable attack collision and start timer
			if attack_collision:
				attack_collision.disabled = false
				attack_active_timer = 1.875
				
			# Stop movement when starting to fire
			velocity.x = 0

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		was_in_air = true  

	# Mendarat dari lompat
	if is_on_floor() and was_in_air:
		was_in_air = false  
		if animplayer.animation == "jump" and not is_firing:
			anim_set("Idle")

	# Reset jump saat nyentuh tanah
	if is_on_floor():
		jump_count = 0

	# Lompat & double jump - dinonaktifkan saat firing
	if not is_firing:
		if is_on_floor() and Input.is_action_just_pressed("ui_up"):
			velocity.y = jump_speed
			jump_count = 1
			anim_set("jump")
		elif jump_count == 1 and !is_on_floor() and Input.is_action_just_pressed("ui_up"):
			velocity.y = jump_speed
			jump_count = 2
			anim_set("jump")

	# Kalau lagi dash atau firing, skip input gerak
	if is_dashing or is_firing:
		if is_dashing:
			dash_timer -= delta
			if dash_timer <= 0:
				is_dashing = false
		move_and_slide()
		return

	# Deteksi arah gerak (pressed) - dinonaktifkan saat firing
	if Input.is_action_pressed("ui_left"):
		move_dir = -1
		animplayer.flip_h = true
		# Adjust attack collision position when facing left
		if attack_collision:
			attack_collision.position.x = original_attack_collision_pos.x - 74
	elif Input.is_action_pressed("ui_right"):
		move_dir = 1
		animplayer.flip_h = false
		# Reset attack collision to original position when facing right
		if attack_collision:
			attack_collision.position.x = original_attack_collision_pos.x

	# Double tap dash (just_pressed) - dinonaktifkan saat firing
	if Input.is_action_just_pressed("ui_left"):
		if current_time - last_press_time.get("ui_left", 0) <= double_press_threshold:
			start_dash(-1)
		last_press_time["ui_left"] = current_time
	elif Input.is_action_just_pressed("ui_right"):
		if current_time - last_press_time.get("ui_right", 0) <= double_press_threshold:
			start_dash(1)
		last_press_time["ui_right"] = current_time

	# Animasi: Idle kalau diem, Walk kalau gerak
	if is_on_floor() and not is_dashing and animplayer.animation != "jump" and not is_firing:
		if move_dir == 0:
			anim_set("Idle")
		else:
			anim_set("Walk")

	# Gerak horizontal - dinonaktifkan saat firing
	velocity.x = move_dir * walk_speed

	# Apply gravity dan gerak
	move_and_slide()

# New function - check for enemies in the attack area
func _on_attack_area_body_entered(body: Node2D) -> void:
	var name = body.name.to_lower()

	if (
		name.find("spider") >= 0 or
		name.find("flower") >= 0 or
		name.find("troopbot") >= 0 or
		name.find("boss") >= 0
	):
		if body.has_method("die"):
			body.die()

func _on_animation_finished():
	# Cek apakah animasi Fire sudah selesai
	if is_firing and animplayer.animation == "Fire":
		is_firing = false
		
		# Pilih animasi yang tepat setelah Fire selesai
		if not is_on_floor():
			anim_set("jump")
		elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			anim_set("Walk")
		else:
			anim_set("Idle")

func start_dash(direction):
	# Prevent dashing during firing
	if is_firing:
		return
		
	is_dashing = true
	dash_timer = 0.3
	velocity.x = direction * walk_speed * 1.5
	anim_set("dash")

func anim_set(animation):
	if animplayer.animation != animation:
		animplayer.play(animation)
		
	# Set offset for Fire animation based on direction
	if animation == "Fire":
		if animplayer.flip_h:  # Facing left
			animplayer.offset.x = -22
		else:  # Facing right
			animplayer.offset.x = 20
	else:
		animplayer.offset = normal_offset
