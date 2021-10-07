import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as RTC;
import 'package:get_boilerplate/src/pages/home/home_page.dart';
import 'package:get_boilerplate/src/services/socket_emit.dart';
import 'package:sdp_transform/sdp_transform.dart';

class RemoteViewCard extends StatefulWidget {
  final dynamic info;
  final localStream;
  final localRenderer;

  RemoteViewCard({this.info, this.localStream, this.localRenderer});

  @override
  State<StatefulWidget> createState() => _RemoteViewCardState();
}

class _RemoteViewCardState extends State<RemoteViewCard> {
  Timer _timmerInstance;

  //VideoCallVariables
  RTC.RTCPeerConnection _peerConnection;
  RTC.RTCVideoRenderer _remoteRenderer = RTC.RTCVideoRenderer();
  bool isFrontCamera = true;

  @override
  void initState() {
    super.initState();

    initRenderers();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
      _setRemoteDescription(widget.info);
    });
  }

  @override
  void dispose() {
    _peerConnection.close();
    _timmerInstance.cancel();
    super.dispose();
  }

  initRenderers() async {
    await _remoteRenderer.initialize();
  }

  void switchCamera() async {}

  void _createAnswer() async {
    RTC.RTCSessionDescription description = await _peerConnection.createAnswer({
      'offerToReceiveVideo': 1,
      'offerToReceiveAudio': 1,
    });

    var session = parse(description.sdp);
    String sdp = write(session, null);
    await sendSdp(sdp);

    _peerConnection.setLocalDescription(description);

    _peerConnection.onIceCandidate = (event) => {
          sendCandidates(event.candidate.toString(), event.sdpMid.toString(), event.sdpMlineIndex),
        };
  }

  void _setRemoteDescription(sdp) async {
    RTC.RTCSessionDescription description = new RTC.RTCSessionDescription(sdp, 'offer');
    await _peerConnection.setRemoteDescription(description);
    _createAnswer();
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

    RTC.RTCPeerConnection pc = await RTC.createPeerConnection(configuration, offerSdpConstraints);
    // if (pc != null) print(pc);
    pc.addStream(widget.localStream);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMlineIndex,
        }));
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
        '{"ice":{"candidate":${jsonEncode(candidate)},"sdpMid":$sdpMid,"sdpMlineIndex":$sdpMLineIndex}}';
    SocketEmit().sendMessage(MY_ID, jsonString);
  }

  Future sendSdp(
    String sdp,
  ) async {
    String jsonString = '{"sdp":{"type":"answer","sdp":${jsonEncode(sdp)}}}';
    SocketEmit().sendMessage(MY_ID, jsonString);
  }

  endCall() {
    _peerConnection.close();
    _timmerInstance.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      child: _remoteRenderer.textureId == null
          ? Container()
          : FittedBox(
              fit: BoxFit.cover,
              child: Container(
                height: size.width * .45,
                width: size.width * .45,
                child: Transform(
                  transform: Matrix4.identity()..rotateY(0.0),
                  alignment: FractionalOffset.center,
                  child: Texture(textureId: _remoteRenderer.textureId),
                ),
              ),
            ),
    );
  }
}
