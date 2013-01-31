part of pingpong;

class GameAudio {

  AudioContext audioCtx;

  Map<String, AudioBuffer> buffers = new Map();

  List<String> urlList;

  GameAudio(this.urlList) {
    audioCtx = new AudioContext();
  }

  void load() {
    for (var i = 0; i < urlList.length; i++) {
      _loadBuffer(urlList[i], i);
    }
  }

  void _loadBuffer(String url, int index) {
    // Load the buffer asynchronously.
    var request = new HttpRequest();
    request.open("GET", "${url}.ogg", true);
    request.responseType = "arraybuffer";
    request.on.load.add((e) => _onLoad(request, url, index));

    // Don't use alert in real life ;)
    request.on.error.add((e) => window.alert("BufferLoader: XHR error"));

    request.send();
  }

  void _onLoad(HttpRequest request, String url, int index) {
    // Asynchronously decode the audio file data in request.response.
    audioCtx.decodeAudioData(request.response, (AudioBuffer buffer) {
      if (buffer == null) {
        // Don't use alert in real life ;)
        window.alert("Error decoding file data: $url");
        return;
      }
      buffers[url] = buffer;
    });
  }

  void playSound(String name) {
    var buffer = buffers[name];
    if (buffer != null) {
      AudioBufferSourceNode source = audioCtx.createBufferSource();
      source.buffer = buffer;
      source.connect(audioCtx.destination, 0, 0);
      source.start(0);
    }
  }

}