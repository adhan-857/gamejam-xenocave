extends Control

@onready var fuel_bar = $MarginContainer2/FuelBar
@onready var health_bar = $MarginContainer4/HealthBar

func _ready():
	# Initialize the fuel bar
	fuel_bar.max_value = Global.max_fuel
	fuel_bar.value = Global.fuel
	
	# Initialize the health bar
	health_bar.max_value = Global.max_health
	health_bar.value = Global.health

func _process(delta):
	# Update the fuel bar to reflect the current global fuel value
	fuel_bar.value = Global.fuel
	
	# Update the health bar to reflect the current global health value
	health_bar.value = Global.health
	
	# Handle fuel regeneration
	Global.regenerate_fuel(delta)

	# Handle health regeneration
	Global.regenerate_health(delta)
