class_name LevelGenTuning
extends Resource
## Room and map generation. Edit content/tuning/level_gen_tuning.tres.

@export_group("Room size (issue #8)")
## Narrowest fight room (px).
@export var combat_width_min: float = 2300.0
## Up to this much wider, at random (px).
@export var combat_width_extra: float = 900.0
## Extra width for Wind fight rooms (open sky) (px).
@export var wind_width_bonus: float = 200.0
## Width of an elite room (px).
@export var elite_width: float = 1900.0

@export_group("Platforms")
## Shortest staff-line platform (px).
@export var segment_length_min: float = 200.0
## Longest staff-line platform (px).
@export var segment_length_max: float = 560.0
## Smallest gap between platforms on a line (px).
@export var gap_min: float = 120.0
## Largest gap between platforms on a line (px).
@export var gap_max: float = 280.0
## Extra gap per line up, so higher lines are sparser (px).
@export var gap_per_line: float = 20.0
## Leave this much of the left edge (spawn) and right edge (exit) free of line ink.
@export var start_margin: float = 220.0
## Keep this much of the right edge free of platforms (px).
@export var end_margin: float = 160.0

@export_group("Reachability (issue #7)")
## Horizontal edge-to-edge distance a note can cover while climbing one line (px).
## Based on Mundo, the note with one jump and the lowest speed.
@export var climb_reach: float = 110.0
## Gap a note can clear jumping across the same line (px).
@export var same_line_reach: float = 150.0
## Length of the ledge added under a platform nobody can reach (px).
@export var stepping_stone_length: float = 180.0

@export_group("Features (issue #4)")
## Minimum distance between any two floor features (drums, updrafts, harmonics) (px).
@export var feature_min_spacing: float = 280.0
## Keep features this far from the spawn (left) and the exit (right) (px).
@export var feature_spawn_clearance: float = 420.0
## Keep features this far from the exit (px).
@export var feature_exit_clearance: float = 380.0
## Placement attempts per feature before giving up.
@export var feature_tries: int = 24

@export_group("Waves (issue #25)")
## Fewest waves in a fight room.
@export var waves_min: int = 2
## Most waves in a fight room (also limited by the bar).
@export var waves_max: int = 4
## Smallest wave.
@export var wave_size_min: int = 3
## Up to this many more enemies, at random.
@export var wave_size_extra: int = 2
## Extra enemies per wave for each bar climbed.
@export var wave_size_per_bar: int = 1
## Largest possible wave.
@export var wave_size_cap: int = 8
## No enemy type appears more than this many times in one wave.
@export var max_same_type_per_wave: int = 2
## Chance that a wave calls reinforcements once half of it is down.
@export var reinforcement_chance: float = 0.35
## Fewest reinforcements.
@export var reinforcement_size_min: int = 1
## Most reinforcements.
@export var reinforcement_size_max: int = 3
## Enemies in one wave spawn at least this far apart (px).
@export var spawn_spacing: float = 170.0
## ...and at least this far from the player (px).
@export var spawn_player_distance: float = 320.0

@export_group("Map (issue #8)")
## Rooms per branching layer between the entry fight and the fermata.
@export var branch_layers: PackedInt32Array = PackedInt32Array([2, 3, 3, 3, 3, 2])
## Special rooms placed once each across the branching layers.
@export var special_rooms: PackedStringArray = PackedStringArray(["elite", "shop", "chest", "chest", "teach", "teach"])
## Chance a bar gets a second elite on its last branching layer.
@export var second_elite_chance: float = 0.6
## Chance the fermata layer also offers a chest.
@export var rest_or_chest_chance: float = 0.35
## Chance that a cleared fight room offers a bonus pick.
@export var bonus_drop_chance: float = 0.4
