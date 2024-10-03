class_name RayTracedSphere
extends CSGSphere3D


@export var color: Color
@export var light_intensity: float = 0.0
@export var light_color: Color


func _ready() -> void:
	RayTracingManagerNew.instance.add_sphere(self)
