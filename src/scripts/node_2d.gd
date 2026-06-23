extends Destructable
@export var active : CompressedTexture2D = preload("res://sprites/OilBarrel_Normal.png")
@export var destroyed : CompressedTexture2D = preload("res://sprites/OilBarrel_Destroyed.png")

@onready var sprite: Sprite2D = $Sprite2D

func change_state(to: int): ## 0 - destroy, 1 - active
	match to:
		0:
			sprite.texture = destroyed
		1:
			sprite.texture = active
		_:
			push_error("Invalid State")

func _ready() -> void:
	change_state(1)
