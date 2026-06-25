class_name SubstratePatch
extends Area3D

@export var substrate_type: String = "leaf_litter"
@export var substrate_label: String = "Leaf litter"

var _compatible := false


func _ready() -> void:
	add_to_group("substrate")
	body_entered.connect(_on_body_entered)
	_apply_realistic_material()
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
	match substrate_type:
		"dead_hardwood":
			mat.albedo_color = Color(0.28, 0.19, 0.12)
			mat.roughness = 0.94
		"leaf_litter":
			mat.albedo_color = Color(0.32, 0.24, 0.14)
			mat.roughness = 0.98
		"forest_soil":
			mat.albedo_color = Color(0.18, 0.14, 0.1)
			mat.roughness = 1.0
		"compost", "manure_compost":
			mat.albedo_color = Color(0.24, 0.2, 0.14)
			mat.roughness = 0.96
		"straw":
			mat.albedo_color = Color(0.45, 0.38, 0.2)
			mat.roughness = 0.92
		"grassland_soil":
			mat.albedo_color = Color(0.26, 0.32, 0.16)
			mat.roughness = 0.97
		"hardwood_sawdust":
			mat.albedo_color = Color(0.35, 0.28, 0.18)
			mat.roughness = 0.95
		_:
			mat.albedo_color = Color(0.3, 0.25, 0.18)
			mat.roughness = 0.95
	mesh.set_surface_override_material(0, mat)


func _update_highlight() -> void:
	var mesh := get_parent().get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		_apply_realistic_material()
		mat = mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	if _compatible:
		mat.emission_enabled = true
		mat.emission = Color(0.12, 0.55, 0.18)
		mat.albedo_color = mat.albedo_color.lerp(Color(0.22, 0.48, 0.2), 0.45)
	else:
		mat.emission_enabled = false


func _on_body_entered(_body: Node3D) -> void:
	pass
