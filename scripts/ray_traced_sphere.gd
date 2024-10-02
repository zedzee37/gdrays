class_name RayTracedSphere
extends CSGSphere3D


@export var color: Color


func _ready() -> void:
	RayTracingManager.instance.add_sphere(self)
