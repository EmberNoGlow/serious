extends CharacterBody2D
class_name Actor

var hp := 5

func die():
	print("DIIIIEEEEEE")

func take_damage(double := false):
	print(hp)
	hp -= 1
	if double:
		hp -= 2
	hp = max(hp, 0)
	if hp == 0:
		die()
