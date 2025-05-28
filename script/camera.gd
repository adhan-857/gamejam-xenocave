extends Camera2D

var shake_amount = 0.0
var default_offset = offset
var shake_duration = 0.0
var is_shaking = false

func _ready():
	# Simpan posisi offset awal
	default_offset = offset
	
	# Daftarkan kamera ke Global untuk akses
	if Global:
		Global.main_camera = self

func _process(delta):
	if is_shaking:
		# Kurangi durasi shake
		shake_duration -= delta
		
		# Jika masih dalam durasi shake
		if shake_duration > 0:
			# Hasilkan random offset untuk efek shake
			offset = Vector2(
				default_offset.x + randf_range(-1.0, 1.0) * shake_amount,
				default_offset.y + randf_range(-1.0, 1.0) * shake_amount
			)
		else:
			# Hentikan shake dan kembalikan ke posisi awal
			is_shaking = false
			offset = default_offset

func shake(duration = 0.2, amount = 1.0):
	if amount > shake_amount or !is_shaking:
		shake_amount = amount
		shake_duration = duration
		is_shaking = true
