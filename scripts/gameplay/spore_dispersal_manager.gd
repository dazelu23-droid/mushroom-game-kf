class_name SporeDispersalManager
extends Node3D

signal colony_spawned(total: int)

const AirborneSpore := preload("res://scripts/gameplay/airborne_spore.gd")
const GROWTH_SCENE := preload("res://scenes/mushroom_growth.tscn")

@export var max_colonies: int = 14
@export var release_interval: float = 0.75
@export var max_travel_distance: float = 36.0
@export var min_travel_distance: float = 3.0
@export var colony_growth_speed_scale: float = 3.0
@export var child_spore_release_duration: float = 5.0

var _species: Dictionary = {}
var _growth_template: MushroomGrowthVisual
var _colony_root: Node3D
var _spawned_colonies: Array[MushroomGrowthVisual] = []
var _release_sources: Array[Dictionary] = []
var _release_timer := 0.0
var _rng := RandomNumberGenerator.new()


func setup(growth_template: MushroomGrowthVisual, species: Dictionary) -> void:
	_growth_template = growth_template
	_species = species.duplicate()
	_rng.randomize()
	if _colony_root == null:
		_colony_root = Node3D.new()
		_colony_root.name = "SpawnedColonies"
		add_child(_colony_root)


func register_release_source(get_origin: Callable, duration: float) -> void:
	_release_sources.append({
		"get_origin": get_origin,
		"until": Time.get_ticks_msec() / 1000.0 + duration,
	})


func _process(delta: float) -> void:
	_prune_release_sources()
	if _release_sources.is_empty():
		return
	_release_timer += delta
	if _release_timer < release_interval:
		return
	_release_timer = 0.0
	if _spawned_colonies.size() >= max_colonies:
		return
	for source in _release_sources:
		var origin: Variant = source.get_origin.call()
		if origin is Vector3:
			_try_dispatch_spore(origin as Vector3)


func _prune_release_sources() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var active: Array[Dictionary] = []
	for source in _release_sources:
		if float(source.get("until", 0.0)) > now:
			active.append(source)
	_release_sources = active


func _try_dispatch_spore(origin: Vector3) -> void:
	if _spawned_colonies.size() >= max_colonies:
		return
	var patch := _pick_target_patch(origin)
	if patch == null:
		return
	_spawn_airborne_spore(origin, patch)


func _pick_target_patch(origin: Vector3) -> SubstratePatch:
	var substrates: Array = MushroomSpeciesData.get_substrates(_species)
	var candidates: Array[SubstratePatch] = []
	for node in get_tree().get_nodes_in_group("substrate"):
		var patch := node as SubstratePatch
		if patch == null or patch.has_colony():
			continue
		if patch.get_substrate_type() not in substrates:
			continue
		var dist := Vector2(origin.x - patch.global_position.x, origin.z - patch.global_position.z).length()
		if dist < min_travel_distance or dist > max_travel_distance:
			continue
		candidates.append(patch)
	if candidates.is_empty():
		return null
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _spawn_airborne_spore(from: Vector3, patch: SubstratePatch) -> void:
	var spore := AirborneSpore.new()
	add_child(spore)
	spore.launch(from + Vector3(_rng.randf_range(-0.2, 0.2), 0.15, _rng.randf_range(-0.2, 0.2)), patch)
	spore.arrived.connect(_on_spore_arrived)


func _on_spore_arrived(patch: SubstratePatch) -> void:
	if patch == null or patch.has_colony():
		return
	if _spawned_colonies.size() >= max_colonies:
		return
	if not patch.claim_colony():
		return
	_spawn_colony(patch)


func _spawn_colony(patch: SubstratePatch) -> void:
	var colony := GROWTH_SCENE.instantiate() as MushroomGrowthVisual
	if colony == null:
		patch.release_colony()
		return
	_colony_root.add_child(colony)
	var land_pos := patch.get_landing_position()
	colony.setup_colony(land_pos, _species, patch, colony_growth_speed_scale)
	colony.register_spectate_target()
	colony.growth_complete.connect(_on_colony_matured.bind(colony))
	_spawned_colonies.append(colony)
	GameState.set_colony_counts(_spawned_colonies.size(), _count_mature_colonies())
	colony_spawned.emit(_spawned_colonies.size())


func _on_colony_matured(colony: MushroomGrowthVisual) -> void:
	GameState.set_colony_counts(_spawned_colonies.size(), _count_mature_colonies())
	register_release_source(Callable(colony, "get_cap_position"), child_spore_release_duration)


func _count_mature_colonies() -> int:
	var count := 0
	for colony in _spawned_colonies:
		if colony and is_instance_valid(colony) and not colony.is_growing():
			count += 1
	return count


func get_spawned_colonies() -> Array[MushroomGrowthVisual]:
	return _spawned_colonies.duplicate()


func claim_patch_near(world_pos: Vector3, radius: float = 2.8) -> void:
	for node in get_tree().get_nodes_in_group("substrate"):
		var patch := node as SubstratePatch
		if patch == null:
			continue
		var dist := Vector2(world_pos.x - patch.global_position.x, world_pos.z - patch.global_position.z).length()
		if dist <= radius:
			patch.claim_colony()
			return
