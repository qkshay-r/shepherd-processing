class GrassTile {

  int gridX, gridY;          // grid indices
  float x, y;                // pixel position (top-left of cell)
  float cellSize;

  float growth;              // 0.0 (bare) to 1.0 (fully grown)
  float growthRate;          // how fast this patch grows per frame
  float sugar;               // 0.0 to 1.0 — sweetness factor
  float nutrition;           // 0.0 to 1.0 — nutrition factor

  // Pre-computed blade offsets so they don't flicker
  float[] bladeX;
  float[] bladeLean;
  int maxBlades = 6;

  GrassTile(int gx, int gy, float cs) {
    gridX = gx;
    gridY = gy;
    cellSize = cs;
    x = gx * cs;
    y = gy * cs;

    // Randomize properties per cell
    growthRate = random(0.0005, 0.004);
    sugar = random(0.2, 1.0);
    nutrition = random(0.2, 1.0);

    // Start with random initial growth
    growth = random(0.2, 0.9);

    // Pre-compute blade positions
    bladeX = new float[maxBlades];
    bladeLean = new float[maxBlades];
    for (int i = 0; i < maxBlades; i++) {
      bladeX[i] = cellSize * 0.12 + i * (cellSize * 0.75 / maxBlades) + random(-1, 1);
      bladeLean[i] = random(-2.5, 2.5);
    }
  }

  void grow(float multiplier) {
    if (growth < 1.0) {
      growth += growthRate * multiplier;
      growth = constrain(growth, 0, 1);
    }
  }

  // Sheep eats this grass — returns how much was eaten
  float eat(float amount) {
    float eaten = min(amount, growth);
    growth -= eaten;
    growth = max(growth, 0);
    return eaten;
  }

  // Overall "attractiveness" to a sheep based on its needs
  float attractiveness(float hungerNeed, float sugarCraving) {
    if (growth < 0.15) return 0;  // too short to eat
    float foodValue = nutrition * hungerNeed + sugar * sugarCraving;
    return foodValue * growth;    // scale by how much grass is available
  }

  void display() {
    noStroke();

    // Base soil color — slight variation
    float soilR = 85 + gridX % 3 * 5;
    float soilG = 125 + gridY % 3 * 5;
    fill(soilR, soilG, 55);
    rect(x, y, cellSize, cellSize);

    if (growth > 0.05) {
      // Color based on properties:
      // High sugar = warm yellow-green, high nutrition = deep lush green
      float r = lerp(35, 110, sugar * 0.7);
      float g = lerp(130, 210, nutrition * 0.4 + growth * 0.4);
      float b = lerp(25, 55, growth * 0.4);

      fill(r, g, b);

      // Draw grass blades — more appear as growth increases
      int bladeCount = (int)(growth * maxBlades);
      bladeCount = max(bladeCount, 1);
      float bladeH = growth * cellSize * 0.55;

      for (int i = 0; i < bladeCount; i++) {
        float bx = x + bladeX[i];
        float by = y + cellSize - 1;

        // Each blade is a thin triangle
        triangle(
          bx - 1.2, by,
          bx + 1.2, by,
          bx + bladeLean[i], by - bladeH
        );
      }

      // Sugar-rich patches get subtle golden dots
      if (sugar > 0.65 && growth > 0.4) {
        fill(220, 195, 60, 50 + sugar * 40);
        float dotSize = 3 + sugar * 2;
        ellipse(x + cellSize * 0.5, y + cellSize * 0.6, dotSize, dotSize);
      }

      // Very nutritious patches get a darker rich base
      if (nutrition > 0.7 && growth > 0.5) {
        fill(30, 100, 30, 35);
        rect(x + 2, y + cellSize * 0.6, cellSize - 4, cellSize * 0.4 - 1);
      }
    }
  }
}
