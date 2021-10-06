import 'package:get_boilerplate/src/pages/home/home_page.dart';

class SocketEmit {
  joinCall(int id) {
    socket.emit('join', id);
  }

  sendMessage(int senderId, String message) {
    socket.emit('call', {'sender': senderId, 'message': message});
  }
}
