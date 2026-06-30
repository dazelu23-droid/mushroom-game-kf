class_name AirborneSpore
extends Node3D

signal arrived(patch: SubstratePatch)

@export var travel_speed: float = 5.5
@export var arc_height: float = 2.4

var _target_patch: SubstratePatch
var _start: Vector3
var _end: Vector3
var _travel := 0.0
var _duration := 1.0
var _mesh: MeshInstance3D


func launch(from: Vector3, patch: SubstratePatch) -> void:
	_target_patch = patch
	_start = from
	_end = Vector3(patch.global_position.x, patch.global_position.y + 0.12, patch.global_position.z)
	global_position = from
	var horizontal_dist := Vector2(_end.x - _start.x, _end.z - _start.z).length()
	_duration = clampf(horizontal_dist / travel_speed, 0.8, 3.5)
	_travel = 0.0


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.028
	sphere.height = 0.056
	sphere.radial_segments = 8
	sphere.rings = 4
	_mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.92, 0.68, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.55)
	mat.emission_energy_multiplier = 1.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh.material_override = mat
	add_child(_mesh)


func _process(delta: float) -> void:
	if _target_patch == null:
		return
	_travel += delta / _duration
	var t := clampf(_travel, 0.0, 1.0)
	var flat := _start.lerp(_end, t)
	var arc := sin(t * PI) * arc_height
	global_position = Vector3(flat.x, lerpf(_start.y, _end.y, t) + arc, flat.z)
	if _mesh:
		_mesh.scale = Vector3.ONE * lerpf(1.0, 0.55, t)
	if t >= 1.0:
		arrived.emit(_target_patch)
		queue_free()
