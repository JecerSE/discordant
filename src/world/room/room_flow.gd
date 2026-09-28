class_name RoomFlow
extends RoomCombat
## Layer 3 of 4. What happens when things end: kills, clears, rewards, boss
## defeats, death, leaving the room. Owned by RewardFlow (`reward_flow`); this
## layer keeps thin forwarders only where the room still calls itself bare.

func _clear() -> void:
	reward_flow.clear_room()


func _leave() -> void:
	reward_flow.leave_room()
