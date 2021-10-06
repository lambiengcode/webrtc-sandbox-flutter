import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_boilerplate/src/pages/call/call_screen.dart';
import 'package:get_boilerplate/src/services/socket_emit.dart';
import 'package:socket_io_client/socket_io_client.dart';

const int MY_ID = 12022000;
Socket socket;

void connectAndListen() async {
  var urlConnectSocket = 'http://192.168.1.8:3000';
  print(urlConnectSocket);
  socket =
      io(urlConnectSocket, OptionBuilder().enableForceNew().setTransports(['websocket']).build());
  socket.connect();
  socket.onConnect((_) {
    print('connected');

    SocketEmit().joinCall(MY_ID);

    socket.on('call', (data) {
      if (data['message'] != null) {
        var message = jsonDecode(data['message']);
        print(message);
        var sender = data['sender'];
        if (sender != MY_ID) {
          var ice = message['ice'];
          if (ice != null) {
            // Opponent accept my call
          } else if (message["sdp"]["type"] == "offer") {
            print(message["sdp"]["sdp"]);
            // Receive a call
            Get.to(CallPage(
              info: message["sdp"]["sdp"],
            ));
          } else if (message["sdp"]["type"] == "answer") {
            // Opponent accept my call
          }
        }
      }
    });
  });

  socket.onDisconnect((_) => print('disconnect'));
}
