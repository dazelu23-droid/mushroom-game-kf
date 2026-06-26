extends Control

const GAME_SCENE := preload("res://scenes/game_world.tscn")

@onready var species_list: ItemList = %SpeciesList
@onready var preview_container: SubViewportContainer = %PreviewViewport
@onready var model_preview = %SpeciesPreview as Node3D
@onready var name_label: Label = %NameLabel
@onready var scientific_label: Label = %ScientificLabel
@onready var detail_label: RichTextLabel = %DetailLabel
@onready var start_button: Button = %StartButton

var _selected_index: int = 0
var _dragging_preview := false


func _ready() -> void:
	_populate_species()
	species_list.item_selected.connect(_on_species_selected)
	start_button.pressed.connect(_on_start_pressed)
	call_deferred("_on_species_selected", 0)


func _input(event: InputEvent) -> void:
	if not preview_container.get_global_rect().has_point(get_viewport().get_mouse_position()):
		if event is InputEventMouseButton:
			_dragging_preview = false
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging_preview = mb.pressed
	elif event is InputEventMouseMotion and _dragging_preview:
		model_preview.apply_drag((event as InputEventMouseMotion).relative)


func _populate_species() -> void:
	species_list.clear()
	for entry in MushroomSpeciesData.SPECIES:
		species_list.add_item(
			"%s (%s)" % [entry.get("common_name", ""), entry.get("scientific_name", "")]
		)


func _on_species_selected(index: int) -> void:
	_selected_index = index
	var species: Dictionary = MushroomSpeciesData.SPECIES[index]
	name_label.text = species.get("common_name", "")
	scientific_label.text = species.get("scientific_name", "")
	model_preview.show_mesh(String(species.get("mesh_name", "mushroom_01")))

	var substrate_list: Array = species.get("substrates", [])
	var enzyme_list: Array = species.get("enzymes", [])
	var substrates: String = _comma_join(substrate_list)
	var enzymes: String = _comma_join(enzyme_list)
	var germ_temp: Vector2 = MushroomSpeciesData.get_vector2(species, "germination_temp_c", Vector2.ZERO)
	var col_temp: Vector2 = MushroomSpeciesData.get_vector2(species, "colonization_temp_c", Vector2.ZERO)
	var col_days: Vector2 = MushroomSpeciesData.get_vector2(species, "colonization_days", Vector2.ZERO)
	var fruit_temp: Vector2 = MushroomSpeciesData.get_vector2(species, "fruiting_temp_c", Vector2.ZERO)
	var fruit_hum: Vector2 = MushroomSpeciesData.get_vector2(species, "fruiting_humidity", Vector2.ZERO)
	var fruit_days: Vector2 = MushroomSpeciesData.get_vector2(species, "fruiting_days", Vector2.ZERO)
	detail_label.text = (
		"[b]Ecology:[/b] %s\n\n" % species.get("summary", "")
		+ "[b]Decomposition:[/b] %s\n\n" % species.get("decomposition", "")
		+ "[b]Preferred substrates:[/b] %s\n" % substrates
		+ "[b]Germination temp:[/b] %.0f–%.0f°C | " % [germ_temp.x, germ_temp.y]
		+ "[b]Colonization:[/b] %.0f–%.0f days at %.0f–%.0f°C\n"
		% [col_days.x, col_days.y, col_temp.x, col_temp.y]
		+ "[b]Fruiting:[/b] %.0f–%.0f days at %.0f–%.0f°C, %.0f–%.0f%% RH\n"
		% [fruit_days.x, fruit_days.y, fruit_temp.x, fruit_temp.y, fruit_hum.x, fruit_hum.y]
		+ "[b]Key enzymes:[/b] %s\n" % enzymes
		+ "[b]Spore release rate:[/b] ~%d spores/min at maturity"
		% int(species.get("spores_per_day", 0))
	)


func _on_start_pressed() -> void:
	var species: Dictionary = MushroomSpeciesData.SPECIES[_selected_index].duplicate()
	GameState.select_species(species)
	get_tree().change_scene_to_packed(GAME_SCENE)


func _comma_join(items: Array) -> String:
	var parts := PackedStringArray()
	for item in items:
		parts.append(String(item))
	return ", ".join(parts)
