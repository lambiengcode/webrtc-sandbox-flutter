import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as RTC;
import 'package:get_boilerplate/src/pages/call/call_screen.dart';
import 'package:get_boilerplate/src/services/socket_emit.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:socket_io_client/socket_io_client.dart';

const int MY_ID = 12022000;
Socket socket;

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer _timmerInstance;
  int _start = 0;
  String _timmer = '';
  bool _offer = false;
  String _sdpReceiveCalling = '';

  //VideoCallVariables
  RTC.RTCPeerConnection _peerConnection;
  RTC.MediaStream _localStream;
  RTC.RTCVideoRenderer _localRenderer = RTC.RTCVideoRenderer();
  RTC.RTCVideoRenderer _remoteRenderer = RTC.RTCVideoRenderer();
  bool isFrontCamera = true;

  void switchCamera() async {
    if (_localStream != null) {
      bool value = await _localStream.getVideoTracks()[0].switchCamera();
      while (value == this.isFrontCamera)
        value = await _localStream.getVideoTracks()[0].switchCamera();
      this.isFrontCamera = value;
    }
  }

  void startTimmer() {
    var oneSec = Duration(seconds: 1);
    _timmerInstance = Timer.periodic(
        oneSec,
        (Timer timer) => setState(() {
              if (_start < 0) {
                _timmerInstance.cancel();
              } else {
                _start = _start + 1;
                _timmer = getTimerTime(_start);
              }
            }));
  }

  String getTimerTime(int start) {
    int minutes = (start ~/ 60);
    String sMinute = '';
    if (minutes.toString().length == 1) {
      sMinute = '0' + minutes.toString();
    } else
      sMinute = minutes.toString();

    int seconds = (start % 60);
    String sSeconds = '';
    if (seconds.toString().length == 1) {
      sSeconds = '0' + seconds.toString();
    } else
      sSeconds = seconds.toString();

    return sMinute + ':' + sSeconds;
  }

  @override
  void initState() {
    super.initState();
    initRenderers();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });
    startTimmer();
    connectAndListen();
  }

  @override
  void dispose() {
    _peerConnection.close();
    _localStream.dispose();
    _localRenderer.dispose();
    _timmerInstance.cancel();
    super.dispose();
  }

  void connectAndListen() async {
    var urlConnectSocket = 'http://192.168.1.8:3000';
    socket =
        io(urlConnectSocket, OptionBuilder().enableForceNew().setTransports(['websocket']).build());
    socket.connect();
    socket.onConnect((_) {
      print('connected');

      SocketEmit().joinCall(MY_ID);

      socket.on('call', (data) {
        if (data['message'] != null) {
          var message = jsonDecode(data['message']);
          var sender = data['sender'];
          if (sender != MY_ID) {
            var ice = message['ice'];
            if (ice != null) {
              // Opponent accept my call
              _addCandidate(ice);
            } else if (message["sdp"]["type"] == "offer") {
              // _createPeerConnection().then((pc) {
              //   _peerConnection = pc;
              //   _setRemoteDescription(message["sdp"]["sdp"]);
              // });
              setState(() {
                _sdpReceiveCalling = message['sdp']['sdp'];
              });
            } else if (message["sdp"]["type"] == "answer") {
              // Opponent accept my call
              _setRemoteDescription(message["sdp"]["sdp"]);
            }
          }
        }
      });
    });

    socket.onDisconnect((_) => print('disconnect'));
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _createOffer() async {
    RTC.RTCSessionDescription description = await _peerConnection.createOffer({
      'offerToReceiveVideo': 1,
      'offerToReceiveAudio': 1,
    });
    var session = parse(description.sdp.toString());
    String sdp = write(session, null);
    await sendSdp(sdp, "offer");
    _offer = true;

    _peerConnection.setLocalDescription(description);
  }

  void _createAnswer() async {
    RTC.RTCSessionDescription description = await _peerConnection.createAnswer({
      'offerToReceiveVideo': 1,
      'offerToReceiveAudio': 1,
    });

    var session = parse(description.sdp);
    String sdp = write(session, null);
    await sendSdp(sdp, "answer");

    _peerConnection.setLocalDescription(description);

    _peerConnection.onIceCandidate = (event) => {
          sendCandidates(event.candidate.toString(), event.sdpMid.toString(), event.sdpMlineIndex),
        };
  }

  void _setRemoteDescription(sdp) async {
    RTC.RTCSessionDescription description =
        new RTC.RTCSessionDescription(sdp, (_offer ? 'answer' : 'offer'));
    await _peerConnection.setRemoteDescription(description);
    if (_offer) {
    } else {
      _createAnswer();
    }
  }

  _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTC.RTCPeerConnection pc = await RTC.createPeerConnection(configuration, offerSdpConstraints);
    // if (pc != null) print(pc);
    pc.addStream(_localStream);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        sendCandidates(
          e.candidate.toString(),
          e.sdpMid.toString(),
          e.sdpMlineIndex,
        );
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteRenderer.srcObject = stream;
    };

    return pc;
  }

  Future sendCandidates(
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) async {
    String jsonString =
        '{"ice":{"candidate":${jsonEncode(candidate)},"sdpMid":"$sdpMid","sdpMlineIndex":"$sdpMLineIndex"}}';
    SocketEmit().sendMessage(MY_ID, jsonString);
  }

  Future sendSdp(
    String sdp,
    String type,
  ) async {
    String jsonString = '{"sdp":{"type":"$type","sdp":${jsonEncode(sdp)}}}';
    SocketEmit().sendMessage(MY_ID, jsonString);
  }

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };

    RTC.MediaStream stream = await RTC.navigator.getUserMedia(mediaConstraints);

    // _localStream = stream;
    _localRenderer.srcObject = stream;

    // _peerConnection.addStream(stream);

    return stream;
  }

  Future<void> _addCandidate(dynamic session) async {
    if (session['candidate'] != null) {
      RTC.RTCIceCandidate candidate = new RTC.RTCIceCandidate(
        session['candidate'].toString().replaceAll('candidate:', ''),
        "audio",
        0,
      );
      await _peerConnection.addCandidate(candidate);
    }
  }

  endCall() {
    _peerConnection.close();
    _localStream.dispose();
    _localRenderer.dispose();
    _timmerInstance.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              children: [
                Container(
                  width: size.width,
                  height: size.height - size.width * .15,
                  child: Column(
                    children: [
                      Expanded(
                        child: _remoteRenderer.textureId == null
                            ? Container()
                            : FittedBox(
                                fit: BoxFit.cover,
                                child: new Center(
                                  child: new SizedBox(
                                    width: size.height * 1.34,
                                    height: size.height,
                                    child: new Transform(
                                      transform: Matrix4.identity()..rotateY(0.0),
                                      alignment: FractionalOffset.center,
                                      child: new Texture(textureId: _remoteRenderer.textureId),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      Expanded(
                        child: _sdpReceiveCalling.length == 0
                            ? Container()
                            : CallPage(
                                info: _sdpReceiveCalling,
                                localStream: _localStream,
                                localRenderer: _localRenderer,
                              ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 40.0,
                  left: 15.0,
                  child: Column(
                    children: [
                      Text(
                        _timmer,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width / 26.5,
                        ),
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                      Container(
                        height: size.width * .54,
                        width: size.width * .32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(6.0)),
                          border: Border.all(color: Colors.blueAccent, width: 2.0),
                        ),
                        child: _localRenderer.textureId == null
                            ? Container()
                            : SizedBox(
                                width: size.height,
                                height: size.height,
                                child: new Transform(
                                  transform: Matrix4.identity()
                                    ..rotateY(
                                      isFrontCamera ? -pi : 0.0,
                                    ),
                                  alignment: FractionalOffset.center,
                                  child: new Texture(textureId: _localRenderer.textureId),
                                ),
                              ),
                      ),
                      SizedBox(
                        height: 12.0,
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                      GestureDetector(
                        onTap: () => switchCamera(),
                        child: Container(
                          height: size.width * .125,
                          width: size.width * .125,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(4.0)),
                            border: Border.all(color: Colors.blueAccent, width: 2.0),
                            color: Colors.blueAccent,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.switch_camera,
                            color: Colors.white,
                            size: size.width / 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () async {
                      endCall();
                    },
                    child: Container(
                      height: size.width * .15,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                      ),
                      child: Icon(
                        Icons.phone_missed,
                        color: Colors.white,
                        size: size.width / 14.0,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () async {
                      _createOffer();
                    },
                    child: Container(
                      height: size.width * .15,
                      decoration: BoxDecoration(
                        color: Colors.green,
                      ),
                      child: Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: size.width / 14.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
