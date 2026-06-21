extends Actor

@export var SPEED = 10.0
@export var dcharge=2
@onready var attack_cooldown_timer = Timer.new()
@onready var charge_attack_timer = Timer.new()

@onready var sprite: Polygon2D = $Node2D/Polygon2D
@onready var shadow: Sprite2D = $Node2D/Sprite2D
@onready var camera: Camera2D = get_viewport().get_camera_2d()

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

@export var DASH_SPEED := 20.0
const DASH_DURATION := 0.15
const DASH_PREPARE := 0.05

var dash_direction := Vector2.ZERO
var is_dashing := false

enum State {
	IDLE,
	MOVE,
	CHARGING,
	ATTACKING,
	RECOVERY,
	DASH
}

var state: State = State.IDLE

var hit_targets: Array = []

func change_state(new_state: State) -> void:
	if Engine.time_scale!=1:
		Engine.time_scale=1
	state = new_state

func _ready() -> void:
	add_child(attack_cooldown_timer)
	add_child(charge_attack_timer)
	
	attack_cooldown_timer.wait_time = 0.2
	attack_cooldown_timer.one_shot = true
	
	charge_attack_timer.wait_time = 0.5
	charge_attack_timer.one_shot = true
	charge_attack_timer.timeout.connect(_on_charge_complete)
	
	attack_area.body_entered.connect(_on_body_entered)
	attack_area.monitoring = false
	
	velocity=velocity.clamp(Vector2.ZERO,Vector2.ONE*SPEED)

func _on_body_entered(body: Node) -> void:
	pass
	#if state == State.ATTACKING and not hit_targets.has(body):
		#hit_targets.append(body)

func _process(_delta: float) -> void:
	attack_area.look_at(get_global_mouse_position())
	$Label.text= str(dcharge)
	
	if state == State.CHARGING:
		if Input.is_action_pressed("attack"):
			var progress: float = (charge_attack_timer.wait_time - charge_attack_timer.time_left) / charge_attack_timer.wait_time
			sprite.modulate = Color(1.0, 1.0 - progress, 1.0 - progress)
		
			var squash_y: float = 1.0 - (progress * 0.3)
			var squash_x: float = 1.0 + (progress * 0.2)
			var jitter_x: float = randf_range(-progress, progress) * 5.0
		
			Engine.time_scale=0.3-(progress*0.3)
			print(Engine.time_scale)
			sprite.scale = Vector2(squash_x, squash_y)
			sprite.position.x = jitter_x
		
			if camera and camera.has_method("start_shake"):
				camera.start_shake(pow(progress, 6.0) * 4.0 + 0.5)
			
		else:change_state(State.DASH)
	elif state != State.ATTACKING:
		if camera and camera.has_method("end_shake"):
			camera.end_shake()
		if attack_cooldown_timer.is_stopped():
			sprite.modulate = Color.WHITE
	
	var target := Vector2(0.5, 0.2) if state == State.DASH else Vector2.ONE
	shadow.scale = shadow.scale.lerp(target, 0.2)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack") \
		and attack_cooldown_timer.is_stopped() \
		and state in [State.IDLE, State.MOVE]:

		change_state(State.CHARGING)
		charge_attack_timer.start()
		
	if Input.is_action_just_released("attack")&& dcharge>0:
		if state == State.CHARGING:
			charge_attack_timer.stop()
			var tween = create_tween().set_parallel(true)
			tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)
			tween.tween_property(sprite, "position", Vector2.ZERO, 0.1)
			sprite.modulate = Color.WHITE
			dcharge-=1
			if state != State.DASH:
				change_state(State.DASH)
				start_dash()
			
	
	#if Input.is_action_just_released("attack"):
		#if state in [State.IDLE, State.MOVE] and !is_dashing:
			#start_dash()

	#if state == State.DASH:
		#velocity = dash_direction * DASH_SPEED

		sprite.position.y = -sin(
			(Time.get_ticks_msec() % 150) / 150.0 * PI
		) * 12.0
		
		
		
		return

	#var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	#
	#if state in [State.IDLE, State.MOVE]:
		#if direction != Vector2.ZERO:
			#change_state(State.MOVE)
		#else:
			#change_state(State.IDLE)
	#
	#if direction and state in [State.IDLE, State.MOVE]:
		#velocity = direction * SPEED
		#sprite.scale.x = move_toward(sprite.scale.x, 1.1, 0.02)
		#sprite.scale.y = move_toward(sprite.scale.y, 0.9, 0.02)
	#else:
		#velocity = velocity.move_toward(Vector2.ZERO, 25.0)
		#if state in [State.IDLE, State.MOVE]:
			#sprite.scale = sprite.scale.move_toward(Vector2.ONE, 0.05)
			#sprite.position = sprite.position.move_toward(Vector2.ZERO, 0.5)

	move_and_slide()
	var collision=move_and_collide(velocity)
	if collision:
		dcharge=2
		velocity=velocity.bounce(collision.get_normal())

func start_dash() -> void:
	if is_dashing:
		return

	is_dashing = true

	#var input_direction := Input.get_vector(
		#"left",
		#"right",
		#"up",
		#"down"
	#)

	dash_direction = (
		#input_direction.normalized()
		#if input_direction != Vector2.ZERO
		global_position.direction_to(get_global_mouse_position())
	)

	sprite.scale = Vector2(1.4, 0.6)
	velocity = dash_direction * (DASH_SPEED * 0.3)

	await get_tree().create_timer(DASH_PREPARE).timeout

	if !is_instance_valid(self):
		return

	change_state(State.DASH)

	sprite.scale = Vector2(1.8, 0.5)

	spawn_afterimages()

	await get_tree().create_timer(DASH_DURATION).timeout

	if !is_instance_valid(self):
		return

	

	create_tween().tween_property(
		sprite,
		"scale",
		Vector2.ONE,
		0.15
	)

	change_state(State.IDLE)

	is_dashing = false


func spawn_afterimages() -> void:
	for i in 6:
		await get_tree().create_timer(0.02).timeout

		if state != State.DASH:
			return
		var ghost := Polygon2D.new()
		ghost.polygon = sprite.polygon
		ghost.color = Color(
			1.0,
			1.0,
			1.0,
			0.4
		)

		ghost.global_position = sprite.global_position
		ghost.global_rotation = sprite.global_rotation
		ghost.global_scale = sprite.global_scale

		get_parent().add_child(ghost)

		var tween := create_tween()

		tween.set_parallel(true)

		tween.tween_property(
			ghost,
			"modulate:a",
			0.0,
			0.25
		)

		tween.tween_property(
			ghost,
			"scale",
			ghost.scale * 1.25,
			0.25
		)

		tween.finished.connect(
			func():
				if is_instance_valid(ghost):
					ghost.queue_free()
		)


func _on_charge_complete() -> void:
	attack_cooldown_timer.start()
	#change_state(State.ATTACKING)

	hit_targets.clear()

	attack_area.monitoring = true

	await get_tree().create_timer(0.08).timeout

	attack_area.monitoring = false

	#for body in hit_targets:
		#if body is Actor and body != self:
			#print(body)
			#body.take_damage(true)

	await get_tree().create_timer(0.2).timeout
	
	change_state(State.IDLE)

func hitstop(duration: float, scale: float = 0.1) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(duration * scale, true, false, true).timeout
	Engine.time_scale = 1.0

func die():
	print("DIEEEEE")
	get_tree().reload_current_scene()
