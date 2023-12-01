local monitor = peripheral.find('monitor')

function setScale(string_length)
    for i = 5, 0.5, -0.5 do
        monitor.setTextScale(i)
        width, height = monitor.getSize()
        if string_length <= width and string_length <= height then
            break
        end
    end
end

setScale(10)

Color = {
    BORDER = colors.orange;
    LETTER = colors.gray;
    WHITE_SQUARE = colors.yellow;
    BLACK_SQUARE = colors.brown;
    WHITE_PIECE = colors.white;
    BLACK_PIECE = colors.black;
    PIECE_POSITION = colors.green;
    POSSIBLE_MOVE = colors.red;
    LAST_MOVE = colors.lightBlue;
    CHECK = colors.red;
}

Class = {}

function Class:new()
    local obj = {}
    self.__index = self
    return setmetatable(obj, self)
end

function Class:extend()
    local child = {}
    return setmetatable(child, {__index = self})
end

--
-- PIECE
--

Piece = Class:extend()

function Piece:new(isWhite, pos)
    local private = {isWhite = isWhite, pos = pos}
    local public = {}
    self.__index = self
    return setmetatable(public, self)
end

function Piece:isWhite()
    return private.isWhite
end

function Piece:getPos()
    return private.pos
end

function Piece:move(toRank, toFile, board)
    board:movePiece(self, toRank, toFile)
end

function Piece:getLetter()
    return private.letter
end

function Piece:getPossibleMoves(board)
    return nil
end

function Piece:getAttackedSquares()
    return nil
end

--
-- PAWN
--

Pawn = Piece:extend()
Pawn.letter = 'P'

function Pawn:getPossibleMoves(board)
    return {}
end

function Pawn:getAttackedSquares()
    local y = self.y + self.isWhite and 1 or -1
    local list = {}
    if self.x ~= 8 then
        list[1] = {self.x + 1, y}
    end
    if self.x ~= 1 then
        list:insert({self.x - 1, y})
    end
    return list
end

function Pawn:isMovePossible()

--
-- KNIGHT
--

Knight = Piece:extend()
Knight.letter = 'N'

function Knight:getPossibleMoves(board)
    return {}
end

function Knight:getAttackedSquares()

end

--
-- BISHOP
--

Bishop = Piece:extend()
Bishop.letter = 'B'

function Bishop:getPossibleMoves(board)
    return {}
end

function Bishop:getAttackedSquares()

end

--
-- ROOK
--

Rook = Piece:extend()
Rook.letter = 'R'

function Rook:getPossibleMoves(board)
    return {}
end

function Rook:getAttackedSquares()

end

--
-- QUEEN
--

Queen = Piece:extend()
Queen.letter = 'Q'

function Queen:getPossibleMoves(board)
    return {}
end

function Queen:getAttackedSquares()

end

--
-- KING
--

King = Piece:extend()
King.letter = 'K'

function King:getPossibleMoves(board)
    return {}
end

function King:getAttackedSquares()

end

--
-- POSITION
--

Pos = Class:extend()

function Pos:new(rank, file)
    local private = {rank = rank, file = file}
    local public = {}

    self.__index = self
    return setmetatable(public, self)
end

function Pos:getRank()
    return private.rank
end

function Pos:getFile()
    return private.file
end

function Pos:setRank(rank)
    private.rank = rank
end

function Pos:setFile(file)
    private.file = file
end

function Pos:setValues(rank, file)
    self.setRank(rank)
    self.setFile(file)
end

function Pos:isValid()
    return rank ~= nil and file ~= nil and
           private.rank <= 8 and private.rank >= 1 and
           private.file <= 8 and private.file >= 1
end

function Pos:copy()
    return Pos:new(self.getRank(), self.getFile())
end

function Pos:toInt()
    return 8 * (self.getFile() - 1) + self.getRank() - 1
end

function Pos.fromInt(int)
    return Pos:new(math.floor(number / 8) + 1, number % 8 + 1)
end

function getPos(rank, file)
    return 8 * (self.getFile() - 1) + self.getRank() - 1
end

function getPosVaues(pos)
    return math.floor(number / 8) + 1, number % 8 + 1
end

--
-- MOVE
--

Move = Class:extend()

function Move:new(fromPos, toPos, board)
    local private = {board = board, moves = {}, captured = {}}



    local public = {}
    self.__index = self
    return setmetatable(public, self)
end

function Move:make(board)

end

function Move:undo(board)

end

--
-- MOVES
--

MoveList = Class:extend()

function Moves:addMove()

end

function Moves:getLastMove()

end

function Moves:undoLastMove()

end

--
-- BOARD
--

Board = Class:extend()

function Board:movePiece(piece, fromRank, fromFile, toRank, toFile)
    self.board[fromY][fromX] = nil
    self.board[toY][toX] = piece
    piece.setPos(toX, toY)
end



--
-- GAME
--

Game = Class:extend()

function Game:new()
    local private = {board = Board:new(), moves = Moves:new()}
    local public = {}
    self.__index = self
    return setmetatable(public, self)
end

function Game:getBoard()
    return private.board
end

function Game:setBoard(board)
    self.board = board
end

function Game:getMoves()
    return private.moves
end
    
function Game:movePiece(piece, fromRank, fromFile, toRank, toFile)
    self.board[fromY][fromX] = nil
    self.board[toY][toX] = piece
    piece.setPos(toX, toY)
end

function Game:getClassicInitialPosition()
    local board = Board:new()

    return board
end

function Game:rollbackLastMove()

end

function Game:draw()

end

--
-- MAIN
--

function main()
    while true do

    end
end

main()
