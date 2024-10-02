extends Node3D


func _ready() -> void:
	for child in get_children():
		if "visible" in child and child is not Camera3D:
			child.visible = false
