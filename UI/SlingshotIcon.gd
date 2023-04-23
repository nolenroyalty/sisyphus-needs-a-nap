extends Control

onready var pebble1 = $Pebble1
onready var pebble2 = $Pebble2
onready var pebble3 = $Pebble3
onready var pebble4 = $Pebble4
onready var pebbles = [pebble1, pebble2, pebble3, pebble4]

func hideemall():
	for p in pebbles: p.hide()

func set_ammo(ammo : int):
	hideemall()
	var i = 0
	while i < ammo:
		pebbles[i].show()
		i += 1
