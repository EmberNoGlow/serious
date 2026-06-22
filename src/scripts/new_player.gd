extends Actor
@export var camera :Camera2D
#@onready var zoom=camera.zoom
@export var SPEED = 500.0
@export var max_speed = 10000
@export var min_speed = 500
@export var dcharge=2

@onready var charge_attack_timer = Timer.new()

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

#@onready var sprite: Polygon2D = $Node2D/Polygon2D
@onready var sprite: AnimatedSprite2D = $Node2D/Sprite2D
#@onready var ogscale=sprite.scale
var dash_direction := Vector2.ZERO

enum State {
	IDLE,
	MOVE,
	CHARGE,
	DASH
}
var state: State = State.IDLE
func change_state(new_state: State) -> void:
	if Engine.time_scale!=1:
		Engine.time_scale=1
	state = new_state
func die() -> void:
	
	

	set_physics_process(false)
	$CollisionShape2D.disabled = true
	await get_tree().create_timer(2)

	fade_out_and_free()


func fade_out_and_free() -> void:
	await get_tree().create_timer(1.2).timeout

	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.5)

	await tween.finished
	queue_free()
func _ready() -> void:
	
	add_child(charge_attack_timer)

func _process(delta: float) -> void:
	attack_area.look_at(get_global_mouse_position())
	#print(velocity.length())
	await get_tree().create_timer(0.02).timeout
	
func _physics_process(delta: float) -> void:
	$Label.text= str(dcharge)
	if velocity.length()>max_speed*delta:
		velocity*=max_speed*delta/velocity.length()
	#if velocity.length()<min_speed*delta:
		#velocity*=min_speed*delta/velocity.length()
	if Input.is_action_pressed("attack")and dcharge>0:
		#print(Engine.time_scale)
		var progress: float = (charge_attack_timer.wait_time - charge_attack_timer.time_left) / charge_attack_timer.wait_time
		sprite.modulate = Color(1.0, 1.0 - progress, 1.0 - progress)
		
		#camera.zoom=zoom+Vector2.ONE*0.2*progress
		
		
		#var squash_y: float = 1.0 - (progress * 0.3)
		#var squash_x: float = 1.0 + (progress * 0.2)
		#var jitter_x: float = randf_range(-progress, progress) * 5.0
		
		Engine.time_scale=0.4-(progress*0.2)
		
		#sprite.scale = Vector2(squash_x, squash_y)
		#sprite.position.x = jitter_x
		if camera and camera.has_method("start_shake"):
			camera.start_shake(pow(progress, 6.0) * 4.0 + 0.5)
	#else:camera.zoom=zoom
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	
	if state in [State.IDLE, State.MOVE]:
		if direction != Vector2.ZERO:
			change_state(State.MOVE)
		else:
			pass
			#change_state(State.IDLE)
	
	if direction :#and state in [State.IDLE, State.MOVE]:
		velocity += direction * SPEED*delta/150
		if velocity.length()>max_speed*delta:
			print(velocity)
			velocity*=max_speed*delta/velocity.length()
		sprite.scale.x = move_toward(sprite.scale.x, 1.1, 0.02)
		sprite.scale.y = move_toward(sprite.scale.y, 0.9, 0.02)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 0.03)
		if state in [State.IDLE, State.MOVE]:
			sprite.scale = sprite.scale.move_toward(Vector2.ONE, 0.05)
			sprite.position = sprite.position.move_toward(Vector2.ZERO, 0.5)
	var target := Vector2(0.5, 0.2) if state == State.DASH else Vector2.ONE
	#shadow.scale = shadow.scale.lerp(target, 0.2)
	
	if Input.is_action_just_pressed("attack"):
		change_state(State.CHARGE)
		charge_attack_timer.start()
		
	if Input.is_action_just_released("attack")&& dcharge>0:
		#sprite.scale=ogscale
		if state == State.CHARGE:
			charge_attack_timer.stop()
			#var tween = create_tween().set_parallel(true)
			#tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)
			#tween.tween_property(sprite, "position", Vector2.ZERO, 0.1)
			sprite.modulate = Color.WHITE
			#sprite.scale = Vector2(1.8, 0.5)
			dcharge-=1
			if state != State.DASH:
				spawn_afterimages()
				dash_direction = (global_position.direction_to(get_global_mouse_position()))
				#sprite.scale = Vector2(1.4, 0.6)
				var vdash = dash_direction * (SPEED)*delta*2
				
				#print(velocity.dot(vdash))
				if velocity.dot(vdash)<-0.5:
					#print("bounce")
					velocity += 2.5*vdash
				else:velocity += vdash
				
				
				change_state(State.DASH)
				
	#print(velocity.length())
	var collision = move_and_collide(velocity )

	if collision:
		dcharge=2
		var normal = collision.get_normal()
		var impact = abs(velocity.normalized().dot(normal))

		if impact > 0.7:
			velocity = 0.8*velocity.bounce(normal)
		else:
			velocity = velocity.slide(normal)
			#print(velocity)
	velocity*=Engine.time_scale
	move_and_slide()

func spawn_afterimages() -> void:
	for i in 6:
		await get_tree().create_timer(0.02).timeout

		if state != State.DASH:
			return
		var ghost := AnimatedSprite2D.new()
		ghost.animation = sprite.animation
		#ghost.color = Color(
			#1.0,
			#1.0,
			#1.0,
			#0.4
		#)

		ghost.global_position = sprite.global_position
		ghost.global_rotation = sprite.global_rotation
		ghost.global_scale = sprite.global_scale

		get_parent().add_child(ghost)

		#var tween := create_tween()
#
		#tween.set_parallel(true)
#
		#tween.tween_property(
			#ghost,
			#"modulate:a",
			#0.0,
			#0.25
		#)
#
		#tween.tween_property(
			#ghost,
			#"scale",
			#ghost.scale * 1.25,
			#0.25
		#)
#
		#tween.finished.connect(
			#func():
				#if is_instance_valid(ghost):
					#ghost.queue_free()
		#)
	
	
	
	
