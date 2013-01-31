
part of pingpong;

void makeAbsolute(Element elem) {
  elem.style.position = 'absolute';
}

void makeRelative(Element elem) {
  elem.style.position = 'relative';
}

void setElementPosition(Element elem, int x, int y) {
  elem.style.left = "${x}px";
  elem.style.top = "${y}px";
}

void setElementSize(Element elem, int l, int t, int r, int b) {
  setElementPosition(elem, l, t);
  elem.style.right = "${r}px";
  elem.style.bottom = "${b}px";
}

class Racket {

  static const String PNG = "images/racket-black.png";
  static const int HEIGHT = 90;
  static const int WIDTH = 16;
  static const int MARGIN = 4;

  Game game;
  Element root;
  ImageElement image;
  num x,y;
  num dy = 0.0;

  Racket(Game aGame, num xpos) {
    game = aGame;
    root = new DivElement();
    makeAbsolute(root);
    x = xpos;
    y = 0.5;
    update();

    image = new ImageElement(src: PNG);
    root.nodes.add(image);
  }

  int xposLeft() {
    var pos = ((x * game.fieldWidth) - (WIDTH * 0.5)).toInt();
    if (pos < 0) {
      pos = 0;
    } else if (pos + WIDTH > game.fieldWidth) {
      pos = game.fieldWidth - WIDTH;
    }
    return pos;
  }

  int yposTop() {
    var pos = ((y * game.fieldHeight) - (HEIGHT * 0.5)).toInt();
    if (pos < MARGIN) {
      pos = MARGIN;
    } else if (pos + HEIGHT + MARGIN > game.fieldHeight) {
      pos = game.fieldHeight - HEIGHT - MARGIN;
    }
    return pos;
  }

  void update() {
    setElementPosition(root, xposLeft(), yposTop());
  }

  bool atXPos(num ballX) {
    return (ballX - game.ballWidth/2) <= (x + game.racketWidth/2) &&
        (ballX - game.ballWidth/2) >= (x - game.racketWidth/2);
  }

  bool atYPos(num ballY) {
    return (ballY >= (y - game.racketHeight/2) && ballY <= (y + game.racketHeight/2));
  }

  directionUp() {
    dy  = -0.01;
  }

  directionstop() {
    dy = 0.0;
  }

  directionDown() {
    dy = 0.01;
  }

  moveTo(num newYpos) {
    y = newYpos / game.fieldHeight;
    y = max(y, game.racketHeight/2);
    y = min(y, 1.0 - game.racketHeight/2);
    update();
  }

  move() {
    if (dy > 0 && (y + game.racketHeight/2) < 1.0) {
      y = y + dy;
    } else if (dy < 0 && (y - game.racketHeight/2) > 0.0) {
      y = y + dy;
    }
    if (dy != 0) {
      update();
    }
  }

  tick(num timeDiff) {
     move();
  }
}

class Ball {

  static const String PNG = "images/ball-265897.png";
  static const int HEIGHT = 14;
  static const int WIDTH = 14;

  static const String BOUNCE_SOUND = "sounds/ball-bounce";
  static const String LOST_SOUND = "sounds/ball-lost";
  static const String RACKET_SOUND = "sounds/ball-racket";

  Game game;
  Racket racket;
  Element root;
  ImageElement image;
  num x,y;
  num dx, dy;
  bool lost = false;

  Ball(Game aGame, Racket aRacket) {
    game = aGame;
    racket = aRacket;
    root = new DivElement();
    makeAbsolute(root);
    x = 0.4 + (random.nextDouble() * 0.2);
    y = 0.2 + (random.nextDouble() * 0.4);
    dx = (0.3 + (random.nextDouble() * 0.1)) / 1000.0;
    dy = (0.3 + (random.nextDouble() * 0.1)) / 1000.0;
    if (random.nextBool()) {
      dy = dy * -1.0;
    }
    update();

    image = new ImageElement(src: PNG);
    root.nodes.add(image);
  }

  void update() {
    setElementPosition(root, xposLeft(), yposTop());
  }

  int xposLeft() {
    var xpos = ((x * game.fieldWidth) - (WIDTH * 0.5)).toInt();
    if (xpos < 0) {
      xpos = 0;
    } else if (xpos + WIDTH > game.fieldWidth) {
      xpos = game.fieldWidth - WIDTH;
    }
    return xpos;
  }

  int xposRight() {
    return xposLeft() + WIDTH;
  }

  int yposTop() {
    var ypos = ((y * game.fieldHeight) - (HEIGHT * 0.5)).toInt();
    if (ypos < 0) {
      ypos = 0;
    } else if (ypos + HEIGHT > game.fieldHeight) {
      ypos = game.fieldHeight - HEIGHT;
    }
    return ypos;
  }

  int yposBottom() {
    return yposTop() + HEIGHT;
  }

  void move(num timeDiff) {
    y = y + dy*timeDiff;
    if (y + (game.ballHeight/2) >= 1.0) {
      y = 2.0 - y; dy = dy * -1;
      game.playSound(BOUNCE_SOUND);
    } else if (y - (game.ballHeight/2) <= 0) {
      y = y * -1; dy = dy * -1;
      game.playSound(BOUNCE_SOUND);
    }
    x = x + dx*timeDiff;
    if (x > game.otherRacket.x) {
      x = 2.0 * game.otherRacket.x- x; dx = dx * -1;
      game.playSound(BOUNCE_SOUND);
    } else {
      if (racket.atXPos(x) && (dx < 0.0 && racket.atYPos(y))) {
        x = (racket.x + game.racketWidth) + (x - (racket.x + game.racketWidth)); dx = dx * -1;
        game.playSound(RACKET_SOUND);
      } else {
        if (x - (game.ballWidth/2) <= 0.0) {
          lost = true;
          game.playSound(LOST_SOUND);
        }
      }
    }
    update();
  }

  void tick(num timeDiff) {
     move(timeDiff);
  }
}