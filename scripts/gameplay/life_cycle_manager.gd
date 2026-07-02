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
var _dispersal: Node3D
var _spectator: Node
var _wild_mushrooms: Node3D
var _explore_controls := false
var _spectate_enabled := false


func _ready() -> void:
	spore.deactivate()
	_dispersal = SporeDispersalManager.new()
	_dispersal.name = "SporeDispersal"
	add_child(_dispersal)
	_spectator = MushroomSpectator.new()
	_spectator.name = "MushroomSpectator"
	add_child(_spectator)
	_wild_mushrooms = WildMushroomScatter.new()
	_wild_mushrooms.name = "WildMushrooms"
	add_child(_wild_mushrooms)
	hud.show_objective("Generating forest ecosystem…")
	await get_tree().process_frame
	_build_world()
	_spectator.setup(world_camera)
	_start_gameplay()


func _build_world() -> void:
	var forest := get_node_or_null("Forest") as ForestBuilder
	if forest:
		forest.build()

	var scatter := substrates as SubstrateScatter
	if scatter:
		if forest:
			scatter.scatter(forest.get_terrain_height)
			var trees_root := forest.get_trees_root()
			if trees_root:
				scatter.scatter_tree_trunk_patches(trees_root)
		else:
			scatter.scatter()

	var nutrient_scatter := nutrients as NutrientScatter
	if nutrient_scatter:
		nutrient_scatter.scatter_near_substrates(substrates)

	if forest and scatter:
		forest.clear_vegetation_near_points(scatter.get_substrate_patch_positions(), 4.5)

	_collect_nutrients()
	_highlight_compatible_substrates()
	var player_id: String = GameState.selected_species.get("id", "")
	_wild_mushrooms.scatter(substrates, player_id)
	_spectator.refresh_targets()


func _start_gameplay() -> void:
	_dispersal.setup(growth, GameState.selected_species)
	_connect_signals()
	hud.bind_spore(spore)
	hud.set_landing_ui_visible(true)
	GameState.set_phase(LifeCycle.Phase.SPORE_DISPERSAL)
	spore.activate()
	hud.show_objective(
		"Drift with WASD. Green rings mark compatible substrates — soil patches on the ground "
		+ "and bark patches on tree trunks. Press L to land."
	)


func _collect_nutrients() -> void:
	_nutrient_sources.clear()
	for node in nutrients.find_children("*", "Area3D", true, false):
		if node is NutrientSource:
			_nutrient_sources.append(node as NutrientSource)


func refresh_nutrient_sources() -> void:
	_collect_nutrients()


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
	_dispersal.colony_spawned.connect(_on_colony_spawned)
	_spectator.target_changed.connect(_on_spectate_target_changed)
	GameState.phase_changed.connect(_on_phase_changed)


func _process(delta: float) -> void:
	if GameState.current_phase == LifeCycle.Phase.ENVIRONMENTAL_TRIGGER:
		_environment_timer += delta
		_process_environmental_trigger(delta)
	if _spectate_enabled:
		_handle_spectate_input()


func _handle_spectate_input() -> void:
	if world_camera and world_camera.is_freecam():
		return
	if Input.is_action_just_pressed("spectate_next"):
		_spectator.refresh_targets()
		_spectator.cycle_next()
	elif Input.is_action_just_pressed("spectate_prev"):
		_spectator.refresh_targets()
		_spectator.cycle_prev()


func _on_spore_landed(_pos: Vector3, substrate_type: String) -> void:
	var compatible: bool = MushroomSpeciesData.has_substrate(GameState.selected_species, substrate_type)
	if not compatible:
		hud.show_objective("Wrong substrate! Drift to a ring-marked patch and press Land again.")
		return
	hud.set_landing_ui_visible(false)
	GameState.set_phase(LifeCycle.Phase.GERMINATION)
	_dispersal.claim_patch_near(spore.global_position)
	var spore_cam := get_node_or_null("SporeCamera") as OrbitCamera
	if spore_cam:
		spore_cam.set_follow_enabled(false)
		spore_cam.current = false
	if world_camera:
		world_camera.set_focus_point(spore.global_position)
		world_camera.follow_distance = 5.5
		world_camera.set_follow_enabled(true)
		world_camera.current = true
	if GameState.landing_patch and GameState.landing_patch.is_tree_mounted():
		hud.show_objective(
			"Germinating on tree bark… Mycelium will grow hidden inside the trunk before fruiting."
		)
	else:
		hud.show_objective("Germinating… Watch the spore swell on the substrate.")


func _on_germination_complete() -> void:
	GameState.set_phase(LifeCycle.Phase.MYCELIUM_COLONIZATION)
	var nutrient_scatter := nutrients as NutrientScatter
	if nutrient_scatter:
		nutrient_scatter.add_cluster_near(GameState.landing_position, 3)
	refresh_nutrient_sources()
	mycelium.setup(GameState.landing_position, _nutrient_sources, GameState.landing_patch)
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
	hud.refresh_colonization_display()
	if GameState.landing_patch and GameState.landing_patch.is_tree_mounted():
		hud.show_objective(
			"Hold SPACE or press Grow Hyphae to colonize hidden mycelium inside the trunk. "
			+ "When ready, the fruiting body will emerge from the bark."
		)
	else:
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
	growth.setup(GameState.landing_position, GameState.landing_patch)
	growth.activate()
	_spectate_enabled = false
	_spectator.disable()
	_spectator.refresh_targets()
	hud.show_objective(
		"Watch your mushroom grow: primordium → stipe → cap → mature fruiting body. "
		+ "Spectating other mushrooms unlocks when fully grown."
	)


func _on_growth_complete() -> void:
	GameState.set_phase(LifeCycle.Phase.SPORE_PRODUCTION)
	_spectate_enabled = true
	_spectator.refresh_targets()
	_spectator.enable()
	_enable_explore_camera()
	spore_release.activate()
	_dispersal.register_release_source(Callable(growth, "get_cap_position"), spore_release.release_duration)
	hud.show_objective(
		"Basidiospores discharging — watch them land on ring-marked patches and multiply into new %s colonies."
		% GameState.selected_species.get("common_name", "mushroom")
	)


func _on_colony_spawned(total: int) -> void:
	_spectator.refresh_targets()
	hud.show_objective(
		"Spores colonized %d new patch%s! Each will grow into %s and release more spores."
		% [total, "es" if total != 1 else "", GameState.selected_species.get("common_name", "mushroom")]
	)


func _on_cycle_complete() -> void:
	GameState.set_phase(LifeCycle.Phase.COMPLETE)
	_enable_explore_camera()
	hud.show_objective(
		"Life cycle complete! ~%d spores released, %d new colonies spawned (%d fruiting). "
		+ "Tab/Q spectate mushrooms | Right-drag pan | Shift+right-drag orbit | F freecam."
		% [GameState.spores_released, GameState.spawned_colonies, GameState.mature_colonies]
	)


func _enable_explore_camera() -> void:
	_explore_controls = true
	_spectate_enabled = true
	if world_camera:
		world_camera.set_follow_enabled(true)
		world_camera.current = true
		world_camera.set_explore_mode(true)
		world_camera.set_focus_point(growth.global_position)
		world_camera.follow_distance = 14.0
	_spectator.enable()
	hud.set_explore_controls_visible(true)


func _on_spectate_target_changed(label: String, index: int, total: int) -> void:
	hud.show_spectate_target(label, index, total)


func _on_phase_changed(_phase: LifeCycle.Phase) -> void:
	pass
