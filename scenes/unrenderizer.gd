extends Node3D


func _ready() -> void:
	for child in get_children():
		if child is not Camera3D and child is not CanvasLayer and "visible" in child:
			child.visible = false
