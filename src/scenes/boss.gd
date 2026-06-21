extends Actor

enum State {
	IDLE,
	RUSH,
	CIRCLE,
	DODGING,
	ATTACK,
	RECOVER
}

#Export
@export var player: Actor

@export var move_speed: float = 220.0
@export var dodge_speed: float = 520.0
@export var vieu_radius: float = 250.0

@export var attack_range: float = 120.0
@export var attack_speed: float = 0.8
@export var reaction_time: float = 0.35

#Other
var state: State = State.IDLE
var state_timer: float = 0.0

var attack_dir: Vector2 = Vector2.ZERO
var dodge_dir = 1.0

var turn_angle := 0.0

@onready var sprite: Polygon2D = $Node2D/blade

#####################
# FUNCTIONS
#####################

func _ready() -> void:
	state = State.IDLE

signal boss_died(boss_position: Vector2)

func die() -> void:
	boss_died.emit(global_position)
	
	set_physics_process(false)
	$CollisionShape2D.disabled = true 
	
	fade_out_and_free() 

func fade_out_and_free() -> void:
	await get_tree().create_timer(1.2).timeout
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.5)
	
	await tween.finished
	queue_free()

##################
# Py_Process
##################
func _physics_process(delta: float) -> void:
	state_timer += delta
	
	match state:
		State.IDLE:
			look_for_player(delta)
			check_player_charge()
		
		State.DODGING:
			perform_dodge(delta)
		
		State.RUSH:
			rush(delta)
			check_player_charge()
		
		State.CIRCLE:
			circle(delta)
			check_player_charge()
		
		State.ATTACK:
			perform_attack()
		
		State.RECOVER:
			recover(delta)
	
	sprite.global_rotation = 0
	
	move_and_slide()


func look_for_player(delta: float) -> void:
	if not player:
		return
	
	if position.distance_to(player.position) < vieu_radius:
		state = State.RUSH
	else:
		#wrong place
		#velocity = (player.position -position).normalized() * move_speed
		velocity = Vector2(randf(),randf()).normalized() * move_speed / 10
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func check_player_charge() -> void:
	if not player:
		return

	# We assume player has charge_attack_timer
	var charging = not player.charge_attack_timer.is_stopped()

	if charging:
		var progress = (
			player.charge_attack_timer.wait_time -
			player.charge_attack_timer.time_left
		) / player.charge_attack_timer.wait_time
		# Boss reacts late (fair reaction delay)
		if progress > 0.8:
			dodge_dir = 1.0
			if randf() > 0.5:
				dodge_dir = -1.0
			state = State.DODGING
			state_timer = 0.0

func perform_dodge(delta: float) -> void:
	# Short dodge duration
	if state_timer > 0.25:
		state = State.RECOVER
	# Slight drag so it doesn't feel robotic
	velocity = (position.direction_to(player.position).orthogonal() * move_speed * 2) * dodge_dir

func rush(delta: float) -> void:
	look_at(player.position)
	if position.distance_to(player.position) < attack_range:
		state = State.CIRCLE
	else:
		state_timer = 0.0
		sprite.modulate = Color(0.661, 0.445, 0.0, 1.0)
		velocity += transform.x * move_speed / 60
		velocity = velocity.limit_length(move_speed)

func circle(delta: float) -> void:
	if position.distance_to(player.position) < attack_range:
		turn_angle += 0.01
	elif position.distance_to(player.position) > vieu_radius:
		state = State.RUSH
		return
	else:
		turn_angle -= 0.01
	
	look_at(player.position)
	rotate(turn_angle)
	velocity += transform.y * move_speed / 20
	velocity = velocity.limit_length(move_speed)
	if state_timer > 3:
		state_timer = 0.0
		attack_dir = position.direction_to(player.position)
		state = State.ATTACK
		sprite.modulate = Color(1.0, 0.3, 0.3)

func perform_attack() -> void:
	# One-shot hit logic
	velocity /= 1.08
	if state_timer >= attack_speed:
		velocity = attack_dir * move_speed * 3

		state = State.RECOVER
		state_timer = 0.0

func recover(delta: float) -> void:
	velocity /= 1.05
	sprite.modulate = Color(0.322, 0.001, 0.861, 1.0)
	if state_timer > 1:
		state = State.RUSH
		state_timer = 0.0

func _on_damage_zone_body_entered(body: Node2D) -> void:
	print(body.name)
	if body == player:
		if body.has_method("take_damage"):
			body.take_damage(true)
