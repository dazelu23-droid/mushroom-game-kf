class_name SpeciesModelPreview
extends Node3D

const MushroomMeshLoader := preload("res://scripts/visuals/mushroom_mesh_loader.gd")

@export var auto_rotate_speed: float = 0.35
@export var preview_height: float = 1.4

@onready var _model_slot: Node3D = $ModelSlot
@onready var _camera: Camera3D = $Camera3D

var _current_pack: Node3D
var _yaw := 0.0
var _pitch := -0.15
var _auto_rotate_pause := 0.0


func _ready() -> void:
	_camera.current = true
	_setup_ground()


func _setup_ground() -> void:
	var ground := get_parent().get_node_or_null("Ground") as MeshInstance3D
	if ground == null:
		return
	var plane := PlaneMesh.new()
	plane.size = Vector2(4.5, 4.5)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.17, 0.22, 0.13)
	mat.roughness = 0.96
	ground.material_override = mat


func show_mesh(mesh_name: String) -> void:
	if _current_pack:
		_current_pack.queue_free()
		_current_pack = null

	var loaded: Dictionary = MushroomMeshLoader.create_display(mesh_name, preview_height, _model_slot)
	if loaded.is_empty():
		push_warning("Species preview: mesh '%s' not found in GLB." % mesh_name)
		return

	_current_pack = loaded["mesh_instance"] as Node3D
	_fit_camera_to_mesh(_current_pack as MeshInstance3D)

	_yaw = 0.0
	_pitch = -0.15
	_model_slot.rotation = Vector3(_pitch, _yaw, 0.0)


func apply_drag(relative: Vector2) -> void:
	_yaw -= relative.x * 0.008
	_pitch = clampf(_pitch - relative.y * 0.008, -0.6, 0.35)
	_auto_rotate_pause = 2.0


func _process(delta: float) -> void:
	if _auto_rotate_pause > 0.0:
		_auto_rotate_pause -= delta
	else:
		_yaw += auto_rotate_speed * delta
	_model_slot.rotation = Vector3(_pitch, _yaw, 0.0)


func _fit_camera_to_mesh(mesh_node: MeshInstance3D) -> void:
	if mesh_node == null or mesh_node.mesh == null:
		_camera.position = Vector3(0.0, 0.8, 3.0)
		_camera.look_at(Vector3(0.0, 0.6, 0.0), Vector3.UP)
		return

	var aabb := mesh_node.mesh.get_aabb()
	var scaled_size := aabb.size * mesh_node.scale
	var height := scaled_size.y
	var width := maxf(scaled_size.x, scaled_size.z)
	var size := maxf(height, width)
	_camera.position = Vector3(0.0, height * 0.45 + 0.1, size * 2.4 + 1.0)
	_camera.look_at(Vector3(0.0, height * 0.35, 0.0), Vector3.UP)
