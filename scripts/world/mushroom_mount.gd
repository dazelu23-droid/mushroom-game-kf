class_name MushroomMount
extends RefCounted

## Orients fruiting bodies as horizontal bracket shelves on tree trunks.


static func apply_to_node(node: Node3D, patch: SubstratePatch, species: Dictionary = {}) -> void:
	if patch == null or not is_instance_valid(patch):
		return
	if patch.is_tree_mounted():
		var basis := patch.get_fruiting_basis(species)
		node.global_transform = Transform3D(basis, patch.get_landing_position())
	else:
		node.global_position = patch.get_landing_position()
