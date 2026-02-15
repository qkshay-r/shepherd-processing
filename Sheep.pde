class Sheep {

  PVector pos;
  PVector vel;
  PVector acc;

  float maxSpeed = 2;
  float mass = 1.4;

  float neighborDist = 60;
  float fearRadius = 140;

  boolean grazing = false;
  float grazeTimer = 0;

  boolean inPen = false;

  float bodySize = 16;

  // Hunger & preference system
  float hunger = 0;           // 0 = full, 1 = starving
  float sugarCraving = 0;     // 0 = no craving, 1 = max craving
  float hungerRate;            // how fast this sheep gets hungry

  // Each sheep has a personality — some prefer sugar, some nutrition
  float sugarPreference;       // 0 = nutrition lover, 1 = sweet tooth

  GrassTile targetGrass = null;    // current grass patch being sought
  int searchCooldown = 0;

  Sheep(float x, float y) {
    pos = new PVector(x, y);
    vel = PVector.random2D();
    acc = new PVector();

    // Personality
    hungerRate = random(0.0004, 0.0015);
    sugarPreference = random(0, 1);
    hunger = random(0.1, 0.5);
    sugarCraving = random(0, 0.3);
  }

  void applyForce(PVector f) {
    PVector force = f.copy();
    force.div(mass);
    acc.add(force);
  }

  void update(GrassTile[][] grid, int cols, int rows, float cellSize) {

    checkPenStatus();

    // Clamp position to screen bounds
    pos.x = constrain(pos.x, 5, width - 5);
    pos.y = constrain(pos.y, 5, height - 5);

    // Hunger increases over time (not in pen — they're fed there)
    if (!inPen) {
      hunger += hungerRate;
      hunger = constrain(hunger, 0, 1);
    } else {
      hunger = max(hunger - 0.001, 0);  // slowly sated in pen
    }

    // Sugar craving fluctuates based on personality
    sugarCraving += (sugarPreference - 0.5) * 0.001;
    sugarCraving = constrain(sugarCraving, 0, 1);

    searchCooldown = max(0, searchCooldown - 1);

    // Decide whether to graze
    if (grazing) {
      vel.mult(0);
      grazeTimer--;

      // Try to eat the grass we're standing on
      int gx = constrain((int)(pos.x / cellSize), 0, cols - 1);
      int gy = constrain((int)(pos.y / cellSize), 0, rows - 1);
      GrassTile g = grid[gx][gy];

      if (g.growth > 0.1) {
        float eaten = g.eat(0.008);
        hunger -= eaten * (0.5 + g.nutrition * 0.5);
        sugarCraving -= eaten * g.sugar * 0.3;
        hunger = max(hunger, 0);
        sugarCraving = max(sugarCraving, 0);
      }

      if (grazeTimer <= 0 || hunger < 0.05) {
        grazing = false;
        targetGrass = null;
      }
    } else {
      // Seek grass when hungry enough (not in pen)
      if (hunger > 0.35 && !inPen) {
        seekGrass(grid, cols, rows, cellSize);
      }

      // Random wander when not actively seeking
      if (targetGrass == null) {
        PVector wander = PVector.random2D().mult(0.04);
        applyForce(wander);
      }

      // Start eating if on good grass and hungry (not in pen)
      if (!inPen) {
        int gx = constrain((int)(pos.x / cellSize), 0, cols - 1);
        int gy = constrain((int)(pos.y / cellSize), 0, rows - 1);
        GrassTile g = grid[gx][gy];

        if (hunger > 0.3 && g.growth > 0.3 && random(1) < 0.02) {
          grazing = true;
          grazeTimer = random(60, 180);
          vel.set(0, 0);
          targetGrass = null;
        }
      }
    }

    vel.add(acc);
    vel.limit(maxSpeed);
    pos.add(vel);
    acc.mult(0);
  }

  void seekGrass(GrassTile[][] grid, int cols, int rows, float cellSize) {
    if (searchCooldown > 0 && targetGrass != null) {
      // Move toward target grass
      PVector target = new PVector(
        targetGrass.x + cellSize/2,
        targetGrass.y + cellSize/2
      );
      PVector toGrass = PVector.sub(target, pos);
      float d = toGrass.mag();

      if (d < cellSize) {
        // Arrived — clear target so we can eat
        targetGrass = null;
        return;
      }

      toGrass.setMag(0.15);
      applyForce(toGrass);
      return;
    }

    // Search for best nearby grass
    float bestScore = 0;
    GrassTile bestGrass = null;
    int searchR = 5;  // search radius in grid cells

    int cx = constrain((int)(pos.x / cellSize), 0, cols - 1);
    int cy = constrain((int)(pos.y / cellSize), 0, rows - 1);

    for (int dx = -searchR; dx <= searchR; dx++) {
      for (int dy = -searchR; dy <= searchR; dy++) {
        int gx = cx + dx;
        int gy = cy + dy;
        if (gx < 0 || gx >= cols || gy < 0 || gy >= rows) continue;

        GrassTile g = grid[gx][gy];
        float score = g.attractiveness(hunger, sugarCraving);

        // Closer grass is preferred (slight distance penalty)
        float pixDist = dist(pos.x, pos.y, g.x + cellSize/2, g.y + cellSize/2);
        score *= 1.0 / (1.0 + pixDist * 0.005);

        if (score > bestScore) {
          bestScore = score;
          bestGrass = g;
        }
      }
    }

    if (bestGrass != null && bestScore > 0.05) {
      targetGrass = bestGrass;
      searchCooldown = 60;  // don't re-search for a bit
    }
  }

  void checkPenStatus() {
    float d = PVector.dist(pos, penCenter);
    if (d < penR/2) inPen = true;  // one-way: once in the pen, stays in
  }

  void boundary() {

    float margin = 50;
    PVector steer = new PVector();

    if (!inPen) {

      if (pos.x < margin) steer.add(new PVector(0.5, 0));
      if (pos.x > width - margin) steer.add(new PVector(-0.5, 0));
      if (pos.y < margin) steer.add(new PVector(0, 0.5));
      if (pos.y > height - margin) steer.add(new PVector(0, -0.5));

    } else {

      float d = PVector.dist(pos, penCenter);
      if (d > penR/2 - 20) {
        PVector toCenter = PVector.sub(penCenter, pos);
        toCenter.setMag(0.6);
        steer.add(toCenter);
      }
    }

    applyForce(steer);
  }

  void collide(ArrayList<Sheep> others) {

    for (Sheep other : others) {

      if (other == this) continue;

      float d = PVector.dist(pos, other.pos);
      float minDist = bodySize;

      if (d < minDist && d > 0) {
        PVector push = PVector.sub(pos, other.pos);
        push.normalize();
        push.mult(0.5);
        applyForce(push);
      }
    }
  }

  void flock(ArrayList<Sheep> sheepList) {

    PVector align = new PVector();
    PVector coh = new PVector();
    int count = 0;

    for (Sheep other : sheepList) {
      float d = PVector.dist(pos, other.pos);
      if (other != this && d < neighborDist) {
        align.add(other.vel);
        coh.add(other.pos);
        count++;
      }
    }

    if (count > 0) {
      align.div(count);
      align.mult(0.05);

      coh.div(count);
      coh.sub(pos);
      coh.mult(0.02);

      applyForce(align);
      applyForce(coh);
    }
  }

  void fleeDog(float dx, float dy, float fleeForce) {

    if (inPen) return;

    float d = dist(pos.x, pos.y, dx, dy);

    if (d < fearRadius) {
      PVector flee = PVector.sub(pos, new PVector(dx, dy));
      flee.normalize();
      flee.mult(fleeForce);
      applyForce(flee);

      // Dog scares sheep out of grazing
      if (grazing && d < fearRadius * 0.7) {
        grazing = false;
        targetGrass = null;
      }
    }
  }

  void display() {

    pushMatrix();
    translate(pos.x, pos.y);

    float heading = 0;
    if (vel.mag() > 0.1) heading = vel.heading();
    rotate(heading);

    noStroke();

    // Shadow
    fill(0, 25);
    ellipse(2, 4, 20, 10);

    // Legs (tiny stubs)
    fill(60);
    rect(-5, 4, 3, 5, 1);
    rect(3, 4, 3, 5, 1);

    // Body — hunger affects brightness
    float bodyBright = lerp(248, 195, hunger);
    fill(bodyBright);
    ellipse(0, 0, 20, 15);

    // Wool texture bumps
    fill(bodyBright - 10);
    ellipse(-3, -4, 7, 6);
    ellipse(3, -3, 6, 5);
    ellipse(-1, 3, 6, 5);

    // Head
    if (grazing) {
      // Head down when grazing
      fill(55);
      ellipse(9, 5, 10, 8);
      fill(30);
      ellipse(12, 6, 3, 3);
    } else {
      fill(55);
      ellipse(10, 0, 10, 8);
      // Eye
      fill(15);
      ellipse(12, -2, 2.5, 2.5);
    }

    popMatrix();

    // Indicators above sheep
    noStroke();
    if (grazing) {
      // Green dot = grazing
      fill(140, 255, 140, 180);
      ellipse(pos.x, pos.y - 15, 5, 5);
    } else if (hunger > 0.6) {
      // Red dot = hungry
      fill(255, 100, 100, 170);
      float indicatorSize = map(hunger, 0.6, 1.0, 3, 7);
      ellipse(pos.x, pos.y - 15, indicatorSize, indicatorSize);
    }
  }
}
