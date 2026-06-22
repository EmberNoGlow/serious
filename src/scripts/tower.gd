extends Node2D

@export var active : CompressedTexture2D = preload("res://sprites/BossTower_Active.webp")
@export var destroyed : CompressedTexture2D = preload("res://sprites/BossTower_Destroyed.webp")

@onready var sprite: Sprite2D = $Sprite

func change_state(to: int): ## 0 - destroy, 1 - active
	match to:
		0:
			sprite.texture = destroyed
		1:
			sprite.texture = active
		_:
			push_error("tower.gd: Invalid State")

func _ready() -> void:
	change_state(1)
