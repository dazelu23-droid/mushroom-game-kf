class_name MushroomSpeciesData
extends RefCounted

## Each entry maps 1:1 to a mesh in lowpoly_mushrooms.glb (verified against albedo textures).

const MESH_TEXTURE_INDEX: Dictionary = {
	"mushroom_10": 0,
	"mushroom_03": 2,
	"mushroom_05": 4,
	"mushroom_04": 6,
	"mushroom_15": 8,
	"mushroom_07": 10,
	"mushroom_11": 12,
	"mushroom_01": 14,
	"mushroom_13": 16,
	"mushroom_09": 18,
	"mushroom_16": 20,
	"mushroom_08": 22,
	"mushroom_14": 24,
	"mushroom_12": 26,
	"mushroom_02": 28,
	"mushroom_06": 30,
}

const SPECIES: Array[Dictionary] = [
	{
		"id": "saffron_milk_cap",
		"common_name": "Saffron Milk Cap",
		"scientific_name": "Lactarius deliciosus",
		"mesh_name": "mushroom_10",
		"substrates": ["forest_soil", "leaf_litter", "dead_hardwood"],
		"germination_temp_c": Vector2(8.0, 18.0),
		"colonization_temp_c": Vector2(12.0, 18.0),
		"fruiting_temp_c": Vector2(10.0, 16.0),
		"fruiting_humidity": Vector2(85.0, 95.0),
		"colonization_days": Vector2(21.0, 35.0),
		"fruiting_days": Vector2(7.0, 14.0),
		"enzymes": ["cellulase", "oxidase"],
		"decomposition": "Mycorrhizal with pines. Exudes orange latex when cut. Cap is saffron-orange with concentric zones.",
		"spores_per_day": 14000,
		"summary": "Orange milk cap with decurrent gills. Fruits under conifers in autumn.",
	},
	{
		"id": "reishi",
		"common_name": "Reishi / Lingzhi",
		"scientific_name": "Ganoderma lucidum",
		"mesh_name": "mushroom_03",
		"substrates": ["dead_hardwood", "hardwood_sawdust"],
		"germination_temp_c": Vector2(12.0, 28.0),
		"colonization_temp_c": Vector2(24.0, 28.0),
		"fruiting_temp_c": Vector2(21.0, 30.0),
		"fruiting_humidity": Vector2(85.0, 95.0),
		"colonization_days": Vector2(21.0, 35.0),
		"fruiting_days": Vector2(30.0, 60.0),
		"enzymes": ["lignin peroxidase", "laccase"],
		"decomposition": "Woody bracket polypore on hardwood. Pore surface on underside; perennial conk.",
		"spores_per_day": 8000,
		"summary": "Lacquered bracket fungus. Releases spores from pores, not gills.",
	},
	{
		"id": "turkey_tail",
		"common_name": "Turkey Tail",
		"scientific_name": "Trametes versicolor",
		"mesh_name": "mushroom_05",
		"substrates": ["dead_hardwood", "leaf_litter"],
		"germination_temp_c": Vector2(10.0, 24.0),
		"colonization_temp_c": Vector2(18.0, 26.0),
		"fruiting_temp_c": Vector2(15.0, 24.0),
		"fruiting_humidity": Vector2(80.0, 90.0),
		"colonization_days": Vector2(14.0, 21.0),
		"fruiting_days": Vector2(10.0, 20.0),
		"enzymes": ["lignin peroxidase", "cellulase"],
		"decomposition": "Shelf polypore on dead logs. Concentric brown and cream banding on cap.",
		"spores_per_day": 12000,
		"summary": "Fan-shaped polypore decomposer on decaying wood.",
	},
	{
		"id": "fly_agaric",
		"common_name": "Fly Agaric",
		"scientific_name": "Amanita muscaria",
		"mesh_name": "mushroom_04",
		"substrates": ["forest_soil", "leaf_litter"],
		"germination_temp_c": Vector2(5.0, 18.0),
		"colonization_temp_c": Vector2(12.0, 18.0),
		"fruiting_temp_c": Vector2(8.0, 15.0),
		"fruiting_humidity": Vector2(85.0, 95.0),
		"colonization_days": Vector2(60.0, 120.0),
		"fruiting_days": Vector2(10.0, 21.0),
		"enzymes": ["ectomycorrhizal enzymes"],
		"decomposition": "Red cap with white warts. Mycorrhizal with birch and pine roots.",
		"spores_per_day": 14000,
		"summary": "Iconic red-and-white spotted mushroom. Symbiont of forest trees.",
	},
	{
		"id": "field_mushroom",
		"common_name": "Field Mushroom",
		"scientific_name": "Agaricus campestris",
		"mesh_name": "mushroom_15",
		"substrates": ["compost", "manure_compost", "grassland_soil"],
		"germination_temp_c": Vector2(12.0, 25.0),
		"colonization_temp_c": Vector2(18.0, 24.0),
		"fruiting_temp_c": Vector2(14.0, 20.0),
		"fruiting_humidity": Vector2(80.0, 90.0),
		"colonization_days": Vector2(14.0, 21.0),
		"fruiting_days": Vector2(7.0, 14.0),
		"enzymes": ["cellulase", "protease"],
		"decomposition": "Pink-then-brown gills on white cap. Saprotroph in meadows and woodland edges.",
		"spores_per_day": 16000,
		"summary": "Wild cousin of the button mushroom. Fruits in grassy clearings.",
	},
	{
		"id": "porcini",
		"common_name": "Porcini / King Bolete",
		"scientific_name": "Boletus edulis",
		"mesh_name": "mushroom_07",
		"substrates": ["forest_soil", "leaf_litter", "dead_hardwood"],
		"germination_temp_c": Vector2(8.0, 18.0),
		"colonization_temp_c": Vector2(12.0, 18.0),
		"fruiting_temp_c": Vector2(10.0, 16.0),
		"fruiting_humidity": Vector2(85.0, 95.0),
		"colonization_days": Vector2(60.0, 90.0),
		"fruiting_days": Vector2(12.0, 21.0),
		"enzymes": ["ectomycorrhizal enzymes"],
		"decomposition": "Sponge-like pores under tan cap. Mycorrhizal with spruce, pine, and oak.",
		"spores_per_day": 13000,
		"summary": "Prized bolete with yellow-green pore surface. Partners with tree roots.",
	},
	{
		"id": "parasol",
		"common_name": "Parasol Mushroom",
		"scientific_name": "Macrolepiota procera",
		"mesh_name": "mushroom_11",
		"substrates": ["leaf_litter", "forest_soil", "grassland_soil"],
		"germination_temp_c": Vector2(10.0, 22.0),
		"colonization_temp_c": Vector2(15.0, 22.0),
		"fruiting_temp_c": Vector2(12.0, 20.0),
		"fruiting_humidity": Vector2(80.0, 90.0),
		"colonization_days": Vector2(21.0, 35.0),
		"fruiting_days": Vector2(7.0, 14.0),
		"enzymes": ["cellulase", "protease"],
		"decomposition": "Large scaly brown cap on tall fibrous stipe with movable ring.",
		"spores_per_day": 17000,
		"summary": "Umbrella-shaped saprotroph of woodland meadows.",
	},
	{
		"id": "slippery_jack",
		"common_name": "Slippery Jack",
		"scientific_name": "Suillus luteus",
		"mesh_name": "mushroom_01",
		"substrates": ["forest_soil", "leaf_litter"],
		"germination_temp_c": Vector2(8.0, 18.0),
		"colonization_temp_c": Vector2(12.0, 18.0),
		"fruiting_temp_c": Vector2(10.0, 16.0),
		"fruiting_humidity": Vector2(85.0, 95.0),
		"colonization_days": Vector2(30.0, 50.0),
		"fruiting_days": Vector2(10.0, 18.0),
		"enzymes": ["ectomycorrhizal enzymes"],
		"decomposition": "Yellow pore bolete with slimy brown cap. Mycorrhizal with pine.",
		"spores_per_day": 15000,
		"summary": "Pine-associated bolete with yellow sponge pores.",
	},
	{
		"id": "shaggy_parasol",
		"common_name": "Shaggy Parasol",
		"scientific_name": "Chlorophyllum rhacodes",
		"mesh_name": "mushroom_13",
		"substrates": ["leaf_litter", "compost", "forest_soil"],
		"germination_temp_c": Vector2(12.0, 24.0),
		"colonization_temp_c": Vector2(16.0, 24.0),
		"fruiting_temp_c": Vector2(14.0, 22.0),
		"fruiting_humidity": Vector2(80.0, 90.0),
		"colonization_days": Vector2(14.0, 21.0),
		"fruiting_days": Vector2(6.0, 12.0),
		"enzymes": ["cellulase", "protease"],
		"decomposition": "Scaly brown cap, tall stipe. Saprotroph in wood chips and garden soil.",
		"spores_per_day": 16000,
		"summary": "Large scaly agaric of disturbed woodland soil.",
	},
	{
		"id": "button",
		"common_name": "Button / Portobello",
		"scientific_name": "Agaricus bisporus",
		"mesh_name": "mushroom_09",
		"substrates": ["compost", "manure_compost"],
		"germination_temp_c": Vector2(12.0, 25.0),
		"colonization_temp_c": Vector2(23.0, 25.0),
		"fruiting_temp_c": Vector2(16.0, 18.0),
		"fruiting_humidity": Vector2(85.0, 90.0),
		"colonization_days": Vector2(18.0, 20.0),
		"fruiting_days": Vector2(16.0, 25.0),
		"enzymes": ["cellulase", "hemicellulase", "protease"],
		"decomposition": "Dark brown gills, ring on stipe. Cultivated on fermented compost.",
		"spores_per_day": 18000,
		"summary": "Most commercially grown mushroom worldwide.",
	},
	{
		"id": "shiitake",
		"common_name": "Shiitake",
		"scientific_name": "Lentinula edodes",
		"mesh_name": "mushroom_16",
		"substrates": ["dead_hardwood", "hardwood_sawdust"],
		"germination_temp_c": Vector2(10.0, 24.0),
		"colonization_temp_c": Vector2(21.0, 27.0),
		"fruiting_temp_c": Vector2(10.0, 24.0),
		"fruiting_humidity": Vector2(70.0, 80.0),
		"colonization_days": Vector2(35.0, 70.0),
		"fruiting_days": Vector2(10.0, 16.0),
		"enzymes": ["lignin peroxidase", "manganese peroxidase"],
		"decomposition": "Cracked scaly brown cap on hardwood. White gilled saprotroph of oak logs.",
		"spores_per_day": 15000,
		"summary": "Premier edible wood-decay fungus. Fruits from colonized logs.",
	},
	{
		"id": "fly_agaric_classic",
		"common_name": "Fly Agaric (Classic Form)",
		"scientific_name": "Amanita muscaria var. muscaria",
		"mesh_name": "mushroom_08",
		"substrates": ["forest_soil", "leaf_litter"],
		"germination_temp_c": Vector2(5.0, 18.0),
		"colonization_temp_c": Vector2(12.0, 18.0),
		"fruiting_temp_c": Vector2(8.0, 15.0),
		"fruiting_humidity": Vector2(85.0, 95.0),
		"colonization_days": Vector2(60.0, 120.0),
		"fruiting_days": Vector2(10.0, 21.0),
		"enzymes": ["ectomycorrhizal enzymes"],
		"decomposition": "Bright red cap, white pyramidal warts. Ectomycorrhizal with birch.",
		"spores_per_day": 14000,
		"summary": "Classic European fly agaric form under birch and spruce.",
	},
	{
		"id": "king_oyster",
		"common_name": "King Oyster",
		"scientific_name": "Pleurotus eryngii",
		"mesh_name": "mushroom_14",
		"substrates": ["dead_hardwood", "straw", "leaf_litter"],
		"germination_temp_c": Vector2(10.0, 24.0),
		"colonization_temp_c": Vector2(20.0, 24.0),
		"fruiting_temp_c": Vector2(15.0, 21.0),
		"fruiting_humidity": Vector2(85.0, 90.0),
		"colonization_days": Vector2(12.0, 16.0),
		"fruiting_days": Vector2(8.0, 13.0),
		"enzymes": ["cellulase", "laccase"],
		"decomposition": "Thick stipe, small brown cap. Decurrent gills run down the stem.",
		"spores_per_day": 12000,
		"summary": "Meaty oyster relative with decurrent gills on wood.",
	},
	{
		"id": "parasol_woodland",
		"common_name": "Woodland Parasol",
		"scientific_name": "Macrolepiota procera",
		"mesh_name": "mushroom_12",
		"substrates": ["leaf_litter", "forest_soil"],
		"germination_temp_c": Vector2(10.0, 22.0),
		"colonization_temp_c": Vector2(15.0, 22.0),
		"fruiting_temp_c": Vector2(12.0, 20.0),
		"fruiting_humidity": Vector2(80.0, 90.0),
		"colonization_days": Vector2(21.0, 35.0),
		"fruiting_days": Vector2(7.0, 14.0),
		"enzymes": ["cellulase", "protease"],
		"decomposition": "Scaly cap emerging from rich humus. Common at forest edges.",
		"spores_per_day": 17000,
		"summary": "Parasol form with soil-stained base from leaf litter.",
	},
	{
		"id": "fly_agaric_red",
		"common_name": "Fly Agaric (Red Form)",
		"scientific_name": "Amanita muscaria",
		"mesh_name": "mushroom_02",
		"substrates": ["forest_soil", "leaf_litter"],
		"germination_temp_c": Vector2(5.0, 18.0),
		"colonization_temp_c": Vector2(12.0, 18.0),
		"fruiting_temp_c": Vector2(8.0, 15.0),
		"fruiting_humidity": Vector2(85.0, 95.0),
		"colonization_days": Vector2(60.0, 120.0),
		"fruiting_days": Vector2(10.0, 21.0),
		"enzymes": ["ectomycorrhizal enzymes"],
		"decomposition": "Vivid red pileus with white veil remnants. Found near conifers.",
		"spores_per_day": 14000,
		"summary": "Alternate mature form of fly agaric in pine forests.",
	},
	{
		"id": "porcini_classic",
		"common_name": "Porcini (Classic Form)",
		"scientific_name": "Boletus edulis",
		"mesh_name": "mushroom_06",
		"substrates": ["forest_soil", "leaf_litter"],
		"germination_temp_c": Vector2(8.0, 18.0),
		"colonization_temp_c": Vector2(12.0, 18.0),
		"fruiting_temp_c": Vector2(10.0, 16.0),
		"fruiting_humidity": Vector2(85.0, 95.0),
		"colonization_days": Vector2(60.0, 90.0),
		"fruiting_days": Vector2(12.0, 21.0),
		"enzymes": ["ectomycorrhizal enzymes"],
		"decomposition": "Bulbous stipe, brown cap, white pore surface when young.",
		"spores_per_day": 13000,
		"summary": "Classic porcini morphology with olive-brown cap.",
	},
]


static func preview_for_mesh(mesh_name: String) -> String:
	var tex_idx: int = int(MESH_TEXTURE_INDEX.get(mesh_name, 0))
	return "res://assets/mushroom/lowpoly_mushrooms_%d.jpg" % tex_idx


static func get_species_with_previews() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in SPECIES:
		var species: Dictionary = entry.duplicate()
		species["preview_texture"] = preview_for_mesh(species.get("mesh_name", ""))
		result.append(species)
	return result


static func get_vector2(species: Dictionary, key: String, default: Vector2 = Vector2.ZERO) -> Vector2:
	var value: Variant = species.get(key, default)
	if value is Vector2:
		return value
	return default


static func get_substrates(species: Dictionary) -> Array:
	return species.get("substrates", [])


static func has_substrate(species: Dictionary, substrate_type: String) -> bool:
	return substrate_type in get_substrates(species)


static func get_by_id(species_id: String) -> Dictionary:
	for species in SPECIES:
		if species.get("id", "") == species_id:
			var copy: Dictionary = species.duplicate()
			copy["preview_texture"] = preview_for_mesh(species.get("mesh_name", ""))
			return copy
	return {}


static func get_by_mesh(mesh_name: String) -> Dictionary:
	for species in SPECIES:
		if species.get("mesh_name", "") == mesh_name:
			var copy: Dictionary = species.duplicate()
			copy["preview_texture"] = preview_for_mesh(mesh_name)
			return copy
	return {}
