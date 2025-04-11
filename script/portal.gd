extends CharacterBody2D

@onready var anim_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
var warp_timer: Timer
var teleport_timer: Timer
var player_in_area = false
var is_warping = false
var current_player = null
var portal_used = false
var warp_sound: AudioStreamPlayer

func _ready() -> void:
	anim_player.play("idle")
	anim_player.animation_finished.connect(_on_animation_finished)
	
	warp_timer = Timer.new()
	warp_timer.one_shot = true
	warp_timer.wait_time = 0.5
	warp_timer.timeout.connect(_on_warp_timer_timeout)
	add_child(warp_timer)
	
	teleport_timer = Timer.new()
	teleport_timer.one_shot = true
	teleport_timer.wait_time = 0.5
	teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	add_child(teleport_timer)
	
	# Initialize warp sound player
	warp_sound = AudioStreamPlayer.new()
	warp_sound.stream = load("res://assets/SFX/warp.mp3")
	warp_sound.volume_db = -10
	add_child(warp_sound)

func _process(delta: float) -> void:
	if player_in_area and not is_warping and Input.is_action_just_pressed("ui_interact") and not portal_used:
		is_warping = true
		warp_timer.start()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("Player"):
		if not portal_used:
			player_in_area = true
			current_player = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("Player"):
		player_in_area = false
		
		if warp_timer.time_left > 0:
			warp_timer.stop()
			is_warping = false
		
		if teleport_timer.time_left > 0:
			teleport_timer.stop()
			
		if not is_warping:
			current_player = null

func _on_warp_timer_timeout() -> void:
	anim_player.play("Warp")
	warp_sound.play()
	teleport_timer.start()

func _on_teleport_timer_timeout() -> void:
	if current_player:
		current_player.global_position = Vector2(343, 3)
		# Mark portal as used after teleporting
		portal_used = true
		
		# Disable Area2D to prevent future detection
		if detection_area:
			detection_area.monitoring = false
			detection_area.monitorable = false

func _on_animation_finished():
	if anim_player.animation == "Warp":
		anim_player.play("idle")
		is_warping = false
