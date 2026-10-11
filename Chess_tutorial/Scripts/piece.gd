extends Node

const BLACK_BISHOP = preload("res://Assets/black_bishop.png")
const BLACK_KING = preload("res://Assets/black_king.png")
const BLACK_KNIGHT = preload("res://Assets/black_knight.png")
const BLACK_PAWN = preload("res://Assets/black_pawn.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Assets/black_rook.png")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Assets/white_king.png")
const WHITE_KNIGHT = preload("res://Assets/white_knight.png")
const WHITE_PAWN = preload("res://Assets/white_pawn.png")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Assets/white_rook.png")

var board_position: Vector2

func update_displayed_piece(piece):
	match piece:
		-6: self.texture = BLACK_KING
		-5: self.texture = BLACK_QUEEN
		-4: self.texture = BLACK_ROOK
		-3: self.texture = BLACK_BISHOP
		-2: self.texture = BLACK_KNIGHT
		-1: self.texture = BLACK_PAWN
		0: self.texture = null
		6: self.texture = WHITE_KING
		5: self.texture = WHITE_QUEEN
		4: self.texture = WHITE_ROOK
		3: self.texture = WHITE_BISHOP
		2: self.texture = WHITE_KNIGHT
		1: self.texture = WHITE_PAWN
