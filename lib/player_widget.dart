import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocalize_it/text_to_speech.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';

enum PlayerState { stopped, playing, paused }
enum PlayingRouteState { speakers, earpiece }

class PlayerWidget extends StatefulWidget {
  final String text;
  final PlayerMode mode;
  final int index;
  final String fileName;

  PlayerWidget(
      {Key key,
      @required this.text,
      this.mode = PlayerMode.MEDIA_PLAYER,
      @required this.index,
      @required this.fileName})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState();
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  String status = 'hidden';
  int counter = 0;

  AudioPlayer _audioPlayer;
  // ignore: unused_field
  AudioPlayerState _audioPlayerState;
  Duration _duration;
  Duration _position;

  PlayerState _playerState = PlayerState.stopped;
  PlayingRouteState _playingRouteState = PlayingRouteState.speakers;
  StreamSubscription _durationSubscription;
  StreamSubscription _positionSubscription;
  StreamSubscription _playerCompleteSubscription;
  StreamSubscription _playerErrorSubscription;
  StreamSubscription _playerStateSubscription;

  get _isPlaying => _playerState == PlayerState.playing;

  get _isPaused => _playerState == PlayerState.paused;

  get _durationText => _duration?.toString()?.split('.')?.first ?? '';

  get _positionText => _position?.toString()?.split('.')?.first ?? '';

  get _isPlayingThroughEarpiece =>
      _playingRouteState == PlayingRouteState.earpiece;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    MediaNotification.setListener('pause', () {
      setState(() {
        status = 'pause';
        _pause();
      });
    });
    MediaNotification.setListener('play', () {
      setState(() {
        status = 'play';
        _play();
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool show = true;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Stack(
          children: <Widget>[
            SizedBox(
              height: 60.0,
              width: 60.0,
              child: CircularProgressIndicator(
                backgroundColor: Colors.black,
                strokeWidth: 4.0,
                valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
                value: (_position != null &&
                        _duration != null &&
                        _position.inMilliseconds > 0 &&
                        _position.inMilliseconds < _duration.inMilliseconds)
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0.0,
              ),
            ),
            IconButton(
                icon: _isPlaying
                    ? Icon(
                        Icons.pause,
                        color: Colors.black,
                        size: 40.0,
                      )
                    : Icon(
                        Icons.play_arrow,
                        color: Colors.black,
                        size: 40.0,
                      ),
                onPressed: () {
                  if (show) {
                    !_isPlaying
                        ? MediaNotification.showNotification(
                            title: widget.fileName, author: '')
                        : MediaNotification.showNotification(
                            title: widget.fileName,
                            author: '',
                            isPlaying: false);
                  }
                  if (!_isPlaying && show && counter == 0) {
                    counter += 1;
                    showModalBottomSheet(
                        elevation: 10.0,
                        context: context,
                        builder: (context) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 60.0),
                            child: Text(
                              "Please Press Stop before picking another file.",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        });
                    show = false;
                  }
                  _isPlaying ? _pause() : _play();
                }),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
        ),
        Stack(
          children: <Widget>[
            SizedBox(
              height: 60.0,
              width: 60.0,
              child: CircularProgressIndicator(
                backgroundColor: Colors.black,
                strokeWidth: 4.0,
                valueColor: AlwaysStoppedAnimation(Colors.black),
                value: 1.0,
              ),
            ),
            IconButton(
                icon: Icon(
                  Icons.stop,
                  color: Colors.black,
                  size: 40.0,
                ),
                onPressed: () {
                  MediaNotification.hideNotification();
                  stop();
                }),
          ],
        )
      ],
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer(mode: widget.mode);

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription =
        _audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
              _position = p;
            }));

    _playerCompleteSubscription =
        _audioPlayer.onPlayerCompletion.listen((event) {
      _onComplete();
      setState(() {
        _position = _duration;
      });
    });

    _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _audioPlayerState = state;
      });
    });

    _audioPlayer.onNotificationPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _audioPlayerState = state);
    });
    _playingRouteState = PlayingRouteState.speakers;
  }

  Future<int> _play() async {
    var response = await voiceResponse(widget.text, widget.index);
    var jsonData = jsonDecode(response.body);
    String audioBase64 = jsonData['audioContent'];
    Uint8List bytes = base64Decode(audioBase64);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = File(
        "$dir/" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp3");
    await file.writeAsBytes(bytes);

    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    final result = await _audioPlayer.play(file.path,
        isLocal: true, position: playPosition);
    if (result == 1)
      setState(() {
        _playerState = PlayerState.playing;
      });
    return result;
  }

  Future<int> _pause() async {
    final result = await _audioPlayer.pause();
    if (result == 1)
      setState(() {
        _playerState = PlayerState.paused;
      });
    return result;
  }

  Future<int> stop() async {
    counter = 0;
    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration();
      });
    }
    return result;
  }

  void _onComplete() {
    setState(() {
      _playerState = PlayerState.stopped;
      counter = 0;
      MediaNotification.hideNotification();
    });
  }
}
