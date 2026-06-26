class_name TreeSporeFade
extends Node

## Fades nearby or camera-blocking trees during spore drift so the player stays visible.

@export var proximity_radius: float = 10.0
@export var occlusion_width: float = 3.2
@export var foliage_faded_alpha: float = 0.12
@export var bark_faded_alpha: float = 0.32
@export var fade_speed: float = 6.0

var _entries: Array[Dictionary] = []
var _collected := false


func _ready() -> void:
	call_deferred("_collect_tree_meshes")


func _collect_tree_meshes() -> void:
	if _collected:
		return
	var trees_root := get_parent().get_node_or_null("Trees") as Node3D
	if trees_root == null:
		return
	for tree in trees_root.get_children():
		if not tree is Node3D:
			continue
		tree.add_to_group("forest_tree")
		for child in tree.get_children():
			if child is MeshInstance3D:
				_register_mesh(child as MeshInstance3D)
	_collected = true


func _register_mesh(mesh_inst: MeshInstance3D) -> void:
	var mat := mesh_inst.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	var is_foliage := "Foliage" in mesh_inst.name
	_entries.append({
		"mesh": mesh_inst,
		"base_color": mat.albedo_color,
		"is_foliage": is_foliage,
		"fade": 0.0,
	})


func _process(delta: float) -> void:
	if not _collected:
		_collect_tree_meshes()
		return

	var active := GameState.current_phase == LifeCycle.Phase.SPORE_DISPERSAL
	var spore := get_tree().get_first_node_in_group("spore_player") as Node3D
	var camera := get_viewport().get_camera_3d()

	if not active or spore == null or not spore.visible:
		_apply_fade(0.0, delta)
		return

	var spore_pos := spore.global_position
	var cam_pos := camera.global_position if camera else spore_pos + Vector3(0, 2, 6)

	for entry in _entries:
		var mesh_inst: MeshInstance3D = entry.get("mesh")
		if not is_instance_valid(mesh_inst):
			continue
		var target_fade := _compute_fade(mesh_inst.global_position, spore_pos, cam_pos, bool(entry.get("is_foliage")))
		entry["fade"] = lerpf(float(entry.get("fade", 0.0)), target_fade, fade_speed * delta)
		_apply_entry_alpha(entry)


func _compute_fade(tree_pos: Vector3, spore_pos: Vector3, cam_pos: Vector3, is_foliage: bool) -> float:
	var horizontal := Vector2(tree_pos.x - spore_pos.x, tree_pos.z - spore_pos.z).length()
	var proximity := 1.0 - clampf(horizontal / proximity_radius, 0.0, 1.0)
	proximity = proximity * proximity

	var occlusion := 0.0
	var view := spore_pos - cam_pos
	var view_len_sq := view.length_squared()
	if view_len_sq > 0.25:
		var to_tree := tree_pos - cam_pos
		var t := to_tree.dot(view) / view_len_sq
		if t > 0.08 and t < 0.92:
			var closest := cam_pos + view * t
			var perp := tree_pos.distance_to(closest)
			var width := occlusion_width if is_foliage else occlusion_width * 0.65
			if perp < width:
				occlusion = 1.0 - perp / width
				occlusion *= occlusion

	return clampf(maxf(proximity * 0.9, occlusion), 0.0, 1.0)


func _apply_fade(target: float, delta: float) -> void:
	for entry in _entries:
		entry["fade"] = lerpf(float(entry.get("fade", 0.0)), target, fade_speed * delta)
		_apply_entry_alpha(entry)


func _apply_entry_alpha(entry: Dictionary) -> void:
	var mesh_inst: MeshInstance3D = entry.get("mesh")
	if not is_instance_valid(mesh_inst):
		return
	var mat := mesh_inst.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	var base: Color = entry.get("base_color", Color.WHITE)
	var fade: float = entry.get("fade", 0.0)
	var min_alpha := foliage_faded_alpha if entry.get("is_foliage") else bark_faded_alpha
	mat.albedo_color = Color(base.r, base.g, base.b, lerpf(base.a, min_alpha, fade))
	if fade > 0.02:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
