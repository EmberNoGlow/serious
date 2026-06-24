extends CharacterBody2D
class_name Actor

var hp := 3

func die():
	print("DIIIIEEEEEE")

func take_damage(double := false):
	print(str(hp)+" "+name)
	hp -= 1
	if double:
		hp -= 2
	hp = max(hp, 0)
	if hp == 0:
		die()
