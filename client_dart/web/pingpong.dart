library pingpong;

import 'dart:html';
import 'dart:json';
import 'dart:math';
import 'dart:web_audio';
//import 'firespark';

part 'moving_parts.dart';
part 'audio.dart';

WebSocket ws;
String myIdentification;
Random random;
Game theGame;

void main() {

  random = new Random();
  theGame = new Game();

  myIdentification = new Date.now().millisecondsSinceEpoch.toString();
  initWebSocket();
}

class Game {

  static const String START_SOUND = "sounds/ball-lost";

  Element field;
  int fieldHeight;
  int fieldWidth;

  Racket myRacket, otherRacket;
  num racketHeight, racketWidth;

  List<Ball> balls;
  num ballHeight, ballWidth;
  bool lost;

  GameAudio gameAudio;

  num lastTime;       // the last time that tick() method was called
  num lastCommTime;   // the last time that we send a message to the server

  Game() {
    field = query("#canvas-content");
    fieldHeight = field.clientHeight;
    fieldWidth = field.clientWidth;
    calculatieRacketAndBallSizes();

    balls = new List();
    createRackets();

    try {
      // not supported in all browsers yet
      gameAudio = new GameAudio([ Ball.BOUNCE_SOUND, Ball.LOST_SOUND, Ball.RACKET_SOUND ]);
      gameAudio.load();
    } catch (e) {
      gameAudio = null;
    }

    query('#buttonStart').on.click.add(start);
    query('#buttonBall').on.click.add(createBall);

    window.on.keyDown.add(onKeyboardEvent, false);
    window.on.resize.add(onWindowsResizeEvent, false);
    field.on.touchMove.add(onTouchMove, false);
  }

  void createRackets() {
    myRacket = new Racket(this, 0.1);
    field.nodes.add(myRacket.root);
    otherRacket = new Racket(this, 0.9);
    field.nodes.add(otherRacket.root);
  }

  void createBall(Event ev) {
    Ball newBall = new Ball(this, myRacket);
    balls.add(newBall);
    field.nodes.add(newBall.root);
  }

  void moveUp(Event event) {
    myRacket.directionUp();
  }

  void moveDown(Event event) {
    myRacket.directionDown();
  }

  void stop(Event event) {
    myRacket.directionstop();
  }

  void onKeyboardEvent(KeyboardEvent e) {
    switch(e.keyCode) {
      case 38:
        moveUp(null);
        break;
      case 40:
        moveDown(null);
        break;
      case 37:
      case 39:
        stop(null);
        break;
    }
  }

  void calculatieRacketAndBallSizes() {
    racketHeight = Racket.HEIGHT / fieldHeight;
    racketWidth = Racket.WIDTH / fieldWidth;
    ballHeight = Ball.HEIGHT / fieldHeight;
    ballWidth = Ball.WIDTH / fieldWidth;
  }

  void onWindowsResizeEvent(Event e) {
    fieldHeight = field.clientHeight;
    fieldWidth = field.clientWidth;
    calculatieRacketAndBallSizes();
    myRacket.update();
    otherRacket.update();
    balls.forEach((ball) => ball.update());
  }

  void onTouchMove(TouchEvent event) {
    myRacket.moveTo(event.touches[0].clientY - field.clientTop);
    event.preventDefault();
  }

  void start(Event event) {
    startGame(true);
  }
  
  void startGame(bool hasService) {
    if (hasService) {
      createBall(null);
    }
    lastTime = null;
    lost = false;
    window.requestAnimationFrame(tick);
    playSound(START_SOUND);
    ButtonElement button = query('#buttonStart');
    button.disabled = true;
    query('#gameMsg').text = "Playing ...";
  }
  
  void stopGame() {
    balls.clear();
    query('#gameMsg').text = "You Win !!!";
  }

  void updateServer() {
    if (lost) {
      sendCommand("Lost", null);
    } else {
      var now = new Date.now().millisecondsSinceEpoch;
      if (lastCommTime == null || (now - lastCommTime > 100)) {
        lastCommTime = now;
        var theBall = balls[0];
        sendCommand("MoveRacket", { 
          'myRacket' : myRacket.y,
          'ballX' : theBall.x,
          'ballY' : theBall.y,
          'dx' : theBall.dx,
          'dy' : theBall.dy
        });
      }
    }
  }

  void tick(num time) {
    var timeDiff = (lastTime == null ? 21.0 : time - lastTime);
    myRacket.tick(timeDiff);
    if (!balls.isEmpty) {
      balls.forEach((ball) => ball.tick(timeDiff));
      balls.where((ball) => ball.lost).forEach((ball) => removeBall(ball));
      if (balls.isEmpty) {
        lost = true;
        query('#gameMsg').text = "You Loose !!!";
        ButtonElement button = query('#buttonStart');
        button.disabled = false;
      }
    } 
    if (!lost) {
      lastTime = time;
      window.requestAnimationFrame(tick);
    }
    updateServer();
  }

  void removeBall(Ball aBall) {
    balls.removeAt(balls.indexOf(aBall));
    field.nodes.removeAt(field.nodes.indexOf(aBall.root));
  }

  void playSound(String name) {
    if (gameAudio != null) {
      gameAudio.playSound(name);
    }
  }
}

void updateWsStatus(String statusText) {
  query('#wsStatus').text = statusText;
}

void initWebSocket([int retrySeconds = 2]) {
  bool encounteredError = false;

  var hostPort = "${window.location.hostname}:${window.location.port}";
  if (window.location.port == '3030') { // local debug mode
    hostPort = 'localhost:8181';
  }
  updateWsStatus("connecting to ${hostPort} ...");
  ws = new WebSocket("ws://${hostPort}/firespark");
  ws.on.open.add((e) {
    updateWsStatus('Connected');
    sendCommand("PlayerJoin", null);
  });

  ws.on.close.add((e) {
    updateWsStatus('Closed, retrying in ${retrySeconds}s');
    if (!encounteredError) {
      window.setTimeout(() => initWebSocket(retrySeconds*2), 1000*retrySeconds);
    }
    encounteredError = true;
  });

  ws.on.error.add((e) {
    updateWsStatus('Error, retrying in ${retrySeconds}s');
    if (!encounteredError) {
      window.setTimeout(() => initWebSocket(retrySeconds*2), 1000*retrySeconds);
    }
    encounteredError = true;
  });

  ws.on.message.add((MessageEvent e) {
    handleReceivedCommand(e.data);
  });
}

void sendCommand(String anAction, parameters) {
  if (ws != null && ws.readyState == WebSocket.OPEN) {
    ws.send(stringify({
      'Timestamp' : new Date.now().millisecondsSinceEpoch,
      'Action': anAction,
      'Source' : myIdentification,
      'Parameter' : parameters }));
  }
}

void handleReceivedCommand(String command) {
  Map parsedCommand = parse(command);
  if (parsedCommand["Action"] == 'MoveRacket') {
    theGame.otherRacket.y = parsedCommand["Parameter"]["myRacket"];
    theGame.otherRacket.update();
  } else if (parsedCommand["Action"] == "GameStart") {
    theGame.start(null);  
  } else if (parsedCommand["Action"] == "Lost") {
    theGame.stopGame();
  }
}