extends Sprite2D

const BOARD_SIZE = 8
const CELL_WIDTH = 18

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")

const PIECE_MOVE = preload("res://Assets/Piece_move.png")

@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn

@export var promotion_canvas: CanvasLayer
@export var white_pieces: Node
@export var black_pieces: Node
@export var camera: Camera2D

#Variables
# -6 = black king
# -5 = black queen
# -4 = black rook
# -3 = black bishop
# -2 = black knight
# -1 = black pawn
# 0 = empty
# 6 = white king
# 5 = white queen
# 4 = white rook
# 3 = white bishop
# 2 = white knight
# 1 = white pawn

var board: Array
var white_side: bool
var white_turn: bool = true

var moves = []
var selected_piece

var promotion_square = null

var white_king = false
var black_king = false
var white_rook_left = false
var white_rook_right = false
var black_rook_left = false
var black_rook_right = false

var en_passant = null

var white_king_pos = Vector2(0, 4)
var black_king_pos = Vector2(7, 4)

var fifty_move_rule = 0

var unique_board_moves : Array = []
var amount_of_same : Array = []

func _ready():
	Global.board = self
	
	board.append([4, 2, 3, 5, 6, 3, 2, 4])
	board.append([1, 1, 1, 1, 1, 1, 1, 1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([-1, -1, -1, -1, -1, -1, -1, -1])
	board.append([-4, -2, -3, -5, -6, -3, -2, -4])
	
	for button in get_tree().get_nodes_in_group("promotion_button"):
		button.pressed.connect(on_promotion_button_pressed.bind(int(button.name.strip_edges())))

func start_game(_turn):
	white_side = _turn
	if !white_side:
		camera.global_rotation_degrees = 180
		
		white_pieces.visible = false
		black_pieces.visible = true
	
	spawn_board_display()

func _input(event):
	if white_turn != white_side:
		return
	
	if !event.is_action_pressed("left_click") || is_mouse_out():
		return
	
	var selected_position = Vector2(int(abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH), int(snapped(get_global_mouse_position().x, 0) / CELL_WIDTH))
	# Picked own piece
	if side(white_turn) * board[selected_position.x][selected_position.y] > 0:
		if selected_piece != selected_position:
			selected_piece = selected_position
			delete_dots()
			show_options()
		else:
			delete_dots()
			selected_piece = null
	# Picked empty or enemy piece
	elif selected_piece != null:
		if moves.has(selected_position):
			if !is_promotion_square(selected_piece, selected_position):
				Multiplayer.send_move(selected_piece, selected_position)
			set_move(selected_piece, selected_position)
			delete_dots()
			selected_piece = null

func is_mouse_out():
	return !get_rect().has_point(to_local(get_global_mouse_position()))

func spawn_board_display():
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			if !white_side:
				holder.global_rotation_degrees = 180
			pieces.add_child(holder)
			
			holder.global_position = Vector2(j * CELL_WIDTH + (float(CELL_WIDTH) / 2), -i * CELL_WIDTH - (float(CELL_WIDTH) / 2))
			holder.board_position = Vector2(i, j)
	
	update_board_display()

func update_board_display():
	for piece in pieces.get_children():
		piece.update_displayed_piece(board[piece.board_position.x][piece.board_position.y])
	
	turn.texture = TURN_WHITE if white_turn else TURN_BLACK

func show_options():
	moves = get_moves(selected_piece)
	if moves == []:
		return
	show_dots()

func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(i.y * CELL_WIDTH + (float(CELL_WIDTH) / 2), -i.x * CELL_WIDTH - (float(CELL_WIDTH) / 2))

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(start_pos : Vector2, end_pos : Vector2, promotion = null):
	var just_now = false
	fifty_move_rule += 1
	if is_enemy(end_pos): fifty_move_rule = 0
	match board[start_pos.x][start_pos.y]:
		1:
			fifty_move_rule = 0
			if end_pos.x == 7: promote(end_pos, promotion)
			if end_pos.x == 3 && start_pos.x == 1:
				en_passant = end_pos
				just_now = true
			elif en_passant != null:
				if en_passant.y == end_pos.y && start_pos.y != end_pos.y && en_passant.x == start_pos.x:
					board[en_passant.x][en_passant.y] = 0
		-1:
			fifty_move_rule = 0
			if end_pos.x == 0: promote(end_pos, promotion)
			if end_pos.x == 4 && start_pos.x == 6:
				en_passant = end_pos
				just_now = true
			elif en_passant != null:
				if en_passant.y == end_pos.y && start_pos.y != end_pos.y && en_passant.x == start_pos.x:
					board[en_passant.x][en_passant.y] = 0
		4:
			if start_pos.x == 0 && start_pos.y == 0: white_rook_left = true
			elif start_pos.x == 0 && start_pos.y == 7: white_rook_right = true
		-4:
			if start_pos.x == 7 && start_pos.y == 0: black_rook_left = true
			elif start_pos.x == 7 && start_pos.y == 7: black_rook_right = true
		6:
			if start_pos.x == 0 && start_pos.y == 4:
				white_king = true
				if end_pos.y == 2:
					white_rook_left = true
					white_rook_right = true
					board[0][0] = 0
					board[0][3] = 4
				elif end_pos.y == 6:
					white_rook_left = true
					white_rook_right = true
					board[0][7] = 0
					board[0][5] = 4
			white_king_pos = end_pos
		-6:
			if start_pos.x == 7 && start_pos.y == 4:
				black_king = true
				if end_pos.y == 2:
					black_rook_left = true
					black_rook_right = true
					board[7][0] = 0
					board[7][3] = -4
				elif end_pos.y == 6:
					black_rook_left = true
					black_rook_right = true
					board[7][7] = 0
					board[7][5] = -4
			black_king_pos = end_pos
	if !just_now: en_passant = null
	
	if promotion != null:
		board[end_pos.x][end_pos.y] = promotion
	else:
		board[end_pos.x][end_pos.y] = board[start_pos.x][start_pos.y]
	
	board[start_pos.x][start_pos.y] = 0
	
	white_turn = !white_turn
	
	threefold_position(board)
	update_board_display()
	
	if (start_pos.x != end_pos.x || start_pos.y != end_pos.y) && side(white_turn) * board[end_pos.x][end_pos.y] > 0:
		start_pos = end_pos
		show_options()
	elif is_stalemate():
		if white_turn && is_in_check(white_king_pos) || !white_turn && is_in_check(black_king_pos): print("CHECKMATE")
		else: print("DRAW")
	
	if fifty_move_rule == 50: print("DRAW")
	elif insuficient_material(): print("DRAW")

func get_moves(selected : Vector2):
	var _moves = []
	match abs(board[selected.x][selected.y]):
		1: _moves = get_pawn_moves(selected)
		2: _moves = get_knight_moves(selected)
		3: _moves = get_bishop_moves(selected)
		4: _moves = get_rook_moves(selected)
		5: _moves = get_queen_moves(selected)
		6: _moves = get_king_moves(selected)
		
	return _moves

func get_rook_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
	
	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos): 
				board[pos.x][pos.y] = 4 * side(white_turn)
				board[piece_position.x][piece_position.y] = 0
				if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = 4 * side(white_turn)
			elif is_enemy(pos):
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = 4 * side(white_turn)
				board[piece_position.x][piece_position.y] = 0
				if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = 4 * side(white_turn)
				break
			else: break
			
			pos += i
	
	return _moves

func get_bishop_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos):
				board[pos.x][pos.y] = 3 * side(white_turn)
				board[piece_position.x][piece_position.y] = 0
				if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = 3 * side(white_turn)
			elif is_enemy(pos):
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = 3 * side(white_turn)
				board[piece_position.x][piece_position.y] = 0
				if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = 3 * side(white_turn)
				break
			else: break
			
			pos += i
	
	return _moves
	
func get_queen_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos):
				board[pos.x][pos.y] = 5 * side(white_turn)
				board[piece_position.x][piece_position.y] = 0
				if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = 5 * side(white_turn)
			elif is_enemy(pos):
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = 5 * side(white_turn)
				board[piece_position.x][piece_position.y] = 0
				if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = 5 * side(white_turn)
				break
			else: break
			
			pos += i
	
	return _moves

func get_king_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	if white_turn:
		board[white_king_pos.x][white_king_pos.y] = 0
	else:
		board[black_king_pos.x][black_king_pos.y] = 0
	
	for i in directions:
		var pos = piece_position + i
		if is_valid_position(pos):
			if !is_in_check(pos):
				if is_empty(pos): _moves.append(pos)
				elif is_enemy(pos):
					_moves.append(pos)
	
	if white_turn && !white_king:
		if !white_rook_left && is_empty(Vector2(0, 1)) && is_empty(Vector2(0, 2)) && !is_in_check(Vector2(0, 2)) && is_empty(Vector2(0, 3)) && !is_in_check(Vector2(0, 3)) && !is_in_check(Vector2(0, 4)):
			_moves.append(Vector2(0, 2))
		if !white_rook_right && !is_in_check(Vector2(0, 4)) && is_empty(Vector2(0, 5)) && !is_in_check(Vector2(0, 5)) && is_empty(Vector2(0, 6)) && !is_in_check(Vector2(0, 6)):
			_moves.append(Vector2(0, 6))
	elif !white_turn && !black_king:
		if !black_rook_left && is_empty(Vector2(7, 1)) && is_empty(Vector2(7, 2)) && !is_in_check(Vector2(7, 2)) && is_empty(Vector2(7, 3)) && !is_in_check(Vector2(7, 3)) && !is_in_check(Vector2(7, 4)):
			_moves.append(Vector2(7, 2))
		if !black_rook_right && !is_in_check(Vector2(7, 4)) && is_empty(Vector2(7, 5)) && !is_in_check(Vector2(7, 5)) && is_empty(Vector2(7, 6)) && !is_in_check(Vector2(7, 6)):
			_moves.append(Vector2(7, 6))
			
	if white_turn:
		board[white_king_pos.x][white_king_pos.y] = 6
	else:
		board[black_king_pos.x][black_king_pos.y] = -6
	
	return _moves
	
func get_knight_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]
	
	for i in directions:
		var pos = piece_position + i
		if is_valid_position(pos):
			if is_empty(pos):
				board[pos.x][pos.y] = 2 * side(white_turn)
				board[piece_position.x][piece_position.y] = 0
				if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = 2 * side(white_turn)
			elif is_enemy(pos):
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = 2 * side(white_turn)
				board[piece_position.x][piece_position.y] = 0
				if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = 2 * side(white_turn)
	
	return _moves

func get_pawn_moves(piece_position : Vector2):
	var _moves = []
	var is_first_move = false
	
	var direction = Vector2(side(white_turn), 0)
	
	if white_turn && piece_position.x == 1 || !white_turn && piece_position.x == 6: is_first_move = true
	
	if en_passant != null && (white_turn && piece_position.x == 4 || !white_turn && piece_position.x == 3) && abs(en_passant.y - piece_position.y) == 1:
		var pos = en_passant + direction
		board[pos.x][pos.y] = side(white_turn)
		board[piece_position.x][piece_position.y] = 0
		board[en_passant.x][en_passant.y] = 0
		if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = side(white_turn)
		board[en_passant.x][en_passant.y] = -side(white_turn)
	
	var pos = piece_position + direction
	if is_empty(pos):
		board[pos.x][pos.y] = side(white_turn)
		board[piece_position.x][piece_position.y] = 0
		if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = side(white_turn)
	
	pos = piece_position + Vector2(direction.x, 1)
	if is_valid_position(pos):
		if is_enemy(pos):
			var t = board[pos.x][pos.y]
			board[pos.x][pos.y] = side(white_turn)
			board[piece_position.x][piece_position.y] = 0
			if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
			board[pos.x][pos.y] = t
			board[piece_position.x][piece_position.y] = side(white_turn)
	pos = piece_position + Vector2(direction.x, -1)
	if is_valid_position(pos):
		if is_enemy(pos):
			var t = board[pos.x][pos.y]
			board[pos.x][pos.y] = side(white_turn)
			board[piece_position.x][piece_position.y] = 0
			if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
			board[pos.x][pos.y] = t
			board[piece_position.x][piece_position.y] = side(white_turn)
		
	pos = piece_position + direction * 2
	if is_first_move && is_empty(pos) && is_empty(piece_position + direction):
		board[pos.x][pos.y] = side(white_turn)
		board[piece_position.x][piece_position.y] = 0
		if white_turn && !is_in_check(white_king_pos) || !white_turn && !is_in_check(black_king_pos): _moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = side(white_turn)
	
	return _moves

func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false
	
func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false
	
func is_enemy(pos : Vector2):
	if side(white_turn) * board[pos.x][pos.y] < 0: return true
	return false

func promote(_var : Vector2, promotion = null):
	if promotion == null:
		promotion_square = _var
		promotion_canvas.visible = true
	else:
		board[_var.x][_var.y] = promotion * side(white_turn)

func on_promotion_button_pressed(value):
	board[promotion_square.x][promotion_square.y] = value
	promotion_canvas.visible = false
	Multiplayer.send_move(selected_piece, promotion_square, value)
	promotion_square = null
	update_board_display()

func is_in_check(king_pos: Vector2):
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	var pawn_direction = side(white_turn)
	var pawn_attacks = [
		king_pos + Vector2(pawn_direction, 1),
		king_pos + Vector2(pawn_direction, -1)
	]
	
	for i in pawn_attacks:
		if is_valid_position(i):
			if board[i.x][i.y] == -side(white_turn): return true
	
	for i in directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if board[pos.x][pos.y] == -6 * side(white_turn): return true
			
	for i in directions:
		var pos = king_pos + i
		while is_valid_position(pos):
			if !is_empty(pos):
				var piece = board[pos.x][pos.y]
				if (i.x == 0 || i.y == 0) && side(white_turn) * piece in [-4, -5]:
					return true
				elif (i.x != 0 && i.y != 0) && side(white_turn) * piece in [-3, -5]:
					return true
				break
			pos += i
			
	var knight_directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]
	
	for i in knight_directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if side(white_turn) * board[pos.x][pos.y] == -2:
				return true
				
	return false

func is_stalemate():
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			if side(white_turn) * board[i][j] > 0:
				if get_moves(Vector2(i, j)) != []: return false
	
	return true

func insuficient_material():
	var white_piece = 0
	var black_piece = 0
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			match board[i][j]:
				2, 3:
					if white_piece == 0: white_piece += 1
					else: return false
				-2, -3:
					if black_piece == 0: black_piece += 1
					else: return false
				6, -6, 0: pass
				_: #4 -4 1 -1 -5 5
					return false
	return true

func threefold_position(var1 : Array):
	for i in unique_board_moves.size():
		if var1 == unique_board_moves[i]:
			amount_of_same[i] += 1
			if amount_of_same[i] >= 3: print("DRAW")
			return
	unique_board_moves.append(var1.duplicate(true))
	amount_of_same.append(1)

func is_promotion_square(start_pos, end_pos) -> bool:
	if abs(board[start_pos.x][start_pos.y]) == 1:
		if end_pos.x == 7 && white_turn || end_pos.x == 0 && !white_turn:
			return true
	
	return false

func side(color) -> int:
	return 1 if color else -1
