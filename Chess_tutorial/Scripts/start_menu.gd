extends CanvasLayer

# Main level scene
const MAIN = preload("uid://wumwx2sgq27v")

# Start the local game
func _on_local_pressed() -> void:
	Global.local = true
	get_tree().change_scene_to_packed(MAIN)

# Host a p2p connection and switch the scene to main
func _on_online_host_pressed() -> void:
	Multiplayer.host()
	get_tree().change_scene_to_packed(MAIN)

# Join a p2p connection and switch the scene to main
func _on_online_join_pressed() -> void:
	Multiplayer.join()
	get_tree().change_scene_to_packed(MAIN)
