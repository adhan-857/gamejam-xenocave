extends Node

var health = 100
var max_health = 100
var health_regeneration_rate = 0.175  # Health points per second

var fuel = 100
var max_fuel = 100
var fuel_regeneration_rate = 0.75  # Fuel points per second

var boss_defeated = false
# Reference to the player node
var player = null

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
		
func take_damage(amount):
	health = max(0, health - amount)
	
	# Try to get the player if we don't have a reference yet
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	# Trigger player hurt animation if player reference exists
	if player != null and player.has_method("play_hurt_animation"):
		player.play_hurt_animation()
	
	if health <= 0:
		# Add a slight delay before changing scenes
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/LoseScreen.tscn")
	
	return health > 0  # Returns true if player is still alive

func heal(amount):
	health = min(health + amount, max_health)
