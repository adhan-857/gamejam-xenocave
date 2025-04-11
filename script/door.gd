extends CharacterBody2D

@onready var animplayer: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_to_disable: CollisionShape2D = $CollisionShape2D2
@onready var area: Area2D = $Area2D

var player_in_area = false
var door_sound: AudioStreamPlayer

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	door_sound = AudioStreamPlayer.new()
	door_sound.stream = load("res://assets/SFX/door.mp3")
	door_sound.volume_db = -7.5
	add_child(door_sound)

func _on_body_entered(body: Node2D):
	if body.name == "Player":
		player_in_area = true

func _on_body_exited(body: Node2D):
	if body.name == "Player":
		player_in_area = false

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("ui_interact"):
		animplayer.play("Open")
		door_sound.play()
		disable_collision_after_delay()

func disable_collision_after_delay():
	await get_tree().create_timer(1.0).timeout
	collision_to_disable.disabled = true
