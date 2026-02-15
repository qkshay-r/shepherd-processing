// ─── Individual Slider ─────────────────────────────────────
class Slider {
  String label;
  float minVal, maxVal, value, defaultVal;
  float x, y, w, h;
  boolean dragging = false;

  Slider(String label, float minVal, float maxVal, float defaultVal) {
    this.label = label;
    this.minVal = minVal;
    this.maxVal = maxVal;
    this.value = defaultVal;
    this.defaultVal = defaultVal;
    this.w = 200;
    this.h = 6;
  }

  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void display() {
    // Label + value
    fill(210);
    textSize(11);
    textAlign(LEFT, BOTTOM);
    text(label, x, y - 4);

    textAlign(RIGHT, BOTTOM);
    // Show integer for values >= 5, one decimal otherwise
    if (maxVal >= 10 && value == (int)value || maxVal >= 10) {
      text(nf(value, 0, (maxVal < 10) ? 2 : 1), x + w, y - 4);
    } else {
      text(nf(value, 0, 2), x + w, y - 4);
    }

    // Track background
    noStroke();
    fill(60, 70, 80);
    rect(x, y, w, h, 3);

    // Filled portion
    float ratio = (value - minVal) / (maxVal - minVal);
    fill(90, 190, 130);
    rect(x, y, w * ratio, h, 3);

    // Thumb
    float thumbX = x + w * ratio;
    float thumbY = y + h / 2;
    stroke(255, 200);
    strokeWeight(1.5);
    fill(dragging ? color(130, 220, 160) : color(240));
    ellipse(thumbX, thumbY, 14, 14);
    noStroke();
  }

  boolean isOver(float mx, float my) {
    float ratio = (value - minVal) / (maxVal - minVal);
    float thumbX = x + w * ratio;
    float thumbY = y + h / 2;
    return dist(mx, my, thumbX, thumbY) < 14;
  }

  boolean isOnTrack(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y - 10 && my <= y + h + 10;
  }

  void press(float mx, float my) {
    if (isOver(mx, my) || isOnTrack(mx, my)) {
      dragging = true;
      updateValue(mx);
    }
  }

  void drag(float mx) {
    if (dragging) {
      updateValue(mx);
    }
  }

  void release() {
    dragging = false;
  }

  void updateValue(float mx) {
    float ratio = constrain((mx - x) / w, 0, 1);
    value = lerp(minVal, maxVal, ratio);
  }

  void reset() {
    value = defaultVal;
  }
}


// ─── Slider Menu Panel ─────────────────────────────────────
class SliderMenu {

  boolean menuOpen = false;
  float panelW = 280;
  float panelX;        // animated x position
  float targetX;
  float openX, closedX;

  float buttonSize = 36;
  float buttonX, buttonY;

  // Scroll
  float scrollY = 0;
  float maxScroll = 0;

  // Category labels + sliders
  String[] categories = { "SHEEP", "GRASS", "PEN", "DOG" };
  int[] categoryStart = new int[4];  // index of first slider in each category

  Slider[] sliders;

  // Reset button
  float resetBtnX, resetBtnY, resetBtnW, resetBtnH;
  boolean resetHover = false;

  SliderMenu() {
    closedX = width;
    openX = width - panelW;
    panelX = closedX;
    targetX = closedX;

    buttonX = width - buttonSize - 10;
    buttonY = 14;

    // ── Create sliders ──
    sliders = new Slider[8];

    // Sheep
    categoryStart[0] = 0;
    sliders[0] = new Slider("Number of Sheep", 5, 80, totalSheep);
    sliders[1] = new Slider("Max Speed", 0.5, 6, 2);
    sliders[2] = new Slider("Fear Radius", 50, 300, 140);
    sliders[3] = new Slider("Flocking Distance", 20, 150, 60);

    // Grass
    categoryStart[1] = 4;
    sliders[4] = new Slider("Growth Rate ×", 0.1, 5.0, 1.0);
    sliders[5] = new Slider("Cell Size", 10, 50, 25);

    // Pen
    categoryStart[2] = 6;
    sliders[6] = new Slider("Pen Radius", 100, 500, 300);

    // Dog
    categoryStart[3] = 7;
    sliders[7] = new Slider("Flee Force", 0.1, 2.0, 0.7);

    resetBtnW = 160;
    resetBtnH = 32;
  }

  // ── Layout helpers ──
  void layoutSliders() {
    float yOff = buttonY + buttonSize + 20 + scrollY;
    float xPad = panelX + 20;
    int sliderIdx = 0;

    for (int c = 0; c < categories.length; c++) {
      // Category label height
      yOff += 22;

      int nextCat = (c + 1 < categories.length) ? categoryStart[c + 1] : sliders.length;
      for (int i = categoryStart[c]; i < nextCat; i++) {
        sliders[i].setPosition(xPad, yOff + 16);
        yOff += 48;
      }
      yOff += 8; // gap between categories
    }

    // Reset button
    resetBtnX = panelX + (panelW - resetBtnW) / 2;
    resetBtnY = yOff + 10;

    maxScroll = max(0, (resetBtnY + resetBtnH + 20) - height);
  }

  // ── Update & Draw ──
  void update() {
    // Smooth animation
    panelX = lerp(panelX, targetX, 0.18);

    // Update toggle button position to follow panel
    buttonX = panelX - buttonSize - 10;
    if (!menuOpen) {
      buttonX = width - buttonSize - 10;
    }

    layoutSliders();
  }

  void display() {
    // Always draw the gear button, even when panel is hidden
    drawGearButton();

    if (abs(panelX - closedX) < 1 && !menuOpen) return;  // fully hidden

    // ── Panel background ──
    noStroke();
    fill(20, 24, 30, 220);
    rect(panelX, 0, panelW, height);

    // Subtle left border
    stroke(90, 190, 130, 100);
    strokeWeight(1);
    line(panelX, 0, panelX, height);
    noStroke();

    // ── Title ──
    fill(255);
    textSize(16);
    textAlign(LEFT, TOP);
    text("SETTINGS", panelX + 20, buttonY + buttonSize + scrollY + 2);

    // ── Draw sliders with category labels ──
    float yOff = buttonY + buttonSize + 20 + scrollY;
    for (int c = 0; c < categories.length; c++) {
      // Category header
      fill(90, 190, 130);
      textSize(10);
      textAlign(LEFT, TOP);
      text("── " + categories[c] + " ──", panelX + 20, yOff + 4);
      yOff += 22;

      int nextCat = (c + 1 < categories.length) ? categoryStart[c + 1] : sliders.length;
      for (int i = categoryStart[c]; i < nextCat; i++) {
        sliders[i].display();
        yOff += 48;
      }
      yOff += 8;
    }

    // ── Reset button ──
    resetHover = mouseX >= resetBtnX && mouseX <= resetBtnX + resetBtnW
              && mouseY >= resetBtnY && mouseY <= resetBtnY + resetBtnH;
    fill(resetHover ? color(200, 70, 70) : color(140, 50, 50));
    rect(resetBtnX, resetBtnY, resetBtnW, resetBtnH, 6);
    fill(255);
    textSize(13);
    textAlign(CENTER, CENTER);
    text("Reset to Defaults", resetBtnX + resetBtnW / 2, resetBtnY + resetBtnH / 2);

    // ── Toggle button (gear) ──
    drawGearButton();
  }

  void drawGearButton() {
    float cx = menuOpen ? panelX - buttonSize / 2 - 10 : width - buttonSize / 2 - 10;
    float cy = buttonY + buttonSize / 2;
    buttonX = cx - buttonSize / 2;

    // Button background
    noStroke();
    fill(menuOpen ? color(90, 190, 130) : color(50, 55, 65, 200));
    ellipse(cx, cy, buttonSize, buttonSize);

    // Gear icon
    pushMatrix();
    translate(cx, cy);
    if (menuOpen) rotate(frameCount * 0.02);  // subtle spin when open

    stroke(255);
    strokeWeight(1.5);
    noFill();
    ellipse(0, 0, 10, 10);

    for (int i = 0; i < 6; i++) {
      float a = radians(i * 60);
      float ix = cos(a) * 6;
      float iy = sin(a) * 6;
      float ox = cos(a) * 11;
      float oy = sin(a) * 11;
      line(ix, iy, ox, oy);
    }
    noStroke();
    popMatrix();
  }

  // ── Interaction ──
  boolean mousePressed(float mx, float my) {
    // Toggle button
    float cx = menuOpen ? panelX - buttonSize / 2 - 10 : width - buttonSize / 2 - 10;
    float cy = buttonY + buttonSize / 2;
    if (dist(mx, my, cx, cy) < buttonSize / 2) {
      menuOpen = !menuOpen;
      targetX = menuOpen ? openX : closedX;
      return true;
    }

    if (!menuOpen) return false;

    // Inside panel?
    if (mx < panelX) return false;

    // Reset button
    if (mx >= resetBtnX && mx <= resetBtnX + resetBtnW
     && my >= resetBtnY && my <= resetBtnY + resetBtnH) {
      resetAll();
      return true;
    }

    // Sliders
    for (Slider s : sliders) {
      s.press(mx, my);
      if (s.dragging) return true;
    }

    return true;  // consumed because inside panel
  }

  boolean mouseDragged(float mx, float my) {
    if (!menuOpen) return false;
    for (Slider s : sliders) {
      if (s.dragging) {
        s.drag(mx);
        return true;
      }
    }
    return false;
  }

  boolean mouseReleased() {
    for (Slider s : sliders) {
      s.release();
    }
    return false;
  }

  void mouseScrolled(float delta) {
    if (!menuOpen) return;
    if (mouseX < panelX) return;
    scrollY -= delta * 20;
    scrollY = constrain(scrollY, -maxScroll, 0);
  }

  void resetAll() {
    for (Slider s : sliders) {
      s.reset();
    }
  }

  // ── Getters for each variable ──
  int getSheepCount()       { return round(sliders[0].value); }
  float getMaxSpeed()       { return sliders[1].value; }
  float getFearRadius()     { return sliders[2].value; }
  float getNeighborDist()   { return sliders[3].value; }
  float getGrowthMult()     { return sliders[4].value; }
  float getCellSize()       { return sliders[5].value; }
  float getPenRadius()      { return sliders[6].value; }
  float getFleeForce()      { return sliders[7].value; }

  boolean isConsuming() {
    if (!menuOpen) return false;
    return mouseX >= panelX;
  }
}
