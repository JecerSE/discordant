class_name CinematicTuning
extends Resource
## Tuning for the intro cutscene and the title screen. Edit
## content/tuning/cinematic_tuning.tres. The shots themselves are in IntroData.

@export_group("Letterbox and captions")
## Height of the black bars at the top and bottom (px).
@export var letterbox_height: float = 92.0
## How long the bars take to slide in or out (s).
@export var letterbox_slide: float = 0.8
## Caption typing speed (characters per second).
@export var type_speed: float = 38.0
@export var caption_size: int = 24
## The skip hint fades out after this long (s).
@export var skip_hint_time: float = 3.5

@export_group("Camera")
## Screen shake strength (px) at a hit, and how fast it dies away (px/s).
@export var shake_strength: float = 14.0
@export var shake_decay: float = 40.0
## How long a white flash lasts (s).
@export var flash_time: float = 0.25

@export_group("Logo")
## Screen pixels per logo pixel, and where the logo's centre sits.
@export var logo_scale: int = 6
@export var logo_center: Vector2 = Vector2(640, 196)
## The slam: the logo starts this much bigger and lands over this long (s).
@export var slam_from_scale: float = 2.6
@export var slam_time: float = 0.14

@export_group("Title screen")
## How fast the title's scenery drifts (px/s at the near layer).
@export var title_drift: float = 14.0
## Seconds for the falling note to cross the screen.
@export var title_fall_time: float = 4.5

@export_group("Screen fades")
## Every screen change fades in from this colour over this long (s).
@export var fade_color: Color = Color(0.05, 0.045, 0.09)
@export var fade_time: float = 0.35
