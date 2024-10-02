extends Node


var dir = 1


func _physics_process(delta: float) -> void:
	if self.get_parent() is not Node3D:
		return
	
	
	self.get_parent().position.x += dir * delta
	if abs(self.get_parent().position.x) > 1:
		dir *= -1
