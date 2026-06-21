extends Actor

enum State {
	IDLE,
	CIRCLING,
	DODGING,
	WINDUP,
	ATTACK,
	RECOVER
}

@export var player: Actor

@export var move_speed: float = 220.0
@export var dodge_speed: float = 520.0
@export var circle_radius: float = 180.0

@export var attack_range: float = 90.0
@export var reaction_time: float = 0.35

var state: State = State.CIRCLING
var state_timer: float = 0.0

var aggression: float = 0.4

@onready var sprite: Polygon2D = $Node2D/Polygon2D

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


func _physics_process(delta: float) -> void:
	state_timer += delta

	match state:
		State.CIRCLING:
			circle_player(delta)
			check_player_charge()

		State.DODGING:
			perform_dodge(delta)

		State.WINDUP:
			windup_attack(delta)

		State.ATTACK:
			perform_attack()

		State.RECOVER:
			recover(delta)


	move_and_slide()


func circle_player(delta: float) -> void:
	if not player:
		return

	var dir := (player.global_position - global_position).normalized()
	var dist := global_position.distance_to(player.global_position)

	var tangent := Vector2(-dir.y, dir.x)
	
	var approach_weight = 0.3 if dist > circle_radius else 0.0
	var move_dir = (tangent + dir * approach_weight).normalized()

	velocity = move_dir * move_speed

	aggression = clamp(1.0 - (dist / 500.0), 0.2, 1.0)

	if dist <= attack_range + 20.0:
		if randf() < delta * aggression * 2.0:
			start_attack()


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
		if progress > (1.0 - reaction_time):
			start_dodge()


func start_dodge() -> void:
	state = State.DODGING
	state_timer = 0.0

	# Direction from player to boss
	var from_player := (global_position - player.global_position).normalized()

	# Perpendicular dodge direction
	var dodge_dir := from_player.orthogonal()

	# Random flip for unpredictability
	if randf() < 0.5:
		dodge_dir *= -1.0

	velocity = dodge_dir * dodge_speed

func perform_dodge(delta: float) -> void:
	# Short dodge duration
	if state_timer > 0.25:
		start_recover()

	# Slight drag so it doesn't feel robotic
	velocity = velocity.move_toward(Vector2.ZERO, 8.0)

func start_attack() -> void:
	state = State.WINDUP
	state_timer = 0.0
	velocity = Vector2.ZERO

func windup_attack(delta: float) -> void:
	# Visual telegraph phase
	sprite.modulate = Color(1.0, 0.3, 0.3)

	# Shake or tension could be added here

	if state_timer > 0.6:
		state = State.ATTACK
		state_timer = 0.0

func perform_attack() -> void:
	# One-shot hit logic
	if global_position.distance_to(player.global_position) < attack_range:
		if player.has_method("take_damage"):
			player.take_damage(true)

	start_recover()

func start_recover() -> void:
	state = State.RECOVER
	state_timer = 0.0
	sprite.modulate = Color(0.7, 0.7, 1.0)

func recover(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 15.0)

	if state_timer > 0.5:
		state = State.CIRCLING
		state_timer = 0.0
