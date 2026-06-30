class_name WildMushroomScatter
extends Node3D

const MushroomMeshLoader := preload("res://scripts/visuals/mushroom_mesh_loader.gd")

@export var wild_count: int = 9
@export var mushroom_height: float = 0.46

var _rng := RandomNumberGenerator.new()


func scatter(_substrates: Node3D, exclude_species_id: String = "") -> void:
	_rng.randomize()
	for child in get_children():
		child.queue_free()

	var patches: Array[SubstratePatch] = []
	for node in get_tree().get_nodes_in_group("substrate"):
		var patch := node as SubstratePatch
		if patch and not patch.has_colony():
			patches.append(patch)
	patches.shuffle()

	var placed := 0
	var species_pool: Array[Dictionary] = []
	for entry in MushroomSpeciesData.SPECIES:
		if entry.get("id", "") != exclude_species_id:
			species_pool.append(entry.duplicate())

	if species_pool.is_empty() or patches.is_empty():
		return

	species_pool.shuffle()
	var patch_idx := 0
	while placed < wild_count and patch_idx < patches.size():
		var patch := patches[patch_idx]
		patch_idx += 1
		var species: Dictionary = species_pool[placed % species_pool.size()]
		if not MushroomSpeciesData.has_substrate(species, patch.get_substrate_type()):
			continue
		if _spawn_wild_mushroom(patch, species):
			placed += 1


func _spawn_wild_mushroom(patch: SubstratePatch, species: Dictionary) -> bool:
	if not patch.claim_colony():
		return false

	var anchor := Node3D.new()
	anchor.set_script(preload("res://scripts/world/wild_mushroom.gd"))
	anchor.name = "Wild_%s" % species.get("id", "mushroom")
	anchor.position = Vector3(
		patch.global_position.x,
		patch.global_position.y + 0.08,
		patch.global_position.z
	)
	add_child(anchor)
	anchor.species = species.duplicate()

	var mesh_name: String = species.get("mesh_name", "mushroom_01")
	var loaded: Dictionary = MushroomMeshLoader.create_display(mesh_name, mushroom_height, anchor, 0.12)
	if loaded.is_empty():
		patch.release_colony()
		anchor.queue_free()
		return false

	var display: MeshInstance3D = loaded.get("mesh_instance") as MeshInstance3D
	if display:
		display.name = "MushroomMesh"
	anchor.cap_height = float(loaded.get("cap_height", mushroom_height * 0.75))
	anchor.add_to_group("spectate_target")
	return true
