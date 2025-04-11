extends CharacterBody2D

@onready var anim_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
var warp_timer: Timer
var teleport_timer: Timer
var player_in_area = false
var is_warping = false
var current_player = null
var portal_used = false

func _ready() -> void:
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
	
	# Set initial animation based on boss status
	update_portal_state()

func _process(delta: float) -> void:
	# Update portal animation if boss status changed
	update_portal_state()
	
	# Only allow interaction if boss is defeated
	if player_in_area and not is_warping and Input.is_action_just_pressed("ui_interact") and not portal_used and Global.boss_defeated:
		is_warping = true
		warp_timer.start()

func update_portal_state() -> void:
	# Change animation based on boss status
	if Global.boss_defeated and anim_player.animation == "NotYet":
		anim_player.play("idle")
	elif not Global.boss_defeated and anim_player.animation != "NotYet":
		anim_player.play("NotYet")

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
	# Only proceed with warping if boss is defeated
	if Global.boss_defeated:
		anim_player.play("Warp")
		teleport_timer.start()
	else:
		is_warping = false

func _on_teleport_timer_timeout() -> void:
	if current_player and Global.boss_defeated:
		# Change to WinScreen scene instead of teleporting player
		get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
		
		# Mark portal as used
		portal_used = true
		
		# Disable Area2D to prevent future detection (this won't matter after scene change)
		if detection_area:
			detection_area.monitoring = false
			detection_area.monitorable = false

func _on_animation_finished():
	if anim_player.animation == "Warp":
		if Global.boss_defeated:
			anim_player.play("Idle")
		else:
			anim_player.play("NotYet")
		is_warping = false
