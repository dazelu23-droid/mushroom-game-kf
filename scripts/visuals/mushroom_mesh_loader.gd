class_name MushroomMeshLoader
extends RefCounted

## Loads a single species mesh from the GLB pack and plants it at the anchor origin.

const ADULT_SCENE := preload("res://assets/mushroom/lowpoly_mushrooms.glb")


static func create_display(
	mesh_name: String,
	desired_height: float,
	anchor: Node3D,
	ground_lift: float = 0.0
) -> Dictionary:
	if not anchor.is_inside_tree():
		return {}

	var temp := ADULT_SCENE.instantiate() as Node3D
	anchor.add_child(temp)
	temp.visible = false

	_hide_all_mushroom_meshes(temp)
	var target := _find_mushroom_node(temp, mesh_name)
	if target == null:
		temp.queue_free()
		return {}

	target.visible = true
	temp.force_update_transform()

	var source := _get_mesh_instance(target)
	if source == null or source.mesh == null:
		temp.queue_free()
		return {}

	var local_aabb := source.mesh.get_aabb()
	var rel_xform := anchor.global_transform.affine_inverse() * source.global_transform
	var world_height := _world_aabb_height(local_aabb, source.global_transform)
	if world_height < 0.001:
		temp.queue_free()
		return {}

	var scale_factor := desired_height / world_height

	var display := MeshInstance3D.new()
	display.name = "AdultMushroom"
	display.mesh = source.mesh
	display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for surface_idx in source.mesh.get_surface_count():
		var surface_mat := source.get_active_material(surface_idx)
		if surface_mat:
			display.set_surface_override_material(surface_idx, surface_mat)

	temp.queue_free()

	anchor.add_child(display)
	display.transform = rel_xform
	display.scale = display.scale * scale_factor
	_align_bottom_to_world_point(display, local_aabb, anchor.to_global(Vector3(0.0, ground_lift, 0.0)))

	display.force_update_transform()
	var cap_height := _world_aabb_height(local_aabb, display.global_transform)

	return {
		"mesh_instance": display,
		"cap_height": cap_height,
	}


static func _align_bottom_to_world_point(
	display: MeshInstance3D,
	local_aabb: AABB,
	target_world: Vector3
) -> void:
	display.force_update_transform()
	var bottom_world := _world_aabb_bottom_center(local_aabb, display.global_transform)
	display.global_position += target_world - bottom_world


static func _world_aabb_height(local_aabb: AABB, xform: Transform3D) -> float:
	var corners := _aabb_corners(local_aabb, xform)
	var min_y := corners[0].y
	var max_y := corners[0].y
	for corner in corners:
		min_y = minf(min_y, corner.y)
		max_y = maxf(max_y, corner.y)
	return max_y - min_y


static func _world_aabb_bottom_center(local_aabb: AABB, xform: Transform3D) -> Vector3:
	var center := local_aabb.get_center()
	var bottom := Vector3(center.x, local_aabb.position.y, center.z)
	return xform * bottom


static func _aabb_corners(local_aabb: AABB, xform: Transform3D) -> Array[Vector3]:
	var p := local_aabb.position
	var s := local_aabb.size
	var corners: Array[Vector3] = []
	for x in [0.0, 1.0]:
		for y in [0.0, 1.0]:
			for z in [0.0, 1.0]:
				corners.append(xform * Vector3(p.x + s.x * x, p.y + s.y * y, p.z + s.z * z))
	return corners


static func _find_mushroom_node(root: Node, mesh_name: String) -> Node3D:
	var exact := root.find_child(mesh_name, true, false) as Node3D
	if exact:
		return exact
	for node in root.find_children("mushroom_*", "Node3D", true, false):
		if node.name == mesh_name or node.name.begins_with(mesh_name + "_"):
			return node as Node3D
	return null


static func _get_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _get_mesh_instance(child)
		if found:
			return found
	return null


static func _hide_all_mushroom_meshes(root: Node) -> void:
	for child in root.get_children():
		if _is_mushroom_root_node(child.name):
			child.visible = false
		_hide_all_mushroom_meshes(child)


static func _is_mushroom_root_node(node_name: String) -> bool:
	if not node_name.begins_with("mushroom_"):
		return false
	var suffix: String = node_name.trim_prefix("mushroom_").split("_")[0]
	return suffix.is_valid_int()
