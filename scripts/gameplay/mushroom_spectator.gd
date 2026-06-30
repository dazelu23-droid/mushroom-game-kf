class_name MushroomSpectator
extends Node

signal target_changed(label: String, index: int, total: int)

var _camera: Camera3D
var _targets: Array[Dictionary] = []
var _index := 0
var _enabled := false


func setup(camera: Camera3D) -> void:
	_camera = camera as OrbitCamera


func enable() -> void:
	_enabled = true
	refresh_targets()
	if _targets.is_empty():
		return
	_index = 0
	_focus_current()


func disable() -> void:
	_enabled = false


func is_enabled() -> bool:
	return _enabled


func refresh_targets() -> void:
	_targets.clear()
	var nodes: Array[Node] = []
	for node in get_tree().get_nodes_in_group("spectate_target"):
		if node is Node3D and is_instance_valid(node):
			nodes.append(node)
	nodes.sort_custom(func(a: Node, b: Node) -> bool:
		return str(a.name) < str(b.name)
	)
	for node in nodes:
		if not node.has_method("get_spectate_focus"):
			continue
		_targets.append({
			"node": node,
			"label": _label_for(node),
			"focus": Callable(node, "get_spectate_focus"),
		})
	if _index >= _targets.size():
		_index = maxi(_targets.size() - 1, 0)


func cycle_next() -> void:
	if not _enabled or _targets.is_empty():
		return
	_index = (_index + 1) % _targets.size()
	_focus_current()


func cycle_prev() -> void:
	if not _enabled or _targets.is_empty():
		return
	_index = (_index - 1 + _targets.size()) % _targets.size()
	_focus_current()


func get_current_label() -> String:
	if _targets.is_empty():
		return ""
	return String(_targets[_index].get("label", ""))


func _focus_current() -> void:
	if _camera == null or _targets.is_empty():
		return
	var entry: Dictionary = _targets[_index]
	var focus_callable: Callable = entry.get("focus", Callable())
	if not focus_callable.is_valid():
		return
	var point: Variant = focus_callable.call()
	if point is Vector3 and _camera is OrbitCamera:
		(_camera as OrbitCamera).focus_on_point(point as Vector3)
		target_changed.emit(String(entry.get("label", "")), _index + 1, _targets.size())


func _label_for(node: Node) -> String:
	if node.has_method("get_spectate_label"):
		return String(node.call("get_spectate_label"))
	return node.name
