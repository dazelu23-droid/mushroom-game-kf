class_name SubstratePatch
extends Area3D

@export var substrate_type: String = "leaf_litter"
@export var substrate_label: String = "Leaf litter"

var _compatible := false
var _marker: MeshInstance3D


func _ready() -> void:
	add_to_group("substrate")
	body_entered.connect(_on_body_entered)
	_apply_realistic_material()
	_build_marker()
	_update_highlight()


func get_substrate_type() -> String:
	return substrate_type


func set_compatible(compatible: bool) -> void:
	_compatible = compatible
	if is_node_ready():
		_update_highlight()


func _apply_realistic_material() -> void:
	var mesh := get_parent().get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.94
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	match substrate_type:
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
	ring.inner_radius = 1.35
	ring.outer_radius = 1.52
	ring.rings = 8
	ring.ring_segments = 24
	_marker.mesh = ring
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
	center.top_radius = 0.18
	center.bottom_radius = 0.18
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
		_marker.visible = _compatible
		var center := _marker.get_node_or_null("MarkerCenter") as MeshInstance3D
		if center:
			center.visible = _compatible


func _on_body_entered(_body: Node3D) -> void:
	pass
