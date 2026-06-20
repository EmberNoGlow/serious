extends Actor

func _ready() -> void:
	hp = 1

func die():
	print("VICTORRREY!")
	queue_free()
