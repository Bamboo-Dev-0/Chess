extends Node2D

var multiplayer_peer = ENetMultiplayerPeer.new()

var player_2_id = null
var player_1_color: Global.COLOR = randi_range(0, 1) as Global.COLOR

# Host a game
func host(port: int = 9999):
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer
	
	multiplayer_peer.peer_connected.connect(
		func(peer_id = multiplayer.get_unique_id()):
			if player_2_id == null:
				player_2_id = peer_id
				rpc("color", player_1_color)
	)

# Join as a client
func join(ip: String = "127.0.0.1", port: int = 9999):
	multiplayer_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = multiplayer_peer

# Receive the color of ourselves and start the game
@rpc("authority", "call_local")
func color(turn):
	Global.board.start_game(player_2_id == null != bool(turn))

# From chess script to all other clients via rpc
func send_move(start_pos, end_pos, promotion = null):
	rpc("receive_move", start_pos, end_pos, promotion)

# Receiving moves via rpc from client which made a move
@rpc("any_peer", "call_remote")
func receive_move(start_pos, end_pos, promotion):
	Global.board.set_move(start_pos, end_pos, promotion)
