class_name SubstrateScatter
extends Node3D

const PATCH_SCENE_SIZE := 3.2
const SUBSTRATE_PATCH_SCRIPT := preload("res://scripts/gameplay/substrate_patch.gd")

const PATCH_DEFINITIONS: Array[Dictionary] = [
	{"type": "forest_soil", "label": "Forest soil (mycorrhizal)", "shape": "plane"},
	{"type": "leaf_litter", "label": "Leaf litter layer", "shape": "plane"},
	{"type": "dead_hardwood", "label": "Decaying hardwood log", "shape": "log"},
	{"type": "compost", "label": "Fermented compost", "shape": "mound"},
	{"type": "straw", "label": "Pasteurized straw", "shape": "plane"},
	{"type": "grassland_soil", "label": "Grassy forest clearing", "shape": "plane"},
	{"type": "hardwood_sawdust", "label": "Hardwood sawdust bed", "shape": "plane"},
]

@export var patch_count: int = 14
@export var scatter_radius: float = 26.0
@export var min_patch_spacing: float = 7.5
@export var center_clear_radius: float = 4.0

var _rng := RandomNumberGenerator.new()
var _placed_positions: Array[Vector2] = []


func scatter(terrain_height: Callable = Callable()) -> void:
	_rng.randomize()
	_placed_positions.clear()
	for child in get_children():
		child.queue_free()

	var types_pool: Array[Dictionary] = []
	for def in PATCH_DEFINITIONS:
		types_pool.append(def.duplicate())
	types_pool.shuffle()

	var placed := 0
	var attempts := 0
	while placed < patch_count and attempts < patch_count * 30:
		attempts += 1
		var angle := _rng.randf_range(0.0, TAU)
		var dist := _rng.randf_range(center_clear_radius + 2.0, scatter_radius)
		var pos := Vector2(cos(angle) * dist, sin(angle) * dist)
		if not _is_valid_position(pos):
			continue

		var def: Dictionary = types_pool[placed % types_pool.size()]
		var world_pos := Vector3(pos.x, 0.0, pos.y)
		if terrain_height.is_valid():
			world_pos.y = terrain_height.call(pos.x, pos.y)
		_create_patch(world_pos, def)
		_placed_positions.append(pos)
		placed += 1


func _is_valid_position(pos: Vector2) -> bool:
	if pos.length() < center_clear_radius:
		return false
	for existing in _placed_positions:
		if pos.distance_to(existing) < min_patch_spacing:
			return false
	return true


func _create_patch(world_pos: Vector3, def: Dictionary) -> void:
	var substrate_type: String = def.get("type", "")
	var substrate_label: String = def.get("label", "")
	var shape: String = def.get("shape", "plane")

	var root := Node3D.new()
	root.name = substrate_type
	var y_offset := 0.04
	match shape:
		"log":
			y_offset = 0.18
		"mound":
			y_offset = 0.05
	root.position = Vector3(world_pos.x, world_pos.y + y_offset, world_pos.z)
	add_child(root)

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	match shape:
		"log":
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.22
			cyl.bottom_radius = 0.28
			cyl.height = _rng.randf_range(2.4, 3.6)
			cyl.radial_segments = 12
			mesh_inst.mesh = cyl
			mesh_inst.rotation.z = PI * 0.5
			mesh_inst.rotation.y = _rng.randf_range(0.0, TAU)
		"mound":
			var sph := SphereMesh.new()
			sph.radius = _rng.randf_range(1.1, 1.5)
			sph.height = sph.radius * 0.5
			mesh_inst.mesh = sph
			mesh_inst.position.y = sph.radius * 0.25
		_:
			var plane := PlaneMesh.new()
			plane.size = Vector2(PATCH_SCENE_SIZE, PATCH_SCENE_SIZE)
			plane.subdivide_width = 2
			plane.subdivide_depth = 2
			mesh_inst.mesh = plane
	root.add_child(mesh_inst)

	var area := Area3D.new()
	area.name = "Area"
	area.set_script(SUBSTRATE_PATCH_SCRIPT)
	root.add_child(area)

	var patch := area as SubstratePatch
	if patch:
		patch.substrate_type = substrate_type
		patch.substrate_label = substrate_label

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	match shape:
		"log":
			box.size = Vector3(3.2, 0.7, 0.7)
			area.position.y = 0.2
		"mound":
			box.size = Vector3(3.0, 1.2, 3.0)
		_:
			box.size = Vector3(PATCH_SCENE_SIZE + 0.4, 0.6, PATCH_SCENE_SIZE + 0.4)
	col.shape = box
	area.add_child(col)
