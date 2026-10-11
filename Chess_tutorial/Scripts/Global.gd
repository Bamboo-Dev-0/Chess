extends Node

enum COLOR {
	WHITE = 1,
	BLACK = 0
}

# Game type - local or p2p
var local: bool = false

# Node of the board with the game script
var board = null


# TODO
# 1. Chess notation to move data
# 2. Restructure of script
# 3. Move history
