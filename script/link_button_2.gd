extends LinkButton

func _ready():
	if not is_connected("pressed", _on_pressed):
		connect("pressed", _on_pressed)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_pressed()

func _on_pressed():
	get_tree().quit()
