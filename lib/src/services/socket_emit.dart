import 'package:get_boilerplate/src/services/socket.dart';

class SocketEmit {
  joinCall(int id) {
    socket.emit('join', id);
  }

  sendMessage(int senderId, String message) {
    socket.emit('call', {'sender': senderId, 'message': message});
  }
}
