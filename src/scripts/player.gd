extends Actor

@export var camera: Camera2D
@export var SPEED = 700.0
@export var max_speed = 2000
@export var min_speed = 500
@export var dcharge = 2


@onready var charge_attack_timer = Timer.new()
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Node2D/Sprite2D

var dash_direction := Vector2.ZERO
var state: State = State.IDLE

enum State {
	IDLE,
	CHARGE,
	DASH 
}

func change_state(new_state: State) -> void:
	if Engine.time_scale != 1:
		Engine.time_scale = 1
	state = new_state


func _ready() -> void:
	add_child(charge_attack_timer)


func _process(delta: float) -> void:
	attack_area.look_at(get_global_mouse_position())
	await get_tree().create_timer(0.02).timeout


func _physics_process(delta: float) -> void:
	$Label.text = str(dcharge)
	if velocity.length() > max_speed * delta:
		velocity *= max_speed * delta / velocity.length()
	if Input.is_action_pressed("attack"):
		var progress: float = (
			(charge_attack_timer.wait_time - charge_attack_timer.time_left)
			/ charge_attack_timer.wait_time
		)
		sprite.modulate = Color(1.0, 1.0 - progress, 1.0 - progress)

		Engine.time_scale = 0.3 - (progress * 0.3)

		if camera and camera.has_method("start_shake"):
			camera.start_shake(pow(progress, 6.0) * 4.0 + 0.5)

	var target := Vector2(0.5, 0.2) if state == State.DASH else Vector2.ONE

	if Input.is_action_just_pressed("attack"):
		change_state(State.CHARGE)
		charge_attack_timer.start()

	if Input.is_action_just_released("attack") && dcharge > 0:
		if state == State.CHARGE:
			charge_attack_timer.stop()
			sprite.modulate = Color.WHITE
			dcharge -= 1
			if state != State.DASH:
				spawn_afterimages()
				dash_direction = (global_position.direction_to(get_global_mouse_position()))
				var vdash = dash_direction * (SPEED) * delta

				if velocity.dot(vdash) < -0.5:
					velocity += 2.5 * vdash
				else:
					velocity += vdash

				change_state(State.DASH)
	var collision = move_and_collide(velocity)

	if collision:
		dcharge = 2
		var normal = collision.get_normal()
		var impact = abs(velocity.normalized().dot(normal))

		if impact > 0.7:
			velocity = velocity.bounce(normal)
		else:
			velocity = velocity.slide(normal)
			print(velocity)

	move_and_slide()


func spawn_afterimages() -> void:
	for i in 6:
		await get_tree().create_timer(0.02).timeout

		if state != State.DASH:
			return
		var ghost := AnimatedSprite2D.new()
		ghost.animation = sprite.animation

		ghost.global_position = sprite.global_position
		ghost.global_rotation = sprite.global_rotation
		ghost.global_scale = sprite.global_scale

		get_parent().add_child(ghost)
