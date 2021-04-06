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

/**
  Reset game board to starting condition
*/
void resetBoard() {
  board = new int[NUM_COLUMNS][NUM_COLUMNS];
  board[NUM_COLUMNS/2-1][NUM_COLUMNS/2-1] = WHITE;
  board[NUM_COLUMNS/2][NUM_COLUMNS/2] = WHITE;
  board[NUM_COLUMNS/2-1][NUM_COLUMNS/2] = BLACK;
  board[NUM_COLUMNS/2][NUM_COLUMNS/2-1] = BLACK;
}

/**
  Counts the board score to find the winning color
  findWinner assumes the game is over
*/
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

/**
  Move object
*/
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

/**
  Generate the list of legal moves for white or black depending on whiteTurn
*/
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

/**
  Check whether a capture will happen in a particular direction
  row_delta and col_delta are the direction of movement of the scan for capture
*/
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

/**
  capture:  flip the pieces that should be flipped by a play at (row,col) by
  white (whiteTurn == true) or black (whiteTurn == false)
  destructively modifies the board it's given
*/
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

/**
  checkGameOver returns the winner, or NOBODY if the game's not over
  recall the game ends when there are no legal moves for either side
*/
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
