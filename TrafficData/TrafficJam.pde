// AUTHOR: Mano de Agua
// TITLE: Traffic Jam
// DATA: tfltrafficcams from http://citydashboard.org
// DESCRIPTION: Loads 30 snapshots from 150 random traffic cameras from the feed.
//              Processes an area of each snapshot with a threshold filter after finding an optimal threshold value
//              Uses the black and white values from the snapshots to decide the color of each cell on the grid
//              Each circle is a window into one of the cameras
// NOTES: The sketch takes a while to load
//        Average frameRate is 27

class TrafficJam extends TheModule {
  
  color darkest = 0;
  color bright = 255;
  color dark = color( 80, 80, 160 );

  RetrieveData data;
  String[] urls;
  PImage[] images;
  int numOfImg = 30; // number of cameras to use
  int imgWidth = 352; // size of captured images
  int imgHeight = 288;
  int grid = 50; // number of rows and columns (MAX = 200)
  int cell = int( w / grid ); // size of a cell
  int posX, posY; // position of cells
  int numOfCells = grid * grid;

  PImage[] procImg   = new PImage[ numOfImg ]; // processed image
  PImage threshImg = createImage( grid, grid, RGB ); // intermediate image for finding the ideal THRESHOLD value
  PImage finalImg = createImage( grid, grid, RGB ); // intermediate image for drawing final output
  int index; // for cell calculation
  int invisibleIndex; // last image that is outside of the frame 
  boolean moveLane = false; // for moving lanes within the allowed time
  int movingLane; // based on invisibleIndex. Lane that should move
  int distance; // distance the circles will move on a refresh
  int[] targetX = new int[ 6 ]; // target position of circles moving (6 in a lane)
  int[] dX = new int[ 6 ]; // distance to target of each circle
  int[] offset = new int[ 5 ]; // offset of each lane in number of circles that have crossed the screen
  int whoMoves; // who is the lucky one to move first?
  float easing = 0.05;
  int moveCount = 0; // counter for frames during movement of lanes
  int movingCircles = 0; // number of circles that can move during update

  int numOfBlack, idealTHRESH; // final THRESHOLD needs to be = idealTHRESH * 0.1
  int proportionBW, prevProportionBW;

  // for comparing with last bit of the images pixels
  int blackBit = 0; 
  int imageBit;
  
  // circless' properties
  int numOfCircles = 30;
  int ring = 18; // max strokeWeight
  int gap = 10; // gap between circles
  int diagonal = int( sqrt( w * h + w * h ));
  int cirD = ( diagonal - 5 * ring - 4 * gap ) / 5; // diameter based on diagonal of screen
  int[][] cirX = new int[ 5 ][ numOfCircles / 5 ];
  int[][] cirY = new int[ 5 ][ numOfCircles / 5 ];
  
  TrafficJam() {
    super(); 
  }    

/////////////////////////////////// 
  void setMeUp() {      
    data = new RetrieveData( "tfltrafficcams" );
    urls = new String[ numOfImg ];
    images = new PImage[ numOfImg ];
    for (int i = 0; i<numOfImg; i++) {
      procImg[i] = createImage( grid, grid, RGB ); 
    }

    // initialization of circles' positions (will be rotated later by 45º)
    for (int i = 0; i<5; i++){    
      for (int j = 0; j<numOfCircles / 5; j++){
        cirX[i][j] = j * ( cirD + ring + gap) - ( cirD / 2 );
        cirY[i][j] = cirD / 2 + ring / 2 + i * ( cirD + ring + gap);
      }
    }

    data.refreshData();
    for (int i = 0; i<numOfImg; i++){
      processImage(i);
    }

    p.beginDraw();
    p.smooth();
    p.rectMode(CENTER);
    p.endDraw();
    
  }

/////////////////////////////////////  
  void refreshData() {
    
    moveLane = true;
    movingLane = floor( random( 5 ));
    distance = int(random( cirD / 2, cirD ));
    for (int j = 0; j<6; j++){
        targetX[j] = cirX[movingLane][j] + distance;
    }
  }
  
  
////////////////////////////////////
  void updateMe() {
    if (moveLane){
      // how many circles can move?
      if (moveCount % 20 == 0 && movingCircles < 6){
        movingCircles++;
      }
      
      // set the first circle to move
      for (int j = 5; j >= 6 - movingCircles; j--){ 
        whoMoves = j - offset[movingLane];
        if (whoMoves < 0){
          whoMoves = 6 + whoMoves;
        }
        dX[whoMoves] = targetX[whoMoves] - cirX[movingLane][whoMoves];
        // Ease OUT
        if (dX[whoMoves] > distance * .7){
          float squareDist = dX[whoMoves] * dX[whoMoves];
          float t = 1 / squareDist * random( easing * 4000, easing * 5000 );
          cirX[movingLane][whoMoves] = int( lerp( cirX[movingLane][whoMoves], targetX[whoMoves], t ));
        }
        // Ease IN
        else if (dX[whoMoves] > 1){
          cirX[movingLane][whoMoves] += int( dX[whoMoves] * random ( easing, easing * 2 )); // Easing
          if (cirX[movingLane][whoMoves] > ( w + cirD + ring )) {
            int nextOne = whoMoves + 1;
            if (nextOne > 5){
              nextOne = 0;
            }
            cirX[movingLane][whoMoves] = cirX[movingLane][nextOne] - ( cirD + ring + gap );
            targetX[whoMoves] = targetX[nextOne] - ( cirD + ring + gap ); //
            // count how many circles have crossed the border in each lane
            offset[movingLane]++;
            if (offset[movingLane] > 5){
              offset[movingLane] = 0;
            }
          }
        }
      }
      moveCount++;
    }

    if (moveCount > 200){
      moveLane = false;
      moveCount = 0;
      movingCircles = 0;
    }
  } 

///////////////////////////////////// 
  void drawMe() {  
    p.beginDraw();
    p.background( bright );
    p.stroke( dark );
    p.strokeWeight( 1 );

    // The Grid
    for (int i = 1; i<grid; i++){
      p.line( 0, i * cell, w, i *cell );
      p.line( i * cell, 0, i *cell, h );
    }

    float translateDist = 2.1 * cirD;
    // Calculate visible cells and draw
    for (int i = 0; i<5; i++){
      p.noStroke();
      p.fill( darkest ); // color of cells
      for (int j = 0; j<numOfCircles / 5; j++){
        index = i * numOfCircles / 5 + j;
        finalImg.copy(procImg[ index ], 0, 0, grid, grid, 0, 0, grid, grid ); 
        finalImg.loadPixels();
        // correcting the position of circles after transformations
        float theta = polarTheta( cirX[i][j], cirY[i][j] );
        float radius = polarRadius( cirX[i][j], cirY[i][j] );
        theta -= QUARTER_PI;
        int correctedY = int( radius * sin( theta )) + 212;
        int correctedX = int( radius * cos( theta )) - 212;
        for (int k = 0; k<numOfCells; k++){
          posX = ( k % grid ) * cell;
          posY =  floor( k / grid ) * cell;
          imageBit = finalImg.pixels[k] >> 23 & 1;
          if (( dist( posX + cell / 2, posY + cell /2, correctedX, correctedY ) < cirD / 2 ) && ( imageBit == blackBit )) {
            p.rect( posX + cell / 2, posY + cell /2, cell + random( -1, 1 ), cell + random( -1, 1 ));
          }
        }
        if (!moveLane && cirX[i][j] < cirD / 2){
           invisibleIndex = index;
         } 
      }

      // Draw circles
      
      p.pushMatrix();
      p.rotate( - QUARTER_PI );
      p.translate( - translateDist, 0 );
      for (int j = 0; j<numOfCircles / 5; j++){

        p.noFill();
        p.strokeWeight( ring );
        p.stroke( bright );
        p.ellipse( cirX[i][j], cirY[i][j], cirD, cirD );
        p.strokeWeight( ring - 4 );
        p.stroke( darkest );
        p.ellipse( cirX[i][j], cirY[i][j], cirD, cirD );
        p.endDraw();
        
      }
      p.popMatrix();
    }
  }

  // Method for extracting B/W pixel info
  void processImage(int i) {
    urls[i] = data.getData( 2 + int( random( 150 )), 1 );
    images[i] = loadImage( urls[i] );  
    procImg[i].copy( images[i], ( imgWidth - 200 ) / 2, 50, grid, grid, 0, 0, grid, grid );
    procImg[i].resize( grid, grid );

    // Find best THRESHOLD value within 1 and 9
    proportionBW = 1;
    idealTHRESH = 5;
    for (int j = 1; j<10; j++){
      threshImg.copy( procImg[i], 0, 0, grid, grid, 0, 0, grid, grid );
      threshImg.filter( THRESHOLD, j * .1 );
      threshImg.loadPixels();
      numOfBlack = 0;
      for (int k = 0; k<numOfCells; k++){
        imageBit = threshImg.pixels[k] >> 23 & 1; // compare only first bit with 0
        if ( imageBit == blackBit ){
          numOfBlack++;          
        }
      }
      prevProportionBW = proportionBW;
      proportionBW = int( abs( 2 * numOfBlack - numOfCells ));
      if (proportionBW < prevProportionBW){
        idealTHRESH = j;
      }
    }
    procImg[i].filter( THRESHOLD, idealTHRESH * 0.1 );
    procImg[i].loadPixels();
  }

  float polarTheta(float x, float y) {
    float theta = atan2( y, x );
    return theta;
  }

  float polarRadius(float x, float y) {
    float radius = sqrt( sq(x) + sq(y) );
    return radius;
  }
}

