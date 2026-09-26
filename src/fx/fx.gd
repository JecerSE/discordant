class_name FX
## Short-lived things that live in a room: hit effects, area attacks, pickups, hazards.
## Each is a Node2D whose `room` is set by Room.add_fx().
## Each effect lives in src/fx/effects/. These constants keep FX.Ring.new() and friends working.

const Base = preload("res://src/fx/effects/base.gd")
const Slash = preload("res://src/fx/effects/slash.gd")
const FloatText = preload("res://src/fx/effects/float_text.gd")
const Ring = preload("res://src/fx/effects/ring.gd")
const Shockwave = preload("res://src/fx/effects/shockwave.gd")
const Splat = preload("res://src/fx/effects/splat.gd")
const Pickup = preload("res://src/fx/effects/pickup.gd")
const Pillar = preload("res://src/fx/effects/pillar.gd")
const Tornado = preload("res://src/fx/effects/tornado.gd")
const Decoy = preload("res://src/fx/effects/decoy.gd")
const Trail = preload("res://src/fx/effects/trail.gd")
const Column = preload("res://src/fx/effects/column.gd")
const SpawnMark = preload("res://src/fx/effects/spawn_mark.gd")
