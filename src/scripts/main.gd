extends Node2D

@onready var fade_overlay = %FadeOverlay
@onready var pause_overlay = %PauseOverlay
@onready var camera=$Camera2D
@onready var polygon_2d: Polygon2D = $StaticBody2D/Polygon2D


var camz1=Vector2.ONE
var camz2=Vector2.ONE*0.5


var circle
enum cstate{follow,arena}
var camstate=cstate.follow
func _ready() -> void:
	$player.camera=camera
	
	fade_overlay.visible = true
	$"StaticBody2D/arena gate".disabled = true
	circle = generate_circle_polygon(400, 64, $Node2D.position)
	$StaticBody2D/CollisionPolygon2D.set_polygon(
		(
			Geometry2D
			. clip_polygons($StaticBody2D/CollisionPolygon2D.get_polygon(), circle.get_polygon())[0]
		)
	)
	#$StaticBody2D.add_child(circle)
	#print(circle)

	#Geometry2D.clip_polygons($StaticBody2D/CollisionPolygon2D.get_polygon,circle)
	polygon_2d.set_polygon(
		(
			Geometry2D
			. clip_polygons($StaticBody2D/CollisionPolygon2D.get_polygon(), circle.get_polygon())[0]
		)
	)
func _process(delta: float) -> void:
	if $player and camstate==cstate.follow:
		$Camera2D2.position=$player.position
		$Camera2D2.zoom=camz1
	elif camstate==cstate.arena:
		$Camera2D2.position=$Node2D.position
		$Camera2D2.zoom=camz2

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
	var polygon = Polygon2D.new()

	for _i in num_sides:
		arr.append(vector + position)
		vector = vector.rotated(angle_delta)
	polygon.set_polygon(arr)

	return polygon


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name=="player":
		camstate=cstate.arena
	pass # Replace with function body.
