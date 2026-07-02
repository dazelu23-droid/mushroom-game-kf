class_name MushroomGrowthVisual
extends Node3D

## Biologically accurate staged growth:
## hyphal knot (0.5mm) -> primordium (1-5mm) -> pin -> stipe elongation -> cap expansion -> adult model

signal growth_complete

const MushroomMeshLoader := preload("res://scripts/visuals/mushroom_mesh_loader.gd")

@export var adult_height_scale: float = 1.0
@export var ground_clearance: float = 0.06
@export var spawned_colony_speed_scale: float = 3.0
@export var spawned_colony_spore_duration: float = 5.0

const _FINAL_STIPE_SCALE_Y := 0.45
const _FINAL_STIPE_POS_Y := 0.05
const _FINAL_STIPE_MESH_H := 1.0
const _FINAL_CAP_POS_OFFSET := 0.04
const _FINAL_CAP_SCALE_Y := 0.12
const _FINAL_CAP_MESH_H := 0.35

enum GrowthStage {
	HYPHAL_KNOT,
	PRIMORDIUM,
	PIN,
	STIPE_ELONGATION,
	CAP_EXPANSION,
	MATURE,
}

var _stage: GrowthStage = GrowthStage.HYPHAL_KNOT
var _progress := 0.0
var _active := false
var _adult_shown := false
var _adult_cap_height := 0.8
var _adult_mesh: MeshInstance3D
var _species_override: Dictionary = {}
var _growth_speed_scale: float = 1.0
var _is_spawned_colony := false
var _substrate_patch: SubstratePatch

@onready var _procedural_root: Node3D = $ProceduralRoot
@onready var _knot: MeshInstance3D = $ProceduralRoot/HyphalKnot
@onready var _primordium: MeshInstance3D = $ProceduralRoot/Primordium
@onready var _pin_stipe: MeshInstance3D = $ProceduralRoot/Pin/Stipe
@onready var _pin_cap: MeshInstance3D = $ProceduralRoot/Pin/Cap
@onready var _adult_slot: Node3D = $AdultSlot


func setup(origin: Vector3, patch: SubstratePatch = null) -> void:
	_substrate_patch = patch
	if patch and patch.is_tree_mounted():
		var basis := patch.get_fruiting_basis(_get_species())
		global_transform = Transform3D(basis, patch.get_landing_position())
	else:
		global_position = origin
	_reset_visuals()


func setup_colony(
	origin: Vector3,
	species: Dictionary,
	patch: SubstratePatch = null,
	speed_scale: float = -1.0
) -> void:
	_species_override = species.duplicate()
	_is_spawned_colony = true
	_substrate_patch = patch
	_growth_speed_scale = speed_scale if speed_scale > 0.0 else spawned_colony_speed_scale
	if patch and not patch.has_colony():
		patch.claim_colony()
	if patch and patch.is_tree_mounted():
		setup(origin, patch)
	else:
		setup(origin)
	activate()


func activate() -> void:
	_active = true
	visible = true
	_stage = GrowthStage.HYPHAL_KNOT
	_progress = 0.0
	_reset_visuals()
	if _is_spawned_colony:
		register_spectate_target()


func is_growing() -> bool:
	return _active


func _reset_visuals() -> void:
	_adult_shown = false
	_procedural_root.visible = true
	_knot.visible = true
	_knot.scale = Vector3.ONE * 0.01
	_primordium.visible = false
	_primordium.scale = Vector3.ONE * 0.02
	_pin_stipe.visible = false
	_pin_cap.visible = false
	_pin_stipe.scale = Vector3(0.08, 0.01, 0.08)
	_pin_cap.scale = Vector3(0.06, 0.04, 0.06)
	_adult_slot.visible = false
	_adult_slot.scale = Vector3.ONE
	_adult_mesh = null
	for child in _adult_slot.get_children():
		child.queue_free()


func _get_species() -> Dictionary:
	if not _species_override.is_empty():
		return _species_override
	return GameState.selected_species


func _process(delta: float) -> void:
	if not _active:
		return

	var species: Dictionary = _get_species()
	if species.is_empty():
		return
	var fruit_days_vec: Vector2 = MushroomSpeciesData.get_vector2(species, "fruiting_days", Vector2(7.0, 14.0))
	var fruit_days: float = (fruit_days_vec.x + fruit_days_vec.y) * 0.5
	var speed: float = delta / maxf(fruit_days * 0.15, 4.0) * _growth_speed_scale
	_progress += speed
	if not _is_spawned_colony:
		GameState.growth_progress = _progress

	match _stage:
		GrowthStage.HYPHAL_KNOT:
			_animate_hyphal_knot()
		GrowthStage.PRIMORDIUM:
			_animate_primordium()
		GrowthStage.PIN:
			_animate_pin()
		GrowthStage.STIPE_ELONGATION:
			_animate_stipe_elongation()
		GrowthStage.CAP_EXPANSION:
			_animate_cap_expansion()
		GrowthStage.MATURE:
			if not _adult_shown:
				_show_adult_model()
			if not _is_spawned_colony:
				register_spectate_target()
			growth_complete.emit()
			_active = false


func _animate_hyphal_knot() -> void:
	_knot.scale = Vector3.ONE * lerpf(0.005, 0.012, _progress * 8.0)
	if _progress >= 0.08:
		_stage = GrowthStage.PRIMORDIUM
		_progress = 0.0
		_knot.visible = false
		_primordium.visible = true


func _animate_primordium() -> void:
	_primordium.scale = Vector3.ONE * lerpf(0.02, 0.05, _progress * 4.0)
	if _progress >= 0.2:
		_stage = GrowthStage.PIN
		_progress = 0.0
		_primordium.visible = false
		_pin_stipe.visible = true
		_pin_cap.visible = true


func _animate_pin() -> void:
	_pin_stipe.scale.y = lerpf(0.01, 0.08, _progress * 3.0)
	_pin_cap.position.y = _pin_stipe.scale.y * 0.5 + 0.02
	_pin_cap.scale = Vector3.ONE * lerpf(0.04, 0.08, _progress * 3.0)
	if _progress >= 0.25:
		_stage = GrowthStage.STIPE_ELONGATION
		_progress = 0.0


func _animate_stipe_elongation() -> void:
	_pin_stipe.scale.y = lerpf(0.08, 0.45, _progress * 2.5)
	_pin_cap.position.y = _pin_stipe.scale.y * 0.5 + 0.04
	if _progress >= 0.35:
		_stage = GrowthStage.CAP_EXPANSION
		_progress = 0.0


func _animate_cap_expansion() -> void:
	_pin_cap.scale = Vector3(
		lerpf(0.08, 0.35, _progress * 2.0),
		lerpf(0.06, 0.12, _progress * 1.5),
		lerpf(0.08, 0.35, _progress * 2.0)
	)
	_pin_stipe.scale.x = lerpf(0.08, 0.12, _progress)
	_pin_stipe.scale.z = lerpf(0.08, 0.12, _progress)
	if _progress >= 0.4:
		_stage = GrowthStage.MATURE
		_progress = 0.0


func _get_mature_procedural_metrics() -> Dictionary:
	var stipe_bottom := _FINAL_STIPE_POS_Y - _FINAL_STIPE_MESH_H * _FINAL_STIPE_SCALE_Y * 0.5
	var cap_pos_y := _FINAL_STIPE_SCALE_Y * 0.5 + _FINAL_CAP_POS_OFFSET
	var cap_top := cap_pos_y + _FINAL_CAP_MESH_H * _FINAL_CAP_SCALE_Y * 0.5
	return {
		"height": cap_top - stipe_bottom,
		"ground_lift": maxf(-stipe_bottom, 0.0),
	}


func _show_adult_model() -> void:
	var mesh_name: String = _get_species().get("mesh_name", "mushroom_01")
	var metrics: Dictionary = _get_mature_procedural_metrics()
	var target_height: float = float(metrics["height"]) * adult_height_scale
	var on_tree := _substrate_patch != null and _substrate_patch.is_tree_mounted()
	var ground_lift: float = 0.0 if on_tree else float(metrics["ground_lift"]) + ground_clearance
	var loaded: Dictionary = MushroomMeshLoader.create_display(
		mesh_name, target_height, _adult_slot, ground_lift
	)
	if loaded.is_empty():
		push_warning("Adult mushroom: mesh '%s' could not be loaded; keeping procedural model." % mesh_name)
		_adult_shown = true
		return

	_adult_shown = true
	_procedural_root.visible = false
	_adult_slot.visible = true

	var display: MeshInstance3D = loaded["mesh_instance"]
	_adult_mesh = display
	_adult_cap_height = float(loaded.get("cap_height", target_height * 0.75))

	var tween := create_tween()
	_adult_slot.scale = Vector3.ONE * 0.01
	tween.tween_property(_adult_slot, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_ELASTIC)


func get_cap_position() -> Vector3:
	if _adult_mesh and is_instance_valid(_adult_mesh) and _adult_mesh.mesh:
		var aabb := _adult_mesh.mesh.get_aabb()
		return _adult_mesh.global_transform * Vector3(
			aabb.get_center().x,
			aabb.position.y + aabb.size.y,
			aabb.get_center().z
		)
	if _adult_slot.visible:
		return _adult_slot.global_position + Vector3.UP * _adult_cap_height
	if _pin_cap.visible:
		return _pin_cap.global_position
	return global_position + Vector3.UP * 0.2


func get_spectate_label() -> String:
	var prefix := "Growing " if _active else ""
	return "%s%s" % [prefix, _get_species().get("common_name", "Mushroom")]


func get_spectate_focus() -> Vector3:
	return get_cap_position()


func register_spectate_target() -> void:
	if not is_in_group("spectate_target"):
		add_to_group("spectate_target")
