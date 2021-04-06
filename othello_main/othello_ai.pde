/**
  Game metric tracker object
*/
class CurrentTracker {
  Move currentMove;
  float currentScore;
  
  CurrentTracker(float currentScore, Move currentMove) {
    this.currentMove = currentMove;
    this.currentScore = currentScore;
  }
}

/**
  ABNegamax runner returns best move and manages game logic
*/
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

/**
  ABNegamax minimax AI algorithm
  Returns CurrentTracker object (contains currentMove, currentScore)
*/
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

/**
  2-d array copier
*/
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

/**
  AIPlay both selects a move and implements it.
  It's given a list of legal moves because we've typically already done that
  work to check whether we should skip the turn because of no legal moves.
  You should implement this so that either white or black's move is selected;
  it's not any more complicated since you need to minimax regardless
*/
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

/**
  Modified evaluation function
  I referenced the following link for ideas on what makes a position stronger in othello:
  https://kartikkukreja.wordpress.com/2013/03/30/heuristic-function-for-reversiothello/

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
