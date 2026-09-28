class_name Season
extends Resource
## One season, as data. A season belongs to a pillar (`family`) and changes only how its
## pages look: the colours of the watercolour wash, what drifts across the page, and the
## planes behind the staff. Picked by SeasonBook; no code branches on which season it is.

@export var id := ""
## The pillar this season dresses ("percussion", "wind", "string").
@export var family := ""
## The wash palette. Each wash blob takes one of these in place of the pillar's single colour.
@export var palette := PackedColorArray()
@export var particles: SeasonParticles
## Scenery behind the staff, far to near.
@export var planes: Array[ParallaxPlane] = []
