class_name SubstratePatch
extends Area3D

@export var substrate_type: String = "leaf_litter"
@export var substrate_label: String = "Leaf litter"
@export var mount_type: String = "ground"

var _compatible := false
var _has_colony := false
var _marker: MeshInstance3D
var _mount_outward: Vector3 = Vector3.UP


func _ready() -> void:
	add_to_group("substrate")
	body_entered.connect(_on_body_entered)
	_apply_realistic_material()
	_build_marker()
	_update_highlight()


func get_substrate_type() -> String:
	return substrate_type


func is_tree_mounted() -> bool:
	return mount_type == "tree_trunk"


func suppresses_hyphae_visuals() -> bool:
	return is_tree_mounted()


func configure_tree_mount(outward: Vector3, _basis: Basis = Basis.IDENTITY) -> void:
	mount_type = "tree_trunk"
	_mount_outward = outward.normalized()


func get_mount_outward() -> Vector3:
	return _mount_outward


func get_fruiting_basis(species: Dictionary = {}) -> Basis:
	if is_tree_mounted():
		return TreeMountUtil.basis_for_tree_fungus(_mount_outward, species)
	return Basis.IDENTITY


func refresh_tree_marker() -> void:
	if _marker and is_instance_valid(_marker):
		_marker.queue_free()
		_marker = null
	_build_marker()
	_update_highlight()


func get_landing_position() -> Vector3:
	if is_tree_mounted():
		return global_position + _mount_outward * 0.05
	return global_position + Vector3.UP * 0.08


func has_colony() -> bool:
	return _has_colony


func claim_colony() -> bool:
	if _has_colony:
		return false
	_has_colony = true
	if is_node_ready():
		_update_highlight()
	return true


func release_colony() -> void:
	_has_colony = false
	if is_node_ready():
		_update_highlight()


func set_compatible(compatible: bool) -> void:
	_compatible = compatible
	if is_node_ready():
		_update_highlight()


func _apply_realistic_material() -> void:
	var mesh := get_parent().get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null or substrate_type == "tree_bark":
		return
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.94
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	match substrate_type:
		"tree_bark":
			mat.albedo_color = Color(0.24, 0.17, 0.11)
			mat.roughness = 0.96
		"dead_hardwood":
			mat.albedo_color = Color(0.28, 0.19, 0.12)
			mat.roughness = 0.94
		"leaf_litter":
			mat.albedo_color = Color(0.34, 0.26, 0.15)
			mat.roughness = 0.98
		"forest_soil":
			mat.albedo_color = Color(0.22, 0.17, 0.12)
			mat.roughness = 1.0
		"compost", "manure_compost":
			mat.albedo_color = Color(0.26, 0.21, 0.15)
			mat.roughness = 0.96
		"straw":
			mat.albedo_color = Color(0.48, 0.4, 0.22)
			mat.roughness = 0.92
		"grassland_soil":
			mat.albedo_color = Color(0.3, 0.26, 0.16)
			mat.roughness = 0.97
		"hardwood_sawdust":
			mat.albedo_color = Color(0.36, 0.29, 0.19)
			mat.roughness = 0.95
		_:
			mat.albedo_color = Color(0.3, 0.25, 0.18)
			mat.roughness = 0.95
	mesh.set_surface_override_material(0, mat)


func _build_marker() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_marker = parent.get_node_or_null("CompatibleMarker") as MeshInstance3D
	if _marker:
		return

	_marker = MeshInstance3D.new()
	_marker.name = "CompatibleMarker"
	_marker.position.y = 0.06

	var ring := TorusMesh.new()
	if is_tree_mounted():
		ring.inner_radius = 0.42
		ring.outer_radius = 0.56
	else:
		ring.inner_radius = 1.35
		ring.outer_radius = 1.52
	ring.rings = 8
	ring.ring_segments = 24
	_marker.mesh = ring
	if is_tree_mounted() and _mount_outward.length_squared() > 0.0001:
		var out := _mount_outward.normalized()
		var tangent := Vector3.UP.cross(out)
		if tangent.length_squared() > 0.0001:
			tangent = tangent.normalized()
			_marker.basis = Basis(tangent, Vector3.UP, out)
		else:
			_marker.rotation = Vector3.ZERO
	elif not is_tree_mounted():
		_marker.rotation.x = PI * 0.5

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.82, 0.42, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.65, 0.28)
	mat.emission_energy_multiplier = 1.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.4
	_marker.material_override = mat
	_marker.visible = false
	parent.add_child(_marker)

	var label_mesh := MeshInstance3D.new()
	label_mesh.name = "MarkerCenter"
	label_mesh.position.y = 0.04
	var center := CylinderMesh.new()
	center.top_radius = 0.18 if not is_tree_mounted() else 0.08
	center.bottom_radius = center.top_radius
	center.height = 0.02
	label_mesh.mesh = center
	var center_mat := mat.duplicate() as StandardMaterial3D
	center_mat.albedo_color = Color(0.4, 0.9, 0.48, 0.7)
	label_mesh.material_override = center_mat
	label_mesh.visible = false
	_marker.add_child(label_mesh)


func _update_highlight() -> void:
	if _marker == null:
		_build_marker()
	if _marker:
		var show_ring := _compatible and not _has_colony
		_marker.visible = show_ring
		var center := _marker.get_node_or_null("MarkerCenter") as MeshInstance3D
		if center:
			center.visible = show_ring
		if _has_colony and _compatible:
			var mat := _marker.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color = Color(0.55, 0.45, 0.28, 0.5)


func _on_body_entered(_body: Node3D) -> void:
	pass
