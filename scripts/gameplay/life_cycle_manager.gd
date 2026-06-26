extends Node3D

signal cycle_complete

@onready var spore: SporePlayer = %SporePlayer
@onready var mycelium: MyceliumColony = %MyceliumColony
@onready var growth: MushroomGrowthVisual = %MushroomGrowth
@onready var spore_release: SporeRelease = %SporeRelease
@onready var hud: GameHUD = %HUD
@onready var substrates: Node3D = %Substrates
@onready var nutrients: Node3D = %NutrientSources
@onready var world_camera: OrbitCamera = %WorldCamera

var _nutrient_sources: Array[NutrientSource] = []
var _environment_timer := 0.0
var _fruiting_started := false
var _colonization_advanced := false


func _ready() -> void:
	var forest := get_node_or_null("Forest") as ForestBuilder
	if forest:
		forest.build()

	var scatter := substrates as SubstrateScatter
	if scatter:
		if forest:
			scatter.scatter(forest.get_terrain_height)
		else:
			scatter.scatter()

	var nutrient_scatter := nutrients as NutrientScatter
	if nutrient_scatter:
		nutrient_scatter.scatter_near_substrates(substrates)

	if forest and scatter:
		forest.clear_vegetation_near_points(scatter.get_substrate_patch_positions(), 4.5)

	_collect_nutrients()
	_highlight_compatible_substrates()
	_connect_signals()
	hud.bind_spore(spore)
	hud.set_landing_ui_visible(true)
	GameState.set_phase(LifeCycle.Phase.SPORE_DISPERSAL)
	spore.activate()
	hud.show_objective(
		"Drift over the forest with WASD. Ring-marked soil patches are compatible substrates — press Land when overhead."
	)


func _collect_nutrients() -> void:
	_nutrient_sources.clear()
	for node in nutrients.find_children("*", "Area3D", true, false):
		if node is NutrientSource:                  
			_nutrient_sources.append(node as NutrientSource)


func _highlight_compatible_substrates() -> void:
	var species: Dictionary = GameState.selected_species
	for child in substrates.get_children():
		var patch: SubstratePatch = child.get_node_or_null("Area") as SubstratePatch
		if patch:
			var is_compatible: bool = MushroomSpeciesData.has_substrate(species, patch.substrate_type)
			patch.set_compatible(is_compatible)


func _connect_signals() -> void:
	spore.landed_on_substrate.connect(_on_spore_landed)
	spore.germination_complete.connect(_on_germination_complete)
	mycelium.colonization_ready.connect(_on_colonization_ready)
	growth.growth_complete.connect(_on_growth_complete)
	spore_release.cycle_complete.connect(_on_cycle_complete)
	GameState.phase_changed.connect(_on_phase_changed)


func _process(delta: float) -> void:
	if GameState.current_phase == LifeCycle.Phase.ENVIRONMENTAL_TRIGGER:
		_environment_timer += delta
		_process_environmental_trigger(delta)


func _on_spore_landed(_pos: Vector3, substrate_type: String) -> void:
	var compatible: bool = MushroomSpeciesData.has_substrate(GameState.selected_species, substrate_type)
	if not compatible:
		hud.show_objective("Wrong substrate! Drift to a ring-marked patch and press Land again.")
		return
	hud.set_landing_ui_visible(false)
	GameState.set_phase(LifeCycle.Phase.GERMINATION)
	var spore_cam := get_node_or_null("SporeCamera") as OrbitCamera
	if spore_cam:
		spore_cam.set_follow_enabled(false)
		spore_cam.current = false
	if world_camera:
		world_camera.set_focus_point(spore.global_position)
		world_camera.follow_distance = 5.5
		world_camera.set_follow_enabled(true)
		world_camera.current = true
	hud.show_objective("Germinating… Watch the spore swell and send out its first hypha.")


func _on_germination_complete() -> void:
	GameState.set_phase(LifeCycle.Phase.MYCELIUM_COLONIZATION)
	mycelium.setup(GameState.landing_position, _nutrient_sources)
	mycelium.activate()
	var spore_cam := get_node_or_null("SporeCamera") as OrbitCamera
	if spore_cam:
		spore_cam.set_follow_enabled(false)
		spore_cam.current = false
	if world_camera:
		world_camera.set_focus_point(GameState.landing_position)
		world_camera.follow_distance = 12.0
		world_camera.set_follow_enabled(true)
	world_camera.current = true
	hud.bind_mycelium(mycelium)
	hud.set_grow_ui_visible(true)
	hud.show_objective(
		"Hold SPACE or press Grow Hyphae to extend apical tips toward dead matter. "
		+ "Species enzymes digest lignin/cellulose — colonize to 80%."
	)


func _on_colonization_ready() -> void:
	if _colonization_advanced:
		return
	_colonization_advanced = true
	GameState.set_phase(LifeCycle.Phase.ENVIRONMENTAL_TRIGGER)
	_environment_timer = 0.0
	GameState.co2_level = 80.0
	GameState.humidity = 60.0
	hud.show_objective("Trigger fruiting: hold H to raise humidity, V to ventilate (lower CO₂). Need humidity >85%, CO₂ <40%.")


func _process_environmental_trigger(delta: float) -> void:
	if Input.is_action_pressed("raise_humidity"):
		GameState.humidity = clampf(GameState.humidity + 20.0 * delta, 0.0, 100.0)
	if Input.is_action_pressed("ventilate"):
		GameState.co2_level = clampf(GameState.co2_level - 25.0 * delta, 0.0, 100.0)

	hud.update_environment(GameState.humidity, GameState.co2_level)

	var species: Dictionary = GameState.selected_species
	var fruiting_humidity: Vector2 = MushroomSpeciesData.get_vector2(species, "fruiting_humidity", Vector2(85.0, 90.0))
	var humidity_ok: bool = GameState.humidity >= fruiting_humidity.x
	var co2_ok: bool = GameState.co2_level <= 40.0

	if humidity_ok and co2_ok and _environment_timer > 2.0:
		_begin_fruiting()


func _begin_fruiting() -> void:
	if _fruiting_started:
		return
	_fruiting_started = true
	hud.set_grow_ui_visible(false)
	mycelium.deactivate()
	GameState.set_phase(LifeCycle.Phase.PRIMORDIUM_FORMATION)
	await get_tree().create_timer(1.5).timeout
	GameState.set_phase(LifeCycle.Phase.FRUITING_BODY_GROWTH)
	growth.setup(GameState.landing_position)
	growth.activate()
	hud.show_objective("Watch bi-phasic growth: primordium → stipe elongation → cap expansion → mature fruiting body.")


func _on_growth_complete() -> void:
	GameState.set_phase(LifeCycle.Phase.SPORE_PRODUCTION)
	spore_release.activate()
	hud.show_objective("Basidiospores discharging from gills. Meiosis complete — life cycle renewing.")


func _on_cycle_complete() -> void:
	GameState.set_phase(LifeCycle.Phase.COMPLETE)
	hud.show_objective("Life cycle complete! %s released ~%d spores. Return to menu to try another species." % [
		GameState.selected_species.get("common_name", "Mushroom"),
		GameState.spores_released,
	])


func _on_phase_changed(_phase: LifeCycle.Phase) -> void:
	pass
