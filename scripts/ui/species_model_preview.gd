class_name SpeciesModelPreview
extends Node3D

const ADULT_SCENE := preload("res://assets/mushroom/lowpoly_mushrooms.glb")

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

	var pack := ADULT_SCENE.instantiate() as Node3D
	_model_slot.add_child(pack)
	_current_pack = pack
	_hide_all_mushroom_meshes(pack)

	var target := pack.find_child(mesh_name, true, false) as Node3D
	if target == null:
		push_warning("Species preview: mesh '%s' not found in GLB." % mesh_name)
		return

	target.visible = true
	_center_and_scale(pack, target)
	_fit_camera_to_mesh(target)

	_yaw = 0.0
	_pitch = -0.15
	_model_slot.rotation = Vector3(_pitch, _yaw, 0.0)


func _center_and_scale(pack: Node3D, target: Node3D) -> void:
	var mesh_node := _get_mesh_instance(target)
	if mesh_node == null or mesh_node.mesh == null:
		pack.position = -target.position
		return

	var aabb := mesh_node.mesh.get_aabb()
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var scale_factor := preview_height / max_dim if max_dim > 0.001 else 1.0
	pack.scale = Vector3.ONE * scale_factor
	pack.position = -target.position * scale_factor
	pack.position.y -= aabb.position.y * scale_factor


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


func _fit_camera_to_mesh(target: Node3D) -> void:
	var mesh_node := _get_mesh_instance(target)
	if mesh_node == null or mesh_node.mesh == null:
		_camera.position = Vector3(0.0, 0.8, 3.0)
		_camera.look_at(Vector3(0.0, 0.6, 0.0), Vector3.UP)
		return

	var aabb := mesh_node.mesh.get_aabb()
	var scaled_size := aabb.size * target.scale * _current_pack.scale if _current_pack else aabb.size
	var height := scaled_size.y
	var width := maxf(scaled_size.x, scaled_size.z)
	var size := maxf(height, width)
	_camera.position = Vector3(0.0, height * 0.45 + 0.1, size * 2.4 + 1.0)
	_camera.look_at(Vector3(0.0, height * 0.35, 0.0), Vector3.UP)


func _get_mesh_instance(target: Node3D) -> MeshInstance3D:
	if target.get_child_count() == 0:
		return null
	return target.get_child(0) as MeshInstance3D


func _hide_all_mushroom_meshes(root: Node) -> void:
	for child in root.get_children():
		if _is_mushroom_root_node(child.name):
			child.visible = false
		_hide_all_mushroom_meshes(child)


func _is_mushroom_root_node(node_name: String) -> bool:
	if not node_name.begins_with("mushroom_"):
		return false
	var suffix: String = node_name.trim_prefix("mushroom_")
	return suffix.is_valid_int()
