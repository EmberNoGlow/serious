extends CollisionPolygon2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name=='player':
		set_deferred('disabled',false)
