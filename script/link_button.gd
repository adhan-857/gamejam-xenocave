extends LinkButton

func _on_pressed():
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")
