class_name NutrientScatter
extends Node3D

const NUTRIENT_SOURCE_SCRIPT := preload("res://scripts/gameplay/nutrient_source.gd")

const NUTRIENT_DEFS: Array[Dictionary] = [
	{"type": "lignocellulose", "amount": 40.0, "label": "Decaying oak log (lignin + cellulose)"},
	{"type": "cellulose", "amount": 30.0, "label": "Decaying leaf litter"},
	{"type": "hemicellulose", "amount": 25.0, "label": "Hardwood sawdust chips"},
	{"type": "lignin", "amount": 35.0, "label": "Rotting stump (lignin)"},
]

@export var source_count: int = 10
@export var scatter_radius: float = 24.0

var _rng := RandomNumberGenerator.new()


func scatter_near_substrates(substrates: Node3D) -> void:
	_rng.randomize()
	for child in get_children():
		child.queue_free()

	var positions: Array[Vector3] = []
	for patch_root in substrates.get_children():
		positions.append(patch_root.global_position)

	if positions.is_empty():
		return

	for i in source_count:
		var base_pos: Vector3 = positions[_rng.randi_range(0, positions.size() - 1)]
		var offset := Vector3(
			_rng.randf_range(-2.5, 2.5),
			0.0,
			_rng.randf_range(-2.5, 2.5)
		)
		var pos := base_pos + offset
		if Vector2(pos.x, pos.z).length() > scatter_radius:
			continue
		var def: Dictionary = NUTRIENT_DEFS[i % NUTRIENT_DEFS.size()]
		_create_source(pos, def)


func _create_source(world_pos: Vector3, def: Dictionary) -> void:
	var nutrient_type: String = def.get("type", "")
	var nutrient_amount: float = float(def.get("amount", 25.0))
	var label_text: String = def.get("label", "")

	var root := Node3D.new()
	root.name = "NutrientSource_%s" % nutrient_type
	root.position = world_pos
	add_child(root)

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.2, 2.2)
	mesh_inst.mesh = plane
	mesh_inst.position.y = 0.08
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.26, 0.17)
	mat.roughness = 0.82
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = 0.25
	mat.subsurf_scatter_transmittance_enabled = true
	mat.subsurf_scatter_transmittance_color = Color(0.55, 0.38, 0.22)
	mat.subsurf_scatter_transmittance_depth = 0.15
	mesh_inst.material_override = mat
	root.add_child(mesh_inst)

	var area := Area3D.new()
	area.name = "NutrientSource"
	area.set_script(NUTRIENT_SOURCE_SCRIPT)
	root.add_child(area)

	var source := area as NutrientSource
	if source:
		source.nutrient_type = nutrient_type
		source.nutrient_amount = nutrient_amount
		source.label_text = label_text

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 0.5, 2.4)
	col.shape = shape
	area.add_child(col)
