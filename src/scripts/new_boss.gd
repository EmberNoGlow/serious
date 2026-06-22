extends Actor
@export var player:Actor
func _physics_process(delta: float) -> void:
	var dir = position-player.global_position
	$shield.rotation=lerp($shield.rotation,dir.angle(),2*delta)
