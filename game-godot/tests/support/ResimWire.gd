extends Node
## Test transport only. Own SceneMultiplayer branch; no LanSession replacement,
## file-message fallback or damage/result authority.
signal received(sender: int, payload: Dictionary)

@rpc("any_peer", "call_remote", "reliable")
func packet(payload: Dictionary) -> void:
	received.emit(multiplayer.get_remote_sender_id(), payload)

func send_to(peer: int, payload: Dictionary) -> void:
	packet.rpc_id(peer,payload)
