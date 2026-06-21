extends CollisionPolygon2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	set_deferred('disabled',false)
	pass # Replace with function body.
