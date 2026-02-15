ArrayList<Sheep> sheep;

int totalSheep = 25;

float penR = 300;
PVector penCenter;

// Grass grid
GrassTile[][] grassGrid;
int grassCols, grassRows;
float cellSize = 25;

// Game timer
int startTime;
int elapsedSeconds = 0;
boolean gameWon = false;
int winTime = 0;

// Dog trail effect
ArrayList<PVector> dogTrail;
int maxTrail = 12;

// Growth rate multiplier (controlled by slider)
float growthMultiplier = 1.0;

// Flee force (controlled by slider)
float fleeForce = 0.7;

// Slider menu
SliderMenu settingsMenu;

void setup() {
  size(1000, 900);
  penCenter = new PVector(width/2, height/2);

  // Initialize grass grid
  grassCols = ceil(width / cellSize);
  grassRows = ceil(height / cellSize);
  grassGrid = new GrassTile[grassCols][grassRows];

  for (int i = 0; i < grassCols; i++) {
    for (int j = 0; j < grassRows; j++) {
      grassGrid[i][j] = new GrassTile(i, j, cellSize);
    }
  }

  // Suppress grass growth inside pen
  for (int i = 0; i < grassCols; i++) {
    for (int j = 0; j < grassRows; j++) {
      float cx = i * cellSize + cellSize / 2;
      float cy = j * cellSize + cellSize / 2;
      if (dist(cx, cy, penCenter.x, penCenter.y) < penR / 2) {
        grassGrid[i][j].growth = 0;
        grassGrid[i][j].growthRate = 0;  // no grass in pen
      }
    }
  }

  // Initialize sheep
  sheep = new ArrayList<Sheep>();

  for (int i = 0; i < totalSheep; i++) {
    float sx, sy;
    do {
      sx = random(50, width - 50);
      sy = random(50, height - 50);
    } while (dist(sx, sy, penCenter.x, penCenter.y) < penR/2 + 30);
    sheep.add(new Sheep(sx, sy));
  }

  // Dog trail
  dogTrail = new ArrayList<PVector>();

  startTime = millis();

  // Create slider menu (only on first run or if null)
  if (settingsMenu == null) {
    settingsMenu = new SliderMenu();
  }
}

void draw() {

  background(70, 130, 60);

  // Apply slider values each frame
  applySliderValues();

  // Timer
  if (!gameWon) {
    elapsedSeconds = (millis() - startTime) / 1000;
  }

  // Update and draw grass grid
  for (int i = 0; i < grassCols; i++) {
    for (int j = 0; j < grassRows; j++) {
      grassGrid[i][j].grow(growthMultiplier);
      grassGrid[i][j].display();
    }
  }

  drawPen();

  // Only move dog if menu is NOT consuming mouse
  float dogX = mouseX;
  float dogY = mouseY;

  // Update and draw sheep
  for (Sheep s : sheep) {
    s.flock(sheep);
    s.collide(sheep);
    if (!settingsMenu.isConsuming()) {
      s.fleeDog(dogX, dogY, fleeForce);
    }
    s.boundary();
    s.update(grassGrid, grassCols, grassRows, cellSize);
    s.display();
  }

  if (!settingsMenu.isConsuming()) {
    updateDogTrail();
    drawDogTrail();
    drawDog();
  } else {
    drawDogTrail();  // still render existing trail fading out
  }

  drawHUD();

  // Settings menu on top of everything
  settingsMenu.update();
  settingsMenu.display();

  // Check win
  if (!gameWon) {
    int count = 0;
    for (Sheep s : sheep) {
      if (s.inPen) count++;
    }
    if (count == totalSheep) {
      gameWon = true;
      winTime = elapsedSeconds;
    }
  }
}

void applySliderValues() {
  // Pen radius
  penR = settingsMenu.getPenRadius();

  // Growth multiplier
  growthMultiplier = settingsMenu.getGrowthMult();

  // Flee force
  fleeForce = settingsMenu.getFleeForce();

  // Per-sheep values
  float spd = settingsMenu.getMaxSpeed();
  float fear = settingsMenu.getFearRadius();
  float neigh = settingsMenu.getNeighborDist();
  for (Sheep s : sheep) {
    s.maxSpeed = spd;
    s.fearRadius = fear;
    s.neighborDist = neigh;
  }

  // Sheep count — resize list if changed
  int target = settingsMenu.getSheepCount();
  if (target != totalSheep) {
    totalSheep = target;
    // Add sheep if needed
    while (sheep.size() < totalSheep) {
      float sx, sy;
      do {
        sx = random(50, width - 50);
        sy = random(50, height - 50);
      } while (dist(sx, sy, penCenter.x, penCenter.y) < penR/2 + 30);
      Sheep ns = new Sheep(sx, sy);
      ns.maxSpeed = spd;
      ns.fearRadius = fear;
      ns.neighborDist = neigh;
      sheep.add(ns);
    }
    // Remove sheep if needed
    while (sheep.size() > totalSheep) {
      sheep.remove(sheep.size() - 1);
    }
  }
}

void updateDogTrail() {
  dogTrail.add(new PVector(mouseX, mouseY));
  if (dogTrail.size() > maxTrail) {
    dogTrail.remove(0);
  }
}

void drawDogTrail() {
  noStroke();
  for (int i = 0; i < dogTrail.size(); i++) {
    PVector p = dogTrail.get(i);
    float alpha = map(i, 0, dogTrail.size(), 10, 60);
    float sz = map(i, 0, dogTrail.size(), 4, 16);
    fill(110, 70, 40, alpha);
    ellipse(p.x, p.y, sz, sz);
  }
}

void drawDog() {
  // Shadow
  noStroke();
  fill(0, 30);
  ellipse(mouseX + 3, mouseY + 3, 30, 20);

  // Body
  fill(110, 70, 40);
  ellipse(mouseX, mouseY, 28, 24);

  // Ears
  fill(80, 45, 20);
  ellipse(mouseX - 11, mouseY - 9, 10, 12);
  ellipse(mouseX + 11, mouseY - 9, 10, 12);

  // Snout
  fill(140, 95, 55);
  ellipse(mouseX, mouseY + 4, 12, 8);

  // Nose
  fill(30);
  ellipse(mouseX, mouseY + 2, 5, 4);

  // Eyes
  fill(20);
  ellipse(mouseX - 5, mouseY - 3, 4, 4);
  ellipse(mouseX + 5, mouseY - 3, 4, 4);
}

void drawPen() {
  // Pen ground — dirt area
  noStroke();
  fill(120, 95, 60, 80);
  ellipse(penCenter.x, penCenter.y, penR, penR);

  // Inner ground detail
  fill(130, 105, 70, 40);
  ellipse(penCenter.x, penCenter.y, penR * 0.6, penR * 0.6);

  // Fence
  stroke(100, 60, 25);
  strokeWeight(4);
  noFill();
  ellipse(penCenter.x, penCenter.y, penR, penR);

  // Fence posts
  float visualR = penR / 2;
  for (int a = 0; a < 360; a += 20) {
    float px = penCenter.x + cos(radians(a)) * visualR;
    float py = penCenter.y + sin(radians(a)) * visualR;

    // Post shadow
    fill(60, 40, 15, 50);
    noStroke();
    ellipse(px + 2, py + 2, 9, 5);

    // Post
    fill(100, 60, 20);
    rect(px - 3, py - 6, 6, 12, 1);

    // Post cap
    fill(120, 75, 30);
    rect(px - 4, py - 7, 8, 3, 1);
  }

  // Horizontal rail between posts
  stroke(90, 55, 20, 120);
  strokeWeight(2);
  noFill();
  ellipse(penCenter.x, penCenter.y, penR - 6, penR - 6);
}

void drawHUD() {
  int count = 0;
  for (Sheep s : sheep) {
    if (s.inPen) count++;
  }

  // Top-left panel
  fill(0, 140);
  noStroke();
  rect(10, 10, 250, 65, 10);

  fill(255);
  textSize(18);
  textAlign(LEFT, TOP);
  text("Sheep in pen: " + count + " / " + totalSheep, 20, 16);

  // Timer
  int mins = elapsedSeconds / 60;
  int secs = elapsedSeconds % 60;
  String timeStr = nf(mins, 2) + ":" + nf(secs, 2);
  textSize(14);
  fill(200);
  text("Time: " + timeStr, 20, 42);

  // Progress bar
  float progress = (float)count / totalSheep;
  fill(50, 50, 50, 150);
  rect(20, 60, 220, 8, 4);
  fill(80, 200, 80);
  rect(20, 60, 220 * progress, 8, 4);

  // Win message
  if (gameWon) {
    // Overlay
    fill(0, 100);
    rect(0, 0, width, height);

    // Win box
    fill(30, 80, 30, 220);
    stroke(120, 200, 80);
    strokeWeight(3);
    rect(width/2 - 220, height/2 - 60, 440, 120, 16);

    noStroke();
    textSize(40);
    textAlign(CENTER, CENTER);
    fill(255, 230, 60);
    text("ALL SHEEP HERDED!", width/2, height/2 - 20);

    textSize(22);
    fill(200, 255, 200);
    text("Time: " + nf(winTime / 60, 2) + ":" + nf(winTime % 60, 2), width/2, height/2 + 25);
  }

  // Legend — bottom right
  drawLegend();
}

void drawLegend() {
  float lx = width - 180;
  float ly = height - 85;

  fill(0, 110);
  noStroke();
  rect(lx - 10, ly - 10, 180, 80, 8);

  textSize(11);
  textAlign(LEFT, TOP);

  // Sugar indicator
  fill(220, 195, 60);
  ellipse(lx + 6, ly + 6, 10, 10);
  fill(230);
  text("Sugary grass", lx + 18, ly);

  // Nutrition indicator
  fill(50, 160, 50);
  rect(lx, ly + 18, 12, 12, 2);
  fill(230);
  text("Nutritious grass", lx + 18, ly + 19);

  // Hungry sheep
  fill(255, 100, 100);
  ellipse(lx + 6, ly + 46, 8, 8);
  fill(230);
  text("Hungry sheep", lx + 18, ly + 40);

  // Grazing sheep
  fill(180, 255, 180);
  ellipse(lx + 6, ly + 62, 8, 8);
  fill(230);
  text("Grazing sheep", lx + 18, ly + 56);
}

// ─── Input forwarding ──────────────────────────────────────
void mousePressed() {
  settingsMenu.mousePressed(mouseX, mouseY);
}

void mouseDragged() {
  settingsMenu.mouseDragged(mouseX, mouseY);
}

void mouseReleased() {
  settingsMenu.mouseReleased();
}

void mouseWheel(MouseEvent event) {
  settingsMenu.mouseScrolled(event.getCount());
}

// Press R to restart
void keyPressed() {
  if (key == 'r' || key == 'R') {
    setup();
  }
}
