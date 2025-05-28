extends Node

var health = 100
var max_health = 100
var health_regeneration_rate = 0.175  # Health points per second

var fuel = 100
var max_fuel = 100
var fuel_regeneration_rate = 0.75  # Fuel points per second

var boss_defeated = false
var main_camera = null  # Referensi ke kamera utama

func reset_game_state():
	health = max_health
	fuel = max_fuel
	boss_defeated = false

func consume_fuel(amount):
	fuel = max(0, fuel - amount)
	return fuel > 0  # Returns true if fuel still available

func regenerate_fuel(delta):
	if fuel < max_fuel:
		fuel = min(fuel + fuel_regeneration_rate * delta, max_fuel)
		
# New function for health regeneration
func regenerate_health(delta):
	if health < max_health:
		health = min(health + health_regeneration_rate * delta, max_health)

# Modified to include camera shake		
func take_damage(amount):
	health = max(0, health - amount)
	
	# Trigger camera shake if camera reference exists
	if main_camera != null and main_camera.has_method("shake"):
		# Parameter: durasi shake (detik), kekuatan shake
		main_camera.shake(0.2, 3.0)
	
	if health <= 0:
		# Add a slight delay before changing scenes
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/LoseScreen.tscn")
	return health > 0  # Returns true if player is still alive

func heal(amount):
	health = min(health + amount, max_health)
