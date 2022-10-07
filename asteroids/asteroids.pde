/**************************************************************
 * File: asteroids.pde
 * Group: Chris Hollman, Mark Hay, Steve Lee
 * Date: Final Version: 24/05/2019
 * Course: COSC101 - Software Development Studio 1
 * Desc: Asteroids - a fun arcade game!
 * Usage: To be run in Processing 3 environment. Requires 'Minim 2.2.2', 'Sound' libraries 
 *        (Install: Sketch>ImportLibrary>Add Library...).'Press play button'.
 *   
 * Video summary: https://youtu.be/2mCmdirOP-M
 * Notes: Resource sources and credits are listed in resources.txt in game folder
 **************************************************************/
import processing.sound.*;
import ddf.minim.*;

// Ship variables
PImage shipImage;
PVector shipLocation;
PVector shipAcceleration;
PVector shipVelocity;
float shipRotation;
float shipMaxSpeed;
float shipMagnitude;

// Astroid variables
PImage asteroidImage0; // Image for asteroid type 0.
PImage asteroidImage1; // Image for asteroid type 1.
PImage asteroidImage2; // Image for asteroid type 2.
PImage asteroidImage3; // Image for asteroid type 3 ("the lava balls").
int astroNums; // Number of asteroids.
int numAstFrags; // Number of asteroid fragments to spawn when hit.
float spawnSizeMultiple; // Size multiplier to use for spawned asteroids.
float numSize; // Variable used to calculate size of asteroids. 
// Variable sets the boundary of initial postive and negative directional speed.
float asteroidMaxSpeed;
// Variable assists in the calculation of asteroid size from directional speed.
float asteroidSizeMultiplier; 
float minSpawnableSize; // Ensures only larger asteroids can spawn when hit.
float minAsteroidSize; // Ensures that asteroids are at least a certain size.
// Variables to hold directional values used for movement.
float astroDirectX, astroDirectY;
ArrayList<PVector> astroids; // PVector arrayList, used for location.
ArrayList<PVector> astroDirect; // PVector arrayList, used for direction.
ArrayList<Float> astroSize; // arrayList used for size of asteroids.
ArrayList<Float> asteroidRotation; // arrayList used for rotation of asteroids.
ArrayList<Integer> asteroidType; // arrayList used for type of asteroids.

// Alien variables
PImage alienImage;
PVector alienLocation;
PVector alienAcceleration;
PVector alienVelocity;
boolean alienAlive;
boolean alienHasBeenSpawned;
int alienTimeElapsed;
int alienSpawnTimer;
int alienLives;
int alienSizeMult;

// Shot variables
ArrayList<PVector> shots;
ArrayList<Float> shotRotation;
float shotSpeed;
boolean shotAllowed;

// Gamestate variables and resources
int score;
int playerLives;
int respawnDelay;
boolean alive;
boolean sUP=false, sDOWN=false, sRIGHT=false, sLEFT=false;
PFont gameFont;
boolean inMenu;
Minim minim;
AudioPlayer shot, explode, lose, alien;

void setup() {

  // Set canvas size to fullscreen
  fullScreen();

  // Ship
  shipImage = loadImage("Spaceship.png");
  shipRotation = -90;
  shipMaxSpeed = 5;
  shipMagnitude = 0.075;

  // Astros
  numAstFrags = 3; // Number of asteroid fragments to spawn when hit.
  // Variable sets boundaries of initial postive and negative directional speed.
  asteroidMaxSpeed = 4.2;  
  // Variable assists in calculation of asteroid size from directional speed.
  asteroidSizeMultiplier = 27;
  spawnSizeMultiple = 1.65; // Size multiplier to use for spawned asteroids.
  minSpawnableSize = 70; // Ensures only larger asteroids can spawn when hit.
  minAsteroidSize = 26; // Ensures that asteroids are at least a certain size.
  asteroidImage0 = loadImage("Asteroid0.png"); // Image for asteroid type 0.
  asteroidImage1 = loadImage("Asteroid1.png"); // Image for asteroid type 1.
  asteroidImage2 = loadImage("Asteroid2.png"); // Image for asteroid type 2.
  asteroidImage3 = loadImage("Asteroid3.png"); // Image for "the lava balls".

  // Shots
  shotSpeed = asteroidMaxSpeed*2.25;
  shotAllowed = true;

  // Alien
  alienImage = loadImage("Alien.png");
  alienSizeMult = 5;
  alienSpawnTimer = (int) random(10000, 20000);  
  alienAlive = false;
  alienHasBeenSpawned = false;

  //GameState
  respawnDelay = 3000;
  gameFont = loadFont("BlasterLaserFont.vlw");
  minim = new Minim(this);
  shot = minim.loadFile("shot2.wav");
  explode = minim.loadFile("explosion.wav");
  lose = minim.loadFile("lose.wav");
  alien = minim.loadFile("alien.wav");
  inMenu = true;

  newGame(); //Set non-constant variables to initial state
}

void draw() {

  // Set background to black
  background(0);

  if (inMenu) {
    drawMenu();
  } else {

    if (alive) {

      // Alien timer - Run until timer satisfied, then change to draw/collide
      if (!alienAlive) {
        alienTimer();
      } else {
        alienDraw();
        alienCollision();
      }
      moveShip();
      drawShip();
      collisionDetection();
      drawShots();
      drawAstroids();
      drawGameState();

    // Player not alive
    } else {
      drawGameState();
      delay(respawnDelay);

      // Player has satisfied win condition
      if (astroNums == 0) {
        newGame();
        inMenu = true;
      }

      // Player has lost a life
      if (playerLives > 0) {
        newLife();
        
      // All lives lost
      } else {
        newGame();
        inMenu = true;
      }
    }
  }
}

/**************************************************************
 * Function: moveShip()
 * Parameters: None
 * Returns: void
 
 * Desc: Adjusts the ships vectors based upon user input for the up
 down left right keys. 
 ***************************************************************/
void moveShip() {

  // Vector maths for accleration and velocity on up arrow
  if (sUP) {
    shipAcceleration = new PVector(
      cos(radians(shipRotation)), 
      sin(radians(shipRotation)));
    shipAcceleration.setMag(shipMagnitude);
    shipVelocity.add(shipAcceleration);
    shipVelocity.limit(shipMaxSpeed);
  }

  // Vector maths for acceleration and velocity on down arrow
  if (sDOWN) {  
    shipAcceleration = new PVector(
      cos(radians(shipRotation)), 
      sin(radians(shipRotation)));
    shipAcceleration.setMag(shipMagnitude);
    shipVelocity.sub(shipAcceleration);
    shipVelocity.limit(shipMaxSpeed);
  }

  // Ship rotate right
  if (sRIGHT) {
    shipRotation = shipRotation + 4;
  }

  // Ship rotate left
  if (sLEFT) {
    shipRotation = shipRotation - 4;
  }
}

/**************************************************************
 * Function: drawShip()
 * Parameters: None
 * Returns: void
 
 * Desc: Draws the ship onto the canvas after adusting for the
 rotation of the ship through translation.
 ***************************************************************/
void drawShip() {

  // Acceleration vector added to ships location
  shipLocation.add(shipVelocity);

  // Boundary checks to ensure ship remains on canvas
  shipBoundaryCheck();

  /* Logic for ship radian rotation with assistance from http://bit.ly/2IxMthS
  Orients the ship based on radian rotation about a specified point */
  pushMatrix();
  translate(shipLocation.x, shipLocation.y);  
  rotate(radians(shipRotation+90));
  image(shipImage, 0, 0);
  popMatrix();
}

/**************************************************************
 * Function: shipBoundaryCheck
 * Parameters: None
 * Returns: void
 
 * Desc: Ensures the ship remains on the canvas through x and you
 coordinate checks and manipulation if necessary.
 ***************************************************************/
void shipBoundaryCheck() {  

  // X coordinate check factoring in ship dimensons
  if (shipLocation.x < -(max(shipImage.height, shipImage.width))) {
    shipLocation.x = width+max(shipImage.height, shipImage.width);
  } else if (shipLocation.x > width+max(shipImage.height, shipImage.width)) {
    shipLocation.x = -(max(shipImage.height, shipImage.width));
  }

  // Y coordinate check factoring in ship dimensons
  if (shipLocation.y < -(max(shipImage.height, shipImage.width))) {
    shipLocation.y = height+max(shipImage.height, shipImage.width);
  } else if (shipLocation.y > height+max(shipImage.height, shipImage.width)) {
    shipLocation.y = -(max(shipImage.height, shipImage.width));
  }
}

/**************************************************************
 * Function: drawShots
 * Parameters: None
 * Returns: void
 
 * Desc: Draw the shots from the ship according to the direction
 / rotation of the ship at the time of the shot
 ***************************************************************/
void drawShots() {  

  // Loop through shots
  for (int i = 0; i < shots.size(); i++) {  
    float X = shots.get(i).x;
    float Y = shots.get(i).y;       

    // Only update the shots still within the canvas
    if ( (X > 0) && (X < width) && (Y > 0) && (Y < height) ) {

      // Gets the shot rotation
      float rot = shotRotation.get(i);         

      // Directs the shot
      float changeX = shotSpeed*cos(radians(rot));
      float changeY = shotSpeed*sin(radians(rot));  

      // Renders shot
      stroke(255);
      line(X, Y, X+changeX, Y+changeY);

      // Updates shot with new location
      shots.set(i, new PVector(X+changeX, Y+changeY));

    // Shots off canvas are removed
    } else {
      shots.remove(i);
      shotRotation.remove(i);
    }
  }
}

/**************************************************************
 * Function: drawAstroids
 * Parameters: None
 * Returns: void
 
 * Desc: Draws the asteroids according to the astroids and astroDirect 
 * PVector ArrayLists and uses the asteroidRotation and astroSize 
 * ArrayLists for information on sizing and rotation. 
 *****************************************************/
void drawAstroids() {
  
  // Loop through asteroids
  for (int i = 0; i < astroNums; i++) {
    
    // Type 3 'lava ball' asteroids, move and rotate faster than others
    if (asteroidType.get(i) == 3) {
      
      // Update position and rotation
      astroids.set(i, new PVector(astroids.get(i).x + 
        (1.5 * astroDirect.get(i).x), astroids.get(i).y + 
        (1.5 * astroDirect.get(i).y)));
        
      if (asteroidRotation.get(i) >= 0) {
        asteroidRotation.set(i, (asteroidRotation.get(i) + 10));
      } else {      
        asteroidRotation.set(i, (asteroidRotation.get(i) - 10));
      }
      
      // Update all other types of asteroids
    } else {   
      
      // Update position and rotation
      astroids.set(i, new PVector(astroids.get(i).x + 
        astroDirect.get(i).x, astroids.get(i).y + 
        astroDirect.get(i).y));
        
      if (asteroidRotation.get(i) >= 0) {
        asteroidRotation.set(i, (asteroidRotation.get(i) + 1));
      } else {         
        asteroidRotation.set(i, (asteroidRotation.get(i) - 1));
      }
    }  

    // Calculate how big asteroid should be
    numSize = asteroidSizeMultiplier * max(abs(astroDirect.get(i).x), 
      abs(astroDirect.get(i).y));
    
    // Ensure is greater than minimum and store
    while (numSize <= minAsteroidSize) {
      numSize *= 1.1;
    }
    astroSize.set(i, numSize); 

    // Wrap asteroids when off screen
    asteroidBoundaryCheck(i);

    //Apply rotation matrix to asteroid
    pushMatrix();
    translate(astroids.get(i).x, astroids.get(i).y);   
    rotate(radians(asteroidRotation.get(i)));    
    imageMode(CENTER);

    /* Draw the asteroid images according to type of asteroid, using the 
    astroSize arrayList element for the sizes. */
    if (asteroidType.get(i) == 0) {
      image(asteroidImage0, 0, 0, astroSize.get(i), astroSize.get(i));
    } else if (asteroidType.get(i) == 1) {
      image(asteroidImage1, 0, 0, astroSize.get(i), astroSize.get(i));
    } else if (asteroidType.get(i) == 2) {
      image(asteroidImage2, 0, 0, astroSize.get(i), astroSize.get(i));
    } else if (asteroidType.get(i) == 3) {

      // Lava balls are tinted orange.
      tint(255, 100, 0);
      image(asteroidImage3, 0, 0, astroSize.get(i), astroSize.get(i));
      noTint();
    }
    popMatrix();
  }
}

/**************************************************************
 * Function: asteroidBoundaryCheck()
 * Parameters: int i: the index of asteroid to check
 * Returns: void
 
 * Desc: Wraps asteroids around screen
 ***************************************************************/
void asteroidBoundaryCheck(int i) {
  
  // X coordinate check factoring in ship dimensions
  if (astroids.get(i).x > (width+astroSize.get(i))) {
    astroids.set(i, new PVector(astroids.get(i).x-(width+astroSize.get(i)*2), 
      astroids.get(i).y));
  }
  if (astroids.get(i).x < -astroSize.get(i)) {
    astroids.set(i, new PVector(astroids.get(i).x+(width+astroSize.get(i)*2), 
      astroids.get(i).y));
  }
  
  // Y coordinate check factoring in ship dimensions
  if (astroids.get(i).y > (height+astroSize.get(i))) {
    astroids.set(i, new PVector(astroids.get(i).x, 
      astroids.get(i).y - (height+astroSize.get(i)*2)));
  }
  if (astroids.get(i).y < -astroSize.get(i)) {
    astroids.set(i, new PVector(astroids.get(i).x, 
      astroids.get(i).y + (height+astroSize.get(i)*2)));
  }
}

/**************************************************************
 * Function: breakAsteroid()
 * Parameters: None
 * Returns: none
 
 * Desc: If asteroid is large enough when hit, add asteroid fragments to asteroid list
 ***************************************************************/
void breakAsteroid(int i) {

  if (astroSize.get(i) >= minSpawnableSize) {

    // Create number of new asteroids based on value of numAstFrags.
    for (int a = 0; a <= (numAstFrags-1); a++) {
      astroids.add(new PVector(astroids.get(i).x,astroids.get(i).y));

      /* Calculate the x and y direction of the spawned asteroids based on 
      random values but allow for number of fragments and spawnSizeMultiple. */
      astroDirectX = random(-asteroidMaxSpeed/(numAstFrags/spawnSizeMultiple), 
        asteroidMaxSpeed/(numAstFrags/spawnSizeMultiple));
      astroDirectY = random(-asteroidMaxSpeed/(numAstFrags/spawnSizeMultiple), 
        asteroidMaxSpeed/(numAstFrags/spawnSizeMultiple));
        
      // Call function that ensures asteroid is not too small and slow.
      standardizeAsteroid();      

      // Add the x and y directional values to astroDirect PVector arrayList.
      astroDirect.add(new PVector(astroDirectX, astroDirectY));

      // Add random rotational values to asteroidRotation arrayList.
      asteroidRotation.add(new Float(random(-180, 180)));

      /* Make sure that the spawned asteroids are same type as the hit one 
      by adding to the asteroidType arrayList the correct value. */
      if (asteroidType.get(i) == 3) {
        asteroidType.add(new Integer(3));
      } else if (asteroidType.get(i) == 2) {
        asteroidType.add(new Integer(2));
      } else if (asteroidType.get(i) == 1) {
        asteroidType.add(new Integer(1));
      } else if (asteroidType.get(i) == 0) {
        asteroidType.add(new Integer(0));
      }

      // Add an astroSize arrayList placeholder float value.
      astroSize.add(0.0);

      // Increment the number of asteroids.
      astroNums++;
    }
  }
}

/**************************************************************
 * Function: standardizeAsteroid()
 * Parameters: None
 * Returns: void
 
 * Desc: Checks the directional movement values for x and y and hence the speed
 * and size of the asteroid, and ensures that they are not too small or slow.
 ***************************************************************/
void standardizeAsteroid() {
  
  // Ensure that the x directional values are not too small.
  if (astroDirectX < 0 && astroDirectX > -1) {
    astroDirectX = -1;
  } else if (astroDirectX > 0 && astroDirectX < 1) {
    astroDirectX = 1;
  }

  // Ensure that the y directional values are not too small.
  if (astroDirectY < 0 && astroDirectY > -1) {
    astroDirectY = -1;
  } else if (astroDirectY > 0 && astroDirectY < 1) {
    astroDirectY = 1;
  }

}

/**************************************************************
 * Function: collisionDetection()
 * Parameters: None
 * Returns: void
 
 * Desc: Detect and handle collisions between game objects
 ***************************************************************/
void collisionDetection() {
  
  // Get asteroid/shot pair of succesfull collision 
  int[] hitIndex = getHit();

  //Shot has collided with astroid
  if (hitIndex != null) {
    
    // Spawn asteroid fragments
    breakAsteroid(hitIndex[1]);
    
    // Remove shot from game
    shots.remove(hitIndex[0]);
    shotRotation.remove(hitIndex[0]);
    
    // Remove asteroid form game and create asteroid fragments if asteroid large enough
    astroids.remove(hitIndex[1]);
    astroSize.remove(hitIndex[1]);
    astroDirect.remove(hitIndex[1]);
    asteroidRotation.remove(hitIndex[1]);
    asteroidType.remove(hitIndex[1]);
    
    
    // Update gamestate values and play sound
    score  += 100;
    astroNums--;
    explode.cue(0);
    explode.play();
  }
  
  // Loop through all asteroids
  for (int i = 0; i < astroNums; i++) {

    //Ship has collided with astroid
    if (abs(shipLocation.dist(astroids.get(i)))-(shipImage.height/2.5) < 
      (astroSize.get(i)/2)) 
    {
      // Remove asteroid from game
      astroids.remove(i);
      astroSize.remove(i);
      astroDirect.remove(i);
      asteroidRotation.remove(i);
      asteroidType.remove(i);
      
      // Update game state variables and play sound
      playerLives--;
      alive = false;
      astroNums--;
      lose.cue(0);
      lose.play();
    }
  }
}

/**************************************************************
 * Function: getHit()
 * Parameters: None
 * Returns: int[]: int[0] contains the index of the shot, int[1] 
 * contains the index of the astroid. Returns null if no hit. 
 
 * Desc: Detects collisions between astroids and shots returns the index
 * of both to be handled. Uses point - circle collision detection.
 ***************************************************************/
int[] getHit() {

  int[] hitIndex = new int[2];
  
  // Loop through all asteroid/shot pairs
  for (int i = 0; i < shots.size(); i++) {
    for (int j = 0; j < astroids.size(); j++) {
      
      // If collision detected return reference to both 
      if (abs(shots.get(i).dist(astroids.get(j))) < astroSize.get(j)/2) {
        hitIndex[0] = i;
        hitIndex[1] = j;
        return hitIndex;
      }
    }
  }
  // No collision detected - return null
  return null;
}

/**************************************************************
 * Function: keyPressed()
 * Parameters: None
 * Returns: None
 
 * Desc: Handle key presses
 ***************************************************************/
void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) sUP=true;
    if (keyCode == DOWN) sDOWN=true;
    if (keyCode == RIGHT) sRIGHT=true;
    if (keyCode == LEFT) sLEFT=true;
  }

  // shotAllowed set by keyReleased, prevents holding down spacebar
  if (key == ' ' && shotAllowed) {

    // Additional maths to ensure shot is always fired from tip of ship
    shots.add(new PVector(
      shipLocation.x + cos(radians(shipRotation))*(shipImage.height/2), 
      shipLocation.y + sin(radians(shipRotation))*(shipImage.height/2)));
    shotRotation.add(shipRotation);

    // Prevents holding down of key to rapidfire shots automatically
    shotAllowed = false;

    // Sound effects only if in-game
    if (!inMenu)
    {
      shot.cue(0);
      shot.play();
    }

  }

  // Start game when enter key is pressed
  if (key == ENTER || key == RETURN) {
    inMenu = false;
  }
  
  // Quit game when 'q' is pressed(only functional while in menu)
  if (key == 'q' || key == 'Q') {
    if (inMenu) {
      exit();
    }
  }
}

/**************************************************************
 * Function: keyReleased()
 * Parameters: None
 * Returns: None
 
 * Desc: Handle releases
 ***************************************************************/
void keyReleased() {
  if (key == CODED) {
    if (keyCode == UP) sUP=false;
    if (keyCode == DOWN) sDOWN=false;
    if (keyCode == RIGHT) sRIGHT=false;
    if (keyCode == LEFT) sLEFT=false;
  }

  // Allows new shot to be taken only on releasing spacebar
  if (key == ' ') {
    shotAllowed = true;
  }
}

/**************************************************************
 * Function: drawGameState()
 * Parameters: None
 * Returns: None 
 
 * Desc: Draws game state objects(score, lives, win/lose messages etc.)
 * to the screen.
 ***************************************************************/
void drawGameState() {

  // Draw score
  textFont(gameFont, 30);
  String scoreT = nf(score, 2);
  textAlign(RIGHT);
  text(scoreT, 120, 30);

  // Draw lives
  for (int i = playerLives; i > 0; i--) {
    image(shipImage, 130-20*i, 50, shipImage.width/2, shipImage.height/2);
  }

  // Draw start / end messages
  textFont(gameFont, 100);
  textAlign(CENTER, CENTER);
  if (playerLives == 0) {
    text("G A M E   O V E R", width/2, height/2);
  } else {
    if (astroNums == 0) {
      alive = false; 
      text("Y O U   W I N", width/2, height/2);
    }
  }
}

/**************************************************************
 * Function: newGame()
 * Parameters: None
 * Returns: None
 
 * Desc: Sets all non-constant game variables to the state required for a new game. 
 ***************************************************************/
void newGame() {

  // Game state reset
  playerLives = 3;
  score = 0;
  astroNums = 17;
  alive = true;

  //Astroids random but not near ship, random travel direction.
  astroids = new ArrayList<PVector>();
  astroDirect = new ArrayList<PVector>();
  astroSize = new ArrayList<Float>();
  asteroidRotation = new ArrayList<Float>();
  asteroidType = new ArrayList<Integer>();
  
  for (int i = 0; i < astroNums; i++) {
    astroDirectX = random(-asteroidMaxSpeed, asteroidMaxSpeed);
    astroDirectY = random(-asteroidMaxSpeed, asteroidMaxSpeed);
    
    // Call function that ensures asteroid is not too small and slow.
    standardizeAsteroid();
    
    astroDirect.add(new PVector(astroDirectX, astroDirectY));     
    asteroidRotation.add(new Float(random(-180, 180)));
    asteroidType.add(new Integer(int(random(0, 4))));
    astroSize.add(i, 0.0);
  }

  // Alien reset
  alienAlive = false;
  alienHasBeenSpawned = false;
  alienTimeElapsed = millis();

  newLife();
}

/**************************************************************
 * Function: newLife()
 * Parameters: None
 * Returns: None
 
 * Desc: Resets necessary game variables to begin a new life.
 ***************************************************************/
void newLife() {
  
  // Loop through all asteroids 
  astroids = new ArrayList<PVector>();
  for (int i = 0; i < astroNums; i++) {
    
    //Spawn atleast 200px away from screen center(ship)
    astroids.add(new PVector(random(width/2)-200, (random(height/2)-200)));
  }

  // No shots on screen
  shots = new ArrayList<PVector>();
  shotRotation = new ArrayList<Float>();

  // Ship starts center screen, stationary
  shipLocation = new PVector(width/2, height/2);
  shipAcceleration = new PVector(0, 0);
  shipVelocity = new PVector(0, 0);
  shipRotation = -90;

  /* If alien was alive at time of player death, it is removed and
     does not respawn */
  if (alienAlive) {
    alienSpawn();
  }

  // Player alive
  alive = true;
}

/**************************************************************
 * Function: drawMenu()
 * Parameters: None
 * Returns: None
 
 * Desc: Draw game menu elements to the screen
 ***************************************************************/
void drawMenu() {
  
  // Draw title
  textFont(gameFont, 150);
  textAlign(CENTER, CENTER);
  text("ASTEROIDS", width/2, height/2 - height/8);

  // Draw menu options
  textSize(40);
  text("Play [ENTER]", width/2, height/2+height/10);
  text("Quit [Q]", width/2, height/2+height/6);
}

/**************************************************************
 * Function: alienDraw()
 * Parameters: None
 * Returns: None
 
 * Desc: Renders image of alien spaceship if lives remain
 ***************************************************************/
void alienDraw() {

  // Move and draw alien whilst it has lives remaining
  if (alienLives > 0) {
    alienAcceleration = PVector.sub(shipLocation, alienLocation);
    alienAcceleration.setMag(0.1);
    alienVelocity.add(alienAcceleration);
    alienVelocity.limit(2);
    alienLocation.add(alienVelocity);

    // Alien size changes dependent on alienLives remaining
    image(alienImage, alienLocation.x, alienLocation.y, alienImage.width + 
      (alienSizeMult*alienLives), alienImage.height+(alienSizeMult*alienLives));

  // Alien must be dead, sound effects and update score
  } else {
    explode.cue(0);
    explode.play();
    alienAlive = false;    
    score = score + 300;
  }
}

/**************************************************************
 * Function: alienSpawn()
 * Parameters: None
 * Returns: None
 
 * Desc: Creates alien on activation from alienTimer()
 ***************************************************************/
void alienSpawn()
{
  // Spawn alien at random X, and slightly offset Y at top of screen
  alienLocation = new PVector((int)random(-alienImage.width, width + 
    alienImage.width), -alienImage.height*1.5);
  alienAcceleration = new PVector(0, 0);
  alienVelocity = new PVector(0, 0);
  alienLives = 3;

  // Alien size changes dependent on alienLives remaining
  image(alienImage, alienLocation.x, alienLocation.y, alienImage.width + 
    (alienSizeMult*alienLives), alienImage.height+(alienSizeMult*alienLives));
}

/**************************************************************
 * Function: alienDraw()
 * Parameters: None
 * Returns: None
 
 * Desc: Activates alien after random time interval
 ***************************************************************/
void alienTimer()
{
  // Spawns alien after given timee period elapsed and if none yet spawned
  if ((millis() > alienTimeElapsed + alienSpawnTimer) && !alienHasBeenSpawned)
  {
    alienSpawn();
    alienAlive = true;
    alienHasBeenSpawned = true;
    // Resets timer
    alienTimeElapsed = millis();
    alien.cue(0);
    alien.play();
  }
}

/**************************************************************
 * Function: alienCollision()
 * Parameters: None
 * Returns: None
 
 * Desc: Checks for collision between alien and player / shots
 ***************************************************************/
void alienCollision()
{
  if (alienAlive) {

    // Shot collision with Alien
    for (int i = 0; i < shots.size(); i++) {
      // Circle based collision detection
      if (abs(shots.get(i).dist(alienLocation)) < (alienImage.width/2) + 
        (5*alienLives)) {

        // Reduce alien lives & remove shot
        alienLives--;
        shots.remove(i);
        shotRotation.remove(i);
      }
    }
    
    // Ship collision with Alien
    if (abs(shipLocation.dist(alienLocation))-(max(shipImage.width, 
      shipImage.height)/2.5) < (alienImage.width/2) + 
      (5*alienLives)) {

      lose.cue(0);
      lose.play();

      // Both player and alien die
      playerLives--;
      alive = false;
      alienAlive = false;
    }
  }
}
