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

	var ground_patches: Array[SubstratePatch] = []
	var tree_patches: Array[SubstratePatch] = []
	for node in get_tree().get_nodes_in_group("substrate"):
		var patch := node as SubstratePatch
		if patch == null or patch.has_colony():
			continue
		if patch.is_tree_mounted():
			tree_patches.append(patch)
		else:
			ground_patches.append(patch)
	ground_patches.shuffle()
	tree_patches.shuffle()

	var species_pool: Array[Dictionary] = []
	for entry in MushroomSpeciesData.SPECIES:
		if entry.get("id", "") != exclude_species_id:
			species_pool.append(entry.duplicate())
	if species_pool.is_empty():
		return

	var placed := 0
	var tree_idx := 0
	var ground_idx := 0
	while placed < wild_count and (tree_idx < tree_patches.size() or ground_idx < ground_patches.size()):
		var use_tree := tree_idx < tree_patches.size() and (
			ground_idx >= ground_patches.size() or _rng.randf() < 0.45
		)
		var patch: SubstratePatch = tree_patches[tree_idx] if use_tree else ground_patches[ground_idx]
		if use_tree:
			tree_idx += 1
		else:
			ground_idx += 1

		var species := _pick_species_for_patch(patch, species_pool, placed)
		if not MushroomSpeciesData.has_substrate(species, patch.get_substrate_type()):
			continue
		if _spawn_wild_mushroom(patch, species):
			placed += 1


func _pick_species_for_patch(patch: SubstratePatch, pool: Array[Dictionary], index: int) -> Dictionary:
	if patch.is_tree_mounted():
		var tree_species: Array[Dictionary] = []
		for species in pool:
			if MushroomSpeciesData.is_tree_dweller(species):
				tree_species.append(species)
		if not tree_species.is_empty():
			return tree_species[index % tree_species.size()]
	var compatible: Array[Dictionary] = []
	for species in pool:
		if MushroomSpeciesData.has_substrate(species, patch.get_substrate_type()):
			if not patch.is_tree_mounted() or not MushroomSpeciesData.is_tree_dweller(species):
				compatible.append(species)
	if compatible.is_empty():
		return pool[index % pool.size()]
	return compatible[index % compatible.size()]


func _spawn_wild_mushroom(patch: SubstratePatch, species: Dictionary) -> bool:
	if not patch.claim_colony():
		return false

	var anchor := Node3D.new()
	anchor.set_script(preload("res://scripts/world/wild_mushroom.gd"))
	anchor.name = "Wild_%s" % species.get("id", "mushroom")
	add_child(anchor)
	MushroomMount.apply_to_node(anchor, patch, species)
	anchor.species = species.duplicate()

	var mesh_name: String = species.get("mesh_name", "mushroom_01")
	var lift := 0.0 if patch.is_tree_mounted() else 0.12
	var loaded: Dictionary = MushroomMeshLoader.create_display(mesh_name, mushroom_height, anchor, lift)
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
