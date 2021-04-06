void draw() {
  drawGame();
  if (gameOver) {
    int winner = findWinner(board);
    if (winner == BLACK) declareWinner(BLACK);
    else declareWinner(WHITE);
  }
}

/**
  Draw Handler
  - generates board state visualization
  - handles user input
*/
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


int boardCount = 0;

/**
  Commandline board visualization
*/
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

/**
  declareWinner: just for displaying winner text
*/
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

/**
  drawGame Helper
  draws Board Lines
*/
void drawBoardLines() {
  for (int i = 1; i <= NUM_COLUMNS; i++) {
    line(i*SQUARE_WIDTH, 0, i*SQUARE_WIDTH, SQUARE_WIDTH * NUM_COLUMNS);
    line(0, i*SQUARE_WIDTH, SQUARE_WIDTH * NUM_COLUMNS, i*SQUARE_WIDTH);
  }
}

/**
  drawGame Helper
  draws Board Pieces
*/
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
