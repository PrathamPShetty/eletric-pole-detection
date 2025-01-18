import 'package:flutter/material.dart';
import 'camera_view.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Object Detection',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CameraView()
    );
  }
}


