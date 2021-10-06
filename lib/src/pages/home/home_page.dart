import 'package:flutter/material.dart';
import 'package:get_boilerplate/src/services/socket.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    connectAndListen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: Text("Sandbox WebRTC Video Call"),
        ),
      ),
    );
  }
}
