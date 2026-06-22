extends Camera2D

var shake_intensity: float = 0.0
var shake_decay: float = 5.0
enum State { following, arena }


func _ready() -> void:
	var state: State = State.following


func _process(delta: float) -> void:
	if shake_intensity > 0:
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
	else:
		offset = Vector2.ZERO


func start_shake(intensity: float, decay: float = 10.0) -> void:
	shake_intensity = intensity
	shake_decay = decay


func end_shake() -> void:
	shake_intensity = 0
	shake_decay = 0
