extends Node2D

@onready var fade_overlay = %FadeOverlay
@onready var pause_overlay = %PauseOverlay
@onready var camera_2d: Camera2D = $Camera2D
@onready var arena_gate = $"StaticBody2D/arena gate"
@onready var collision_polygon: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D
@onready var polygon_2d: Polygon2D = $StaticBody2D/Polygon2D

enum CameraState { FOLLOW, ARENA }

const FOLLOW_ZOOM := Vector2.ONE
const ARENA_ZOOM := Vector2.ONE * 0.5

var camera_state: CameraState = CameraState.FOLLOW
var target_camera_position: Vector2 = Vector2.ZERO
var target_camera_zoom: Vector2 = FOLLOW_ZOOM


func _ready() -> void:
	fade_overlay.visible = true
	arena_gate.disabled = true

	var circle_polygon := generate_circle_polygon(400.0, 64, $Node2D.position)
	var clipped_polygons := Geometry2D.clip_polygons(
		collision_polygon.polygon,
		circle_polygon.polygon
	)

	if clipped_polygons.is_empty():
		return

	var clipped_polygon := clipped_polygons[0]
	collision_polygon.polygon = clipped_polygon
	polygon_2d.polygon = clipped_polygon

func _physics_process(delta: float) -> void:
	var player = get_node_or_null("player")

	if player != null and camera_state == CameraState.FOLLOW:
		target_camera_position = player.position
		target_camera_zoom = FOLLOW_ZOOM
	elif camera_state == CameraState.ARENA:
		target_camera_position = $Node2D.position
		target_camera_zoom = ARENA_ZOOM

	camera_2d.position = camera_2d.position.lerp(target_camera_position, delta * 5.0)
	camera_2d.zoom = camera_2d.zoom.lerp(target_camera_zoom, delta * 2.0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not pause_overlay.visible:
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		pause_overlay.grab_button_focus()
		pause_overlay.visible = true

func generate_circle_polygon(radius: float, num_sides: int, position: Vector2) -> Polygon2D:
	var angle_delta := TAU / num_sides
	var point := Vector2(radius, 0.0)
	var points := PackedVector2Array()

	for _i in num_sides:
		points.append(point + position)
		point = point.rotated(angle_delta)

	var polygon := Polygon2D.new()
	polygon.polygon = points
	return polygon

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player":
		camera_state = CameraState.ARENA
