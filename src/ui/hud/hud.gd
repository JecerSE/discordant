class_name Hud
extends CanvasLayer
## The HUD root. Builds one widget per job and forwards the room's requests to them.
## Widgets only draw; overlays (menus, choices) are added as children of this layer.

const LAYER := 5

var room: Node
var enemy_roster: EnemyRoster

var _health: HudHealthPanel
var _powers: HudPowerBar
var _metronome: HudMetronome
var _boss: HudBossBar
var _status: HudRoomStatus
var _flash: HudEdgeFlash
var _announcer: HudAnnouncer
var _toasts: HudToasts
var _prompt: HudPrompt
var _card: HudCharacterCard


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_flash = _add(HudEdgeFlash.new())
	_health = _add(HudHealthPanel.new())
	_powers = _add(HudPowerBar.new())
	_metronome = _add(HudMetronome.new())
	_boss = _add(HudBossBar.new())
	_status = _add(HudRoomStatus.new())
	_prompt = _add(HudPrompt.new())
	_announcer = _add(HudAnnouncer.new())
	_toasts = _add(HudToasts.new())
	_card = _add(HudCharacterCard.new())


func _add(w: HudWidget) -> HudWidget:
	w.room = room
	w.enemy_roster = enemy_roster
	add_child(w)
	return w


func announce(title: String, subtitle: String, col: Color) -> void:
	_announcer.show_banner(title, subtitle, col)


func flash(col: Color) -> void:
	_flash.flash(col)


func beat_hit() -> void:
	_metronome.hit()


## Shows (or clears, with null) the prompt for the interactable in reach.
func set_prompt(target: Node) -> void:
	if target == null:
		_prompt.label = ""
		_prompt.detail = {}
		return
	_prompt.label = target.label()
	_prompt.detail = target.detail()


func show_character_card(char_id: String) -> void:
	_card.show_character(char_id)
