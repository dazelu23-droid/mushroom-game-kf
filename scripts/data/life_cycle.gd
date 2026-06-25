class_name LifeCycle
extends RefCounted

enum Phase {
	SPORE_DISPERSAL,
	GERMINATION,
	MYCELIUM_COLONIZATION,
	ENVIRONMENTAL_TRIGGER,
	PRIMORDIUM_FORMATION,
	FRUITING_BODY_GROWTH,
	SPORE_PRODUCTION,
	COMPLETE,
}

const PHASE_FACTS: Dictionary = {
	Phase.SPORE_DISPERSAL: {
		"title": "Basidiospore Dispersal",
		"fact": "A single mushroom releases billions of basidiospores. Most spores never germinate; they need moisture, suitable temperature, and a compatible substrate.",
	},
	Phase.GERMINATION: {
		"title": "Spore Germination",
		"fact": "Under favorable moisture, a dormant spore absorbs water, swells, and sends out a germ tube that becomes a hypha. The hypha is haploid and must find a compatible mate.",
	},
	Phase.MYCELIUM_COLONIZATION: {
		"title": "Mycelial Colonization",
		"fact": "Compatible hyphae fuse (plasmogamy), forming dikaryotic mycelium. The network secretes extracellular enzymes—cellulases and lignin peroxidases—that decompose dead organic matter and absorb released nutrients.",
	},
	Phase.ENVIRONMENTAL_TRIGGER: {
		"title": "Fruiting Initiation",
		"fact": "Fruiting is triggered by environmental cues: nutrient depletion in the substrate, reduced CO₂, increased humidity, temperature shift, and sometimes light exposure.",
	},
	Phase.PRIMORDIUM_FORMATION: {
		"title": "Hyphal Knots & Primordia",
		"fact": "Mycelium aggregates into hyphal knots (0.5–1 mm), which differentiate into primordia (1–5 mm). Tissues for stipe, pileus, and gills are patterned inside before visible expansion.",
	},
	Phase.FRUITING_BODY_GROWTH: {
		"title": "Fruiting Body Expansion",
		"fact": "Growth is biphasic: cell proliferation forms tissues, then turgor-driven cell expansion inflates the mushroom—stipe elongates first, then the pileus expands, similar to inflating a balloon.",
	},
	Phase.SPORE_PRODUCTION: {
		"title": "Meiosis & Spore Release",
		"fact": "Basidia on gill surfaces undergo meiosis, producing four basidiospores each. Mature spores are discharged into air currents—often 20,000+ per minute from a single cap.",
	},
	Phase.COMPLETE: {
		"title": "Life Cycle Complete",
		"fact": "Released spores disperse by wind and rain. Those landing on suitable substrate can germinate, continuing the fungal life cycle.",
	},
}
