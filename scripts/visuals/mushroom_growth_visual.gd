class_name MushroomGrowthVisual
extends Node3D

## Biologically accurate staged growth:
## hyphal knot (0.5mm) -> primordium (1-5mm) -> pin -> stipe elongation -> cap expansion -> adult model

signal growth_complete

const ADULT_SCENE := preload("res://assets/mushroom/lowpoly_mushrooms.glb")

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

@onready var _procedural_root: Node3D = $ProceduralRoot
@onready var _knot: MeshInstance3D = $ProceduralRoot/HyphalKnot
@onready var _primordium: MeshInstance3D = $ProceduralRoot/Primordium
@onready var _pin_stipe: MeshInstance3D = $ProceduralRoot/Pin/Stipe
@onready var _pin_cap: MeshInstance3D = $ProceduralRoot/Pin/Cap
@onready var _adult_slot: Node3D = $AdultSlot


func setup(origin: Vector3) -> void:
	global_position = origin
	_reset_visuals()


func activate() -> void:
	_active = true
	visible = true
	_stage = GrowthStage.HYPHAL_KNOT
	_progress = 0.0
	_reset_visuals()


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
	for child in _adult_slot.get_children():
		child.queue_free()


func _process(delta: float) -> void:
	if not _active:
		return

	var species: Dictionary = GameState.selected_species
	if species.is_empty():
		return
	var fruit_days_vec: Vector2 = MushroomSpeciesData.get_vector2(species, "fruiting_days", Vector2(7.0, 14.0))
	var fruit_days: float = (fruit_days_vec.x + fruit_days_vec.y) * 0.5
	var speed: float = delta / maxf(fruit_days * 0.15, 4.0)
	_progress += speed
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
			_show_adult_model()
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
	# Undifferentiated hyphal ball 1–5 mm; tissues pattern internally.
	_primordium.scale = Vector3.ONE * lerpf(0.02, 0.05, _progress * 4.0)
	if _progress >= 0.2:
		_stage = GrowthStage.PIN
		_progress = 0.0
		_primordium.visible = false
		_pin_stipe.visible = true
		_pin_cap.visible = true


func _animate_pin() -> void:
	# Pin stage: 3–8 mm, basic cap-and-stem architecture visible.
	_pin_stipe.scale.y = lerpf(0.01, 0.08, _progress * 3.0)
	_pin_cap.position.y = _pin_stipe.scale.y * 0.5 + 0.02
	_pin_cap.scale = Vector3.ONE * lerpf(0.04, 0.08, _progress * 3.0)
	if _progress >= 0.25:
		_stage = GrowthStage.STIPE_ELONGATION
		_progress = 0.0


func _animate_stipe_elongation() -> void:
	# Turgor-driven cell expansion: stipe elongates BEFORE cap (Fungus Fact Friday #234).
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


func _show_adult_model() -> void:
	if _adult_shown:
		return
	_adult_shown = true
	_procedural_root.visible = false
	_adult_slot.visible = true

	var adult_pack := ADULT_SCENE.instantiate() as Node3D
	_adult_slot.add_child(adult_pack)

	var mesh_name: String = GameState.selected_species.get("mesh_name", "mushroom_01")
	_hide_all_mushroom_meshes(adult_pack)
	var target := adult_pack.find_child(mesh_name, true, false) as Node3D
	if target:
		target.visible = true
		_align_adult_mesh(adult_pack, target)

	var tween := create_tween()
	_adult_slot.scale = Vector3.ONE * 0.01
	tween.tween_property(_adult_slot, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_ELASTIC)


func _hide_all_mushroom_meshes(root: Node) -> void:
	for child in root.get_children():
		if _is_mushroom_root_node(child.name):
			child.visible = false
		_hide_all_mushroom_meshes(child)


func _is_mushroom_root_node(node_name: String) -> bool:
	if not node_name.begins_with("mushroom_"):
		return false
	var suffix: String = node_name.trim_prefix("mushroom_")
	return suffix.is_valid_int()


func _align_adult_mesh(root: Node3D, target: Node3D) -> void:
	var mesh_node: MeshInstance3D = target.get_child(0) as MeshInstance3D if target.get_child_count() > 0 else null
	if mesh_node and mesh_node.mesh:
		var aabb: AABB = mesh_node.mesh.get_aabb()
		root.position.y = -aabb.position.y * target.scale.y


func get_cap_position() -> Vector3:
	if _adult_slot.visible:
		return _adult_slot.global_position + Vector3.UP * 0.8
	if _pin_cap.visible:
		return _pin_cap.global_position
	return global_position + Vector3.UP * 0.2
