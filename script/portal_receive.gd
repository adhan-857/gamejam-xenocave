extends CharacterBody2D

@onready var anim_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
var warp_timer: Timer
var teleport_timer: Timer
var is_warping = false
var current_player = null
var has_been_activated = false

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
	add_child(teleport_timer)

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Only trigger once, ever
	if (body.name == "Player" or body.is_in_group("Player")) and not has_been_activated:
		has_been_activated = true
		current_player = body
		
		# Immediately disable area to prevent further detection
		detection_area.monitoring = false
		detection_area.monitorable = false
		
		# Start warp sequence
		is_warping = true
		warp_timer.start()

func _on_area_2d_body_exited(body: Node2D) -> void:
	# This function won't be called anymore after area is disabled
	pass

func _on_warp_timer_timeout() -> void:
	anim_player.play("Warp")
	teleport_timer.start()

func _on_animation_finished():
	if anim_player.animation == "Warp":
		anim_player.play("idle")
		is_warping = false
		current_player = null
