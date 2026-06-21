extends Node2D
@onready var fade_overlay = %FadeOverlay
@onready var pause_overlay = %PauseOverlay
var circle
func _ready() -> void:
	fade_overlay.visible = true
	$"StaticBody2D/arena gate".disabled=true
	circle=generate_circle_polygon(400,64,$Node2D.position)
	$StaticBody2D/CollisionPolygon2D.set_polygon(Geometry2D.clip_polygons($StaticBody2D/CollisionPolygon2D.get_polygon(),circle.get_polygon())[0])
	#$StaticBody2D.add_child(circle)
	#print(circle)
	
	#Geometry2D.clip_polygons($StaticBody2D/CollisionPolygon2D.get_polygon,circle)
	
func _input(event) -> void:
	if event.is_action_pressed("pause") and not pause_overlay.visible:
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		pause_overlay.grab_button_focus()
		pause_overlay.visible = true
		
func generate_circle_polygon(radius: float, num_sides: int, position: Vector2):
	var angle_delta: float = (PI * 2) / num_sides
	var vector: Vector2 = Vector2(radius, 0)
	var arr: PackedVector2Array
	var polygon=Polygon2D.new()

	for _i in num_sides:
		arr.append(vector + position)
		vector = vector.rotated(angle_delta)
	polygon.set_polygon(arr)

	return polygon
