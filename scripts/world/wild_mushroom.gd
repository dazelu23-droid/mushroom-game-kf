class_name WildMushroom
extends Node3D

var species: Dictionary = {}
var cap_height: float = 0.35


func get_spectate_label() -> String:
	return "%s (wild)" % species.get("common_name", "Mushroom")


func get_spectate_focus() -> Vector3:
	var mesh := get_node_or_null("MushroomMesh") as MeshInstance3D
	if mesh and mesh.mesh:
		var aabb := mesh.mesh.get_aabb()
		return mesh.global_transform * Vector3(
			aabb.get_center().x,
			aabb.position.y + aabb.size.y * 0.85,
			aabb.get_center().z
		)
	return global_position + Vector3.UP * cap_height
