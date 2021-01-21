import java.io.FileReader;
import java.io.FileWriter;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.util.Random;
import java.util.ArrayList;
import java.util.Arrays;

static final int SQUARE_WIDTH = 40;
static final int NUM_COLUMNS = 8;

boolean whiteTurn = true;
// We want to keep these enum values so that flipping ownership is just a sign change
static final int WHITE = 1;
static final int NOBODY = 0;
static final int BLACK = -1;
static final int TIE = 2;

Random rng = new Random();

static final float WIN_ANNOUNCE_X = NUM_COLUMNS / 2 * SQUARE_WIDTH;
static final float WIN_ANNOUNCE_Y = (NUM_COLUMNS + 0.5) * SQUARE_WIDTH;

static final int BACKGROUND_BRIGHTNESS = 128;

float WIN_VAL = 100;

boolean gameOver = false;

int[][] board;

void settings() {
  size(SQUARE_WIDTH * NUM_COLUMNS, SQUARE_WIDTH * (NUM_COLUMNS + 1));
}

void setup() {
  resetBoard();
}

void resetBoard() {
  board = new int[NUM_COLUMNS][NUM_COLUMNS];
  board[NUM_COLUMNS/2-1][NUM_COLUMNS/2-1] = WHITE;
  board[NUM_COLUMNS/2][NUM_COLUMNS/2] = WHITE;
  board[NUM_COLUMNS/2-1][NUM_COLUMNS/2] = BLACK;
  board[NUM_COLUMNS/2][NUM_COLUMNS/2-1] = BLACK;
}

void draw() {
  drawGame();
  if (gameOver) {
    int winner = findWinner(board);
    if (winner == BLACK) declareWinner(BLACK);
    else declareWinner(WHITE);
  }
}
  
void drawGame() {
  background(BACKGROUND_BRIGHTNESS);
  if (gameOver) return;
  drawBoardLines();
  ArrayList<Move> legalMoves = generateLegalMoves(board,true);
  while (whiteTurn && legalMoves.isEmpty()) {
    ArrayList<Move> blackLegalMoves = generateLegalMoves(board, false);
    if (!blackLegalMoves.isEmpty()) {
      //AIPlay(board, false, blackLegalMoves);
      AIPlay(board, false);
    } else {
      int winner = findWinner(board);   // We'll just end up doing this until the end of time
      drawBoardPieces();
      declareWinner(winner);
      return;
    }
    legalMoves = generateLegalMoves(board,true);
  }
  if (!whiteTurn) {
     ArrayList<Move> blackLegalMoves = generateLegalMoves(board,false);
     if (!blackLegalMoves.isEmpty()) {
       //AIPlay(board, false, blackLegalMoves);
       AIPlay(board, false);
     }
     whiteTurn = true;
  }
  if (mousePressed) {
    int col = mouseX / SQUARE_WIDTH;  // intentional truncation
    int row = mouseY / SQUARE_WIDTH;
   
    if (whiteTurn) {
      if (legalMoves.contains(new Move(row,col))) {
        board[row][col] = WHITE;
        capture(board, row, col, true);
        whiteTurn = false;
        drawBoardPieces();
        fill(255);
        text("thinking...", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
        whiteTurn = false;
      }
    }
    printBoard(board);
  }
  drawBoardPieces();
}


// findWinner assumes the game is over
int findWinner(int[][] board) {
  int whiteCount = 0;
  int blackCount = 0;
  for (int row = 0; row < NUM_COLUMNS; row++) {
    for (int col = 0; col < NUM_COLUMNS; col++) {
      if (board[row][col] == WHITE) whiteCount++;
      if (board[row][col] == BLACK) blackCount++;
    }
  }
  if (whiteCount > blackCount) {
    return WHITE;
  } else if (whiteCount < blackCount) {
    return BLACK;
  } else {
    return TIE;
  }
}

// declareWinner:  just for displaying winner text
void declareWinner(int winner) {
  textSize(28);
  textAlign(CENTER);
  fill(255);
  if (winner == WHITE) {
    text("Winner:  WHITE", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
  } else if (winner == BLACK) {
    text("Winner:  BLACK", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
  } else if (winner == TIE) {
    text("Winner:  TIE", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
  }
}

// drawBoardLines and drawBoardPieces draw the game
void drawBoardLines() {
  for (int i = 1; i <= NUM_COLUMNS; i++) {
    line(i*SQUARE_WIDTH, 0, i*SQUARE_WIDTH, SQUARE_WIDTH * NUM_COLUMNS);
    line(0, i*SQUARE_WIDTH, SQUARE_WIDTH * NUM_COLUMNS, i*SQUARE_WIDTH);
  }
}

void drawBoardPieces() {
  for (int row = 0; row < NUM_COLUMNS; row++) {
    for (int col= 0; col < NUM_COLUMNS; col++) {
      if (board[row][col] == WHITE) {
        fill(255,255,255);
      } else if (board[row][col] == BLACK) {
        fill(0,0,0);
      }
      if (board[row][col] != NOBODY) {
        ellipse(col*SQUARE_WIDTH + SQUARE_WIDTH/2, row*SQUARE_WIDTH + SQUARE_WIDTH/2,
                SQUARE_WIDTH-2, SQUARE_WIDTH-2);
      }
    }
  }
}

class Move {
  int row;
  int col;
  
  Move(int r, int c) {
    row = r;
    col = c;
  }
  
  public boolean equals(Object o) {
    if (o == this) {
      return true;
    }
    
    if (!(o instanceof Move)) {
      return false;
    }
    Move m = (Move) o;
    return (m.row == row && m.col == col);
  }
}

// Generate the list of legal moves for white or black depending on whiteTurn
ArrayList<Move> generateLegalMoves(int[][] board, boolean whiteTurn) {
  ArrayList<Move> legalMoves = new ArrayList<Move>();
  for (int row = 0; row < NUM_COLUMNS; row++) {
    for (int col = 0; col < NUM_COLUMNS; col++) {
      if (board[row][col] != NOBODY) {
        continue;  // can't play in occupied space
      }
      // Starting from the upper left ...short-circuit eval makes this not terrible
      if (capturesInDir(board,row,-1,col,-1, whiteTurn) ||
          capturesInDir(board,row,-1,col,0,whiteTurn) ||    // up
          capturesInDir(board,row,-1,col,+1,whiteTurn) ||   // up-right
          capturesInDir(board,row,0,col,+1,whiteTurn) ||    // right
          capturesInDir(board,row,+1,col,+1,whiteTurn) ||   // down-right
          capturesInDir(board,row,+1,col,0,whiteTurn) ||    // down
          capturesInDir(board,row,+1,col,-1,whiteTurn) ||   // down-left
          capturesInDir(board,row,0,col,-1,whiteTurn)) {    // left
            legalMoves.add(new Move(row,col));
      }
    }
  }
  return legalMoves;
}

// Check whether a capture will happen in a particular direction
// row_delta and col_delta are the direction of movement of the scan for capture
boolean capturesInDir(int[][] board, int row, int row_delta, int col, int col_delta, boolean whiteTurn) {
  // Nothing to capture if we're headed off the board
  if ((row+row_delta < 0) || (row + row_delta >= NUM_COLUMNS)) {
    return false;
  }
  if ((col+col_delta < 0) || (col + col_delta >= NUM_COLUMNS)) {
    return false;
  }
  // Nothing to capture if the neighbor in the right direction isn't of the opposite color
  int enemyColor = (whiteTurn ? BLACK : WHITE);
  if (board[row+row_delta][col+col_delta] != enemyColor) {
    return false;
  }
  // Scan for a friendly piece that could capture -- hitting end of the board
  // or an empty space results in no capture
  int friendlyColor = (whiteTurn ? WHITE : BLACK);
  int scanRow = row + 2*row_delta;
  int scanCol = col + 2*col_delta;
  while ((scanRow >= 0) && (scanRow < NUM_COLUMNS) &&
          (scanCol >= 0) && (scanCol < NUM_COLUMNS) && (board[scanRow][scanCol] != NOBODY)) {
      if (board[scanRow][scanCol] == friendlyColor) {
          return true;
      }
      scanRow += row_delta;
      scanCol += col_delta;
  }
  return false;
}

// capture:  flip the pieces that should be flipped by a play at (row,col) by
// white (whiteTurn == true) or black (whiteTurn == false)
// destructively modifies the board it's given
void capture(int[][] board, int row, int col, boolean whiteTurn) {
  for (int row_delta = -1; row_delta <= 1; row_delta++) {
    for (int col_delta = -1; col_delta <= 1; col_delta++) {
      if ((row_delta == 0) && (col_delta == 0)) {
        // the only combination that isn't a real direction
        continue;
      }
      if (capturesInDir(board, row, row_delta, col, col_delta, whiteTurn)) {
        // All our logic for this being valid just happened -- start flipping
        int flipRow = row + row_delta;
        int flipCol = col + col_delta;
        int enemyColor = (whiteTurn ? BLACK : WHITE);
        // No need to check for board bounds - capturesInDir tells us there's a friendly piece
        while(board[flipRow][flipCol] == enemyColor) {
          // Take advantage of enum values and flip the owner
          board[flipRow][flipCol] = -board[flipRow][flipCol];
          flipRow += row_delta;
          flipCol += col_delta;
        }
      }
    }
  }
}

//Modified evaluation function
//I referenced the following link for ideas on what makes a position stronger in othello:
//https://kartikkukreja.wordpress.com/2013/03/30/heuristic-function-for-reversiothello/
/*
 Strategy:
 - coin parity - who has more coins on the board
 - mobility - who has more options for the next move
 - corner control - who controls the corners? corners can't be flanked
*/
float evaluationFunction(int[][] board) {
  float evaluation = 0;
  //who has more coins on the board?
  float coinParity = 0;
  for (int r = 0; r < NUM_COLUMNS; r++) {
    for (int c = 0; c < NUM_COLUMNS; c++) {
      coinParity += board[r][c];
    }
  }
  evaluation += coinParity;
  
  //who has more options for the next move?
  ArrayList<Move> blackLegalMoves = generateLegalMoves(board, false);
  ArrayList<Move> whiteLegalMoves = generateLegalMoves(board, true);
  int blackMoves = blackLegalMoves.size();
  int whiteMoves = whiteLegalMoves.size();
  float mobility = whiteMoves - blackMoves;
  evaluation += mobility;
  
  //corners are the best position because they cannot be flanked
  //who has more corners? say corners are worth 3* normal spots
  int len = NUM_COLUMNS - 1;
  int cW = 3;
  float corners = cW*board[0][0] + cW*board[len][0] + cW*board[0][len] + cW*board[len][len];
  //evaluation += corners; //this seems to make the AI worse???
  
  return evaluation;
}

// checkGameOver returns the winner, or NOBODY if the game's not over
// --recall the game ends when there are no legal moves for either side
int checkGameOver(int[][] board) {
  ArrayList<Move> whiteLegalMoves = generateLegalMoves(board, true);
  if (!whiteLegalMoves.isEmpty()) {
    return NOBODY;
  }
  ArrayList<Move> blackLegalMoves = generateLegalMoves(board, false);
    if (!blackLegalMoves.isEmpty()) {
    return NOBODY;
  }
  // No legal moves, so the game is over
  return findWinner(board);
}

// AIPlay both selects a move and implements it.
// It's given a list of legal moves because we've typically already done that
// work to check whether we should skip the turn because of no legal moves.
// You should implement this so that either white or black's move is selected;
// it's not any more complicated since you need to minimax regardless
void AIPlay(int[][] board, boolean whiteTurn) {
  Move bestMove = getBestMoveABNegamax(board, 9);
  if (bestMove == null) {
    if (checkGameOver(board) == NOBODY) {
      println("AI had to skip a turn.");
      delay(100);
      return;
    } else {
      println("Game Over...");
      gameOver = true;
      int winner = findWinner(board);
      println("Winner: " + winner);
      return;
    }
  }
  else {
    board[bestMove.row][bestMove.col] = (whiteTurn? WHITE : BLACK);
    capture(board, bestMove.row, bestMove.col, whiteTurn);
    return;
  }
}

class CurrentTracker {
  Move currentMove;
  float currentScore;
  
  CurrentTracker(float currentScore, Move currentMove) {
    this.currentMove = currentMove;
    this.currentScore = currentScore;
  }
}

Move getBestMoveABNegamax(int[][] board, int maxDepth) {
  CurrentTracker best = abNegamax(board, maxDepth, 0, (float) Double.NEGATIVE_INFINITY, (float) Double.POSITIVE_INFINITY);
  if (best.currentMove == null) {
    if (checkGameOver(board) == NOBODY) {
      ArrayList<Move> blackLegalMoves = generateLegalMoves(board, false);
      if (!blackLegalMoves.isEmpty()) {
        return blackLegalMoves.get(0);
      }
    } else {
      println("Game Over...");
      gameOver = true;
      int winner = findWinner(board);
      println("Winner: " + winner);
      return null;
    }
  }
  return best.currentMove;
}

//based on abNegamax psueudocode in textbook
CurrentTracker abNegamax(int[][] board, int maxDepth, int currentDepth, float alpha, float beta) {
  //the game has a winner or currentDepth = maxDepth
  if (checkGameOver(board) != NOBODY || currentDepth == maxDepth) {
    return new CurrentTracker(evaluationFunction(board), null);
  }
  
  Move bestMove = null;
  float bestScore = (float) Double.NEGATIVE_INFINITY;
  
  for (Move move : generateLegalMoves(board, whiteTurn)) {
    int[][] newBoard = deepCopy(board);
    capture(newBoard, move.row, move.col, whiteTurn);
    
    CurrentTracker recurse = abNegamax(newBoard, maxDepth, currentDepth+1, (-1) * beta, (-1) * max(alpha, bestScore));
    float currentScore = (-1) * recurse.currentScore;
    
    if (currentScore > bestScore) {
      bestScore = currentScore;
      bestMove = move;
      
      if (bestScore >= beta) {
        return new CurrentTracker(bestScore, bestMove);
      }
    }
  }
  return new CurrentTracker(bestScore, bestMove);
}

int[][] deepCopy(int[][] original) {
    if (original == null) {
        return null;
    }
    final int[][] result = new int[original.length][];
    for (int i = 0; i < original.length; i++) {
        result[i] = Arrays.copyOf(original[i], original[i].length);
    }
    return result;
}

int boardCount = 0;

void printBoard(int[][] board) {
  println("Board: " + boardCount);
  println("Evaluation: " + evaluationFunction(board));
  for (int i = 0; i < board.length; i++) {
    for (int j = 0; j < board[i].length; j++) {
      print(board[i][j] + " ");
    }
    println();
  }
  println();
  boardCount++;
}
