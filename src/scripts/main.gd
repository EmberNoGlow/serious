extends Node2D

@onready var fade_overlay = %FadeOverlay
@onready var pause_overlay = %PauseOverlay


@onready var camera=get_tree().current_scene.get_node("Camera2D")
@onready var polygon_2d: Polygon2D = $StaticBody2D/Polygon2D

enum cstate {follow,arena}
var camstate=cstate.follow
var camz1=Vector2.ONE
var camz2=Vector2.ONE*0.5
var target_camz:Vector2
var target_camp:Vector2


var circle

	

func _ready() -> void:

	fade_overlay.visible = true
	$"StaticBody2D/arena gate".disabled = true
	circle = generate_circle_polygon(400, 64, $Node2D.position)
	
	$StaticBody2D/CollisionPolygon2D.set_polygon((Geometry2D.clip_polygons($StaticBody2D/CollisionPolygon2D.get_polygon(),circle.get_polygon())[0]))



	#$StaticBody2D.add_child(circle)
	#print(circle)

	#Geometry2D.clip_polygons($StaticBody2D/CollisionPolygon2D.get_polygon,circle)
	polygon_2d.set_polygon(
		(
			Geometry2D
			. clip_polygons($StaticBody2D/CollisionPolygon2D.get_polygon(), circle.get_polygon())[0]
		)
	)


func _physics_process(delta: float) -> void:
	if $player and camstate==cstate.follow:
		target_camp=$player.position
		target_camz=camz1
	elif camstate==cstate.arena:
		target_camp= $Node2D.position
		target_camz=camz2
	
	$Camera2D.position=lerp($Camera2D.position, target_camp, delta*5.0)
	$Camera2D.zoom=lerp($Camera2D.zoom, target_camz, delta*2.0)


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
	#print(arr)

	return polygon


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name=='player':
		
		camstate=cstate.arena
	pass # Replace with function body.
