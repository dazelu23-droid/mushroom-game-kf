class_name MushroomGrowthVisual
extends Node3D

## Biologically accurate staged growth:
## hyphal knot (0.5mm) -> primordium (1-5mm) -> pin -> stipe elongation -> cap expansion -> adult model

signal growth_complete

const ADULT_SCENE := preload("res://assets/mushroom/lowpoly_mushrooms.glb")

@export var adult_height: float = 1.2

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
	_adult_slot.scale = Vector3.ONE
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

	var adult_pack := ADULT_SCENE.instantiate() as Node3D
	_adult_slot.add_child(adult_pack)

	var mesh_name: String = GameState.selected_species.get("mesh_name", "mushroom_01")
	_hide_all_mushroom_meshes(adult_pack)
	var target := _find_mushroom_node(adult_pack, mesh_name)
	if target == null:
		push_warning("Adult mushroom: mesh '%s' not found in GLB." % mesh_name)
		adult_pack.queue_free()
		return

	_adult_shown = true
	_procedural_root.visible = false
	_adult_slot.visible = true
	target.visible = true
	_center_and_scale_adult(adult_pack, target)

	var tween := create_tween()
	_adult_slot.scale = Vector3.ONE * 0.01
	tween.tween_property(_adult_slot, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_ELASTIC)


func _find_mushroom_node(root: Node, mesh_name: String) -> Node3D:
	var exact := root.find_child(mesh_name, true, false) as Node3D
	if exact:
		return exact
	for node in root.find_children("mushroom_*", "Node3D", true, false):
		if node.name == mesh_name or node.name.begins_with(mesh_name + "_"):
			return node as Node3D
	return null


func _center_and_scale_adult(pack: Node3D, target: Node3D) -> void:
	var mesh_node := _get_mesh_instance(target)
	if mesh_node == null or mesh_node.mesh == null:
		pack.position = -target.position
		_adult_cap_height = adult_height * 0.75
		return

	var aabb := mesh_node.mesh.get_aabb()
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var scale_factor := adult_height / max_dim if max_dim > 0.001 else 1.0
	pack.scale = Vector3.ONE * scale_factor
	pack.position = -target.position * scale_factor
	pack.position.y -= aabb.position.y * scale_factor
	_adult_cap_height = aabb.size.y * scale_factor


func _get_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _get_mesh_instance(child)
		if found:
			return found
	return null


func _hide_all_mushroom_meshes(root: Node) -> void:
	for child in root.get_children():
		if _is_mushroom_root_node(child.name):
			child.visible = false
		_hide_all_mushroom_meshes(child)


func _is_mushroom_root_node(node_name: String) -> bool:
	if not node_name.begins_with("mushroom_"):
		return false
	var suffix: String = node_name.trim_prefix("mushroom_").split("_")[0]
	return suffix.is_valid_int()


func get_cap_position() -> Vector3:
	if _adult_slot.visible:
		return _adult_slot.global_position + Vector3.UP * _adult_cap_height
	if _pin_cap.visible:
		return _pin_cap.global_position
	return global_position + Vector3.UP * 0.2
