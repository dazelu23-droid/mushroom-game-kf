class_name TreeMountUtil
extends RefCounted

## Trunk dimensions match forest_tree.tscn Trunk mesh (local space, base at y=0).
## Bracket orientation follows real polypores: shelves project from bark, pore surface faces down.

const TRUNK_HEIGHT := 5.8
const TRUNK_BOTTOM_RADIUS := 0.38
const TRUNK_TOP_RADIUS := 0.14

## shelf_pitch: degrees to tilt the outer edge of the shelf upward (gravity-aligned pores face down).
const SPECIES_MOUNT: Dictionary = {
	"reishi": {"shelf_pitch": 10.0, "hoof_blend": 0.0},
	"turkey_tail": {"shelf_pitch": 6.0, "hoof_blend": 0.0},
	"shiitake": {"shelf_pitch": 18.0, "hoof_blend": 0.38},
	"king_oyster": {"shelf_pitch": 22.0, "hoof_blend": 0.32},
}


static func surface_mount(tree: Node3D, height_ratio: float, angle: float) -> Dictionary:
	var scale := tree.scale.x
	var h := clampf(height_ratio, 0.12, 0.78) * TRUNK_HEIGHT
	var t := h / TRUNK_HEIGHT
	var radius := lerpf(TRUNK_BOTTOM_RADIUS, TRUNK_TOP_RADIUS, t) * scale
	var local_outward := Vector3(cos(angle), 0.0, sin(angle))
	var local_pos := Vector3(local_outward.x * radius, h, local_outward.z * radius)
	var global_pos := tree.global_transform * local_pos
	var global_outward := (tree.global_transform.basis * local_outward).normalized()
	return {
		"position": global_pos,
		"outward": global_outward,
	}


static func basis_for_tree_fungus(outward: Vector3, species: Dictionary = {}) -> Basis:
	var out := Vector3(outward.x, 0.0, outward.z)
	if out.length_squared() < 0.0001:
		out = Vector3.FORWARD
	else:
		out = out.normalized()

	var species_id: String = species.get("id", "")
	var mount_cfg: Dictionary = SPECIES_MOUNT.get(species_id, {"shelf_pitch": 12.0, "hoof_blend": 0.0})
	var shelf_pitch: float = float(mount_cfg.get("shelf_pitch", 12.0))
	var hoof_blend: float = float(mount_cfg.get("hoof_blend", 0.0))

	var up := Vector3.UP
	var tangent := up.cross(out).normalized()
	if tangent.length_squared() < 0.0001:
		tangent = Vector3.RIGHT

	# Model +Y (stipe) grows horizontally out from bark; model +Z aligns toward ground (pore side).
	var y_axis := out.lerp(up, hoof_blend).normalized()
	var z_axis := -up
	var x_axis := y_axis.cross(z_axis).normalized()
	if x_axis.length_squared() < 0.0001:
		x_axis = tangent
	z_axis = x_axis.cross(y_axis).normalized()

	var basis := Basis(x_axis, y_axis, z_axis)
	# Real shelves tilt slightly upward from the attachment point on vertical trunks.
	return basis.rotated(tangent, deg_to_rad(shelf_pitch))
