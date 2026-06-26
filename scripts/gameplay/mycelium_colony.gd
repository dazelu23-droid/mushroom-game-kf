class_name MyceliumColony
extends Node3D

## Dikaryotic mycelium with apical tip growth, chemotaxis, and enzyme-gated nutrient uptake.
## Hyphae are scaled up from real ~1–10 µm diameter for visibility.

signal colonization_ready
signal grow_state_changed(is_growing: bool)

class HyphaTip:
	var position: Vector3 = Vector3.ZERO
	var direction: Vector3 = Vector3(0.0, -0.15, 1.0).normalized()
	var depth: int = 0
	var energy: float = 1.0


@export var growth_speed: float = 3.8
@export var max_branches: int = 160
@export var tip_search_range: float = 14.0
@export var absorb_range: float = 3.0
@export var branch_chance: float = 0.14
@export var chemotaxis_strength: float = 0.72
@export var tortuosity: float = 0.35

var _tips: Array[HyphaTip] = []
var _nutrient_sources: Array[NutrientSource] = []
var _active := false
var _grow_requested := false
var _rng := RandomNumberGenerator.new()
var _colonization_signaled := false
var _hypha_material: StandardMaterial3D
var _tip_glow_material: StandardMaterial3D
var _hypha_root: Node3D
var _tip_glows: Node3D
var _branch_count := 0
var _species: Dictionary = {}


func _ready() -> void:
	_hypha_root = Node3D.new()
	_hypha_root.name = "Hyphae"
	add_child(_hypha_root)
	_tip_glows = Node3D.new()
	_tip_glows.name = "TipGlows"
	add_child(_tip_glows)
	_build_materials()


func setup(origin: Vector3, nutrients: Array[NutrientSource]) -> void:
	for child in _hypha_root.get_children():
		child.queue_free()
	for child in _tip_glows.get_children():
		child.queue_free()
	_tips.clear()
	_branch_count = 0
	position = origin
	_nutrient_sources = nutrients
	_species = GameState.selected_species
	_rng.randomize()
	_create_initial_hypha()


func activate() -> void:
	_active = true
	_colonization_signaled = false
	visible = true


func deactivate() -> void:
	_active = false
	_grow_requested = false
	_clear_tip_glows()
	grow_state_changed.emit(false)


func set_grow_active(active: bool) -> void:
	_grow_requested = active
	grow_state_changed.emit(_is_growing())


func is_grow_active() -> bool:
	return _grow_requested


func _build_materials() -> void:
	_hypha_material = StandardMaterial3D.new()
	_hypha_material.albedo_color = Color(0.94, 0.91, 0.84, 0.92)
	_hypha_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hypha_material.roughness = 0.28
	_hypha_material.metallic = 0.0
	_hypha_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_hypha_material.subsurface_scattering_enabled = true
	_hypha_material.subsurface_scattering_strength = 0.55
	_hypha_material.transmittance_enabled = true
	_hypha_material.transmittance_color = Color(0.98, 0.9, 0.78)
	_hypha_material.transmittance_depth = 0.08
	_hypha_material.clearcoat_enabled = true
	_hypha_material.clearcoat = 0.22
	_hypha_material.clearcoat_roughness = 0.18

	_tip_glow_material = StandardMaterial3D.new()
	_tip_glow_material.albedo_color = Color(0.98, 0.95, 0.82, 0.75)
	_tip_glow_material.emission_enabled = true
	_tip_glow_material.emission = Color(0.85, 0.95, 0.7)
	_tip_glow_material.emission_energy_multiplier = 1.8
	_tip_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tip_glow_material.roughness = 0.15


func _create_initial_hypha() -> void:
	var tip := HyphaTip.new()
	tip.position = Vector3.ZERO
	tip.direction = Vector3(0.0, -0.2, 0.85).normalized()
	tip.depth = 0
	_tips.append(tip)
	_add_hypha_segment(Vector3.ZERO, Vector3(0.0, -0.01, 0.12), 0)


func _physics_process(delta: float) -> void:
	if not _active:
		return

	var growing := _is_growing()
	if growing and _branch_count < max_branches:
		_grow_step(delta)
		_update_tip_glows(true)
	else:
		_update_tip_glows(false)

	if GameState.colonization_percent >= 80.0 and not _colonization_signaled:
		_colonization_signaled = true
		colonization_ready.emit()


func _is_growing() -> bool:
	return Input.is_action_pressed("grow_mycelium") or _grow_requested


func _grow_step(delta: float) -> void:
	var new_tips: Array[HyphaTip] = []
	var temp_c: float = GameState.temperature_c
	var colon_temp: Vector2 = MushroomSpeciesData.get_vector2(
		_species, "colonization_temp_c", Vector2(12.0, 24.0)
	)
	var temp_factor := _temperature_growth_factor(temp_c, colon_temp)

	for tip in _tips:
		var nutrient := _find_nearest_nutrient_for_tip(tip)
		if nutrient == null:
			_explore_step(tip, delta, temp_factor, new_tips)
			continue

		var target := to_local(nutrient.global_position)
		var to_target := target - tip.position
		var dist := to_target.length()
		if dist < 0.02:
			continue

		var desired_dir := to_target.normalized()
		desired_dir.y = clampf(desired_dir.y, -0.18, 0.06)
		tip.direction = tip.direction.lerp(desired_dir, chemotaxis_strength * delta * 4.5).normalized()
		tip.direction = tip.direction.rotated(
			Vector3.UP,
			_rng.randf_range(-tortuosity, tortuosity) * delta * 6.0
		).normalized()

		var efficiency := MushroomSpeciesData.digest_efficiency(
			_species, nutrient.get_nutrient_type()
		)
		var speed_boost := 1.0 + efficiency * 0.35
		if dist < absorb_range:
			speed_boost += 0.4

		var length := growth_speed * temp_factor * speed_boost * delta * _rng.randf_range(0.55, 1.0)
		var end := tip.position + tip.direction * length
		_add_hypha_segment(tip.position, end, tip.depth)
		tip.position = end
		tip.depth += 1
		new_tips.append(tip)

		if tip.depth > 2 and _rng.randf() < branch_chance and _branch_count < max_branches - 1:
			var branch := HyphaTip.new()
			branch.position = tip.position
			var branch_angle := _rng.randf_range(0.45, 1.1) * (1.0 if _rng.randf() > 0.5 else -1.0)
			branch.direction = tip.direction.rotated(Vector3.UP, branch_angle).normalized()
			branch.direction.y = clampf(branch.direction.y, -0.12, 0.04)
			branch.depth = tip.depth
			branch.energy = tip.energy * 0.7
			var branch_end := branch.position + branch.direction * length * 0.65
			_add_hypha_segment(branch.position, branch_end, branch.depth)
			branch.position = branch_end
			branch.depth += 1
			new_tips.append(branch)

		if dist <= absorb_range:
			var absorb_rate := 2.8 * efficiency * delta * speed_boost
			var absorbed: float = nutrient.absorb(absorb_rate)
			if absorbed > 0.0:
				GameState.add_nutrients(absorbed)
				GameState.set_colonization(
					GameState.colonization_percent + absorbed * 0.18 * efficiency
				)
				nutrient.pulse_absorption(absorbed)

	_tips = new_tips
	if _tips.is_empty():
		_create_initial_hypha()


func _explore_step(tip: HyphaTip, delta: float, temp_factor: float, new_tips: Array[HyphaTip]) -> void:
	tip.direction = tip.direction.rotated(
		Vector3.UP,
		_rng.randf_range(-0.8, 0.8) * delta * 2.5
	).normalized()
	tip.direction.y = clampf(tip.direction.y, -0.2, 0.02)
	var length := growth_speed * temp_factor * 0.35 * delta
	var end := tip.position + tip.direction * length
	_add_hypha_segment(tip.position, end, tip.depth)
	tip.position = end
	tip.depth += 1
	new_tips.append(tip)


func _temperature_growth_factor(temp_c: float, optimal: Vector2) -> float:
	var mid := (optimal.x + optimal.y) * 0.5
	var half_span := maxf((optimal.y - optimal.x) * 0.5, 1.0)
	var deviation := absf(temp_c - mid) / half_span
	return clampf(1.15 - deviation * 0.55, 0.35, 1.15)


func _find_nearest_nutrient_for_tip(tip: HyphaTip) -> NutrientSource:
	var best: NutrientSource = null
	var best_score := INF
	var tip_world := global_position + tip.position
	for source in _nutrient_sources:
		if source.is_depleted():
			continue
		var dist := tip_world.distance_to(source.global_position)
		if dist > tip_search_range:
			continue
		var efficiency := MushroomSpeciesData.digest_efficiency(
			_species, source.get_nutrient_type()
		)
		var score := dist / maxf(efficiency, 0.15)
		if score < best_score:
			best_score = score
			best = source
	return best


func _add_hypha_segment(start: Vector3, end: Vector3, depth: int) -> void:
	var segment_length := start.distance_to(end)
	if segment_length < 0.008:
		return

	var depth_t := clampf(1.0 - float(depth) / 28.0, 0.3, 1.0)
	var bottom_r := lerpf(0.005, 0.024, depth_t) * _rng.randf_range(0.92, 1.05)
	var top_r := bottom_r * _rng.randf_range(0.72, 0.88)

	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = segment_length
	mesh.radial_segments = 10
	mesh.rings = 2
	mesh_instance.mesh = mesh

	var mat := _hypha_material.duplicate() as StandardMaterial3D
	var shade := _rng.randf_range(0.96, 1.04)
	mat.albedo_color = Color(
		0.94 * shade, 0.9 * shade, 0.82 * shade, 0.9
	)
	mesh_instance.material_override = mat

	var mid := (start + end) * 0.5
	mesh_instance.position = mid
	mesh_instance.look_at(end, Vector3.UP)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI * 0.5)

	_hypha_root.add_child(mesh_instance)
	_branch_count += 1


func _update_tip_glows(show: bool) -> void:
	_clear_tip_glows()
	if not show:
		return
	for tip in _tips:
		var glow := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.018
		sphere.height = 0.036
		sphere.radial_segments = 8
		sphere.rings = 4
		glow.mesh = sphere
		glow.material_override = _tip_glow_material
		glow.position = tip.position
		_tip_glows.add_child(glow)


func _clear_tip_glows() -> void:
	for child in _tip_glows.get_children():
		child.queue_free()
