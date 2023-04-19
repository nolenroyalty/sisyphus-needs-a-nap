extends Node2D

onready var sprite : Sprite = $Sprite

func _ready():
	sprite.frame = State.block_height