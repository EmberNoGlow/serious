extends tower


@export var active : CompressedTexture2D = preload("res://sprites/BossTower_Active.webp")
@export var destroyed : CompressedTexture2D = preload("res://sprites/BossTower_Destroyed.webp")
@export var boost : CompressedTexture2D = preload("res://sprites/BossTower_boost.webp.png")
@onready var collision=$CollisionShape2D
@onready var barier = $AnimatedSprite2D
@onready var sprite: Sprite2D = $Sprite
var timer = 10*randf()+5

func c_state(to: int,body:Node2D): ## 0 - destroy, 1 - active
	if to ==0 and body !=$".":
		print("tower stun")
		body.stun()
	match to:
		0:
			sprite.texture = destroyed
			Interactions.boosted=false
			$CollisionShape2D.disabled=true
		1:
			sprite.texture = active
		2:
			sprite.texture = boost
			$AnimatedSprite2D.visible=false
		_:
			push_error("tower.gd: Invalid State")

func _ready() -> void:
	c_state(1,$".")

func _physics_process(delta: float) -> void:
	timer-=delta
	if timer<=0 and Interactions.boosted==false:
		Interactions.boosted=true
		c_state(2,$".")
	elif timer<=0:
		timer=5*randf()
