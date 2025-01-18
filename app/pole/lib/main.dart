import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
 // Use the actual plugin for PyTorch mobile
import 'dart:typed_data';
import 'package:pytorch_lite/pytorch_lite.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Object Detection',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ObjectDetectionScreen(camera: camera),
    );
  }
}

class ObjectDetectionScreen extends StatefulWidget {
  final CameraDescription camera;

  ObjectDetectionScreen({required this.camera});

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late CameraController _controller;
  late Interpreter _interpreter;  // PyTorch model interpreter
  late List<dynamic> _recognitions;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  // Initialize camera
  void _initializeCamera() {
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.startImageStream((image) {
        _processImage(image);
      });
    });
  }

  // Load the PyTorch model
  Future<void> _loadModel() async {
    try {
      _interpreter = await PytorchLite.loadObjectDetectionMode('assets/fasterrcnn_scripted.pt');
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  // Process the captured image and run object detection
  void _processImage(CameraImage image) async {
    // Convert CameraImage to byte data for inference
    final inputImage = await _convertImage(image);

    // Run inference with PyTorch model
    var recognitions = await _interpreter.run(inputImage);
    setState(() {
      _recognitions = recognitions;
    });
  }

  // Convert CameraImage to suitable format for the PyTorch model
  Future<Uint8List> _convertImage(CameraImage image) async {
    // Convert CameraImage to a format PyTorch model understands (usually byte buffer)
    // Use a library like `image` to convert and resize the image if needed.
    // For simplicity, this is a placeholder. Actual conversion will depend on the model.
    return Uint8List(0); // Placeholder
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Real-Time Object Detection')),
      body: Stack(
        children: [
          CameraPreview(_controller), // Display camera preview
          _recognitions.isEmpty
              ? Container()
              : CustomPaint(
            painter: ObjectPainter(_recognitions),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ObjectPainter extends CustomPainter {
  final List<dynamic> recognitions;

  ObjectPainter(this.recognitions);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textStyle = TextStyle(color: Colors.red, fontSize: 12);

    for (var recognition in recognitions) {
      final rect = recognition['rect']; // Bounding box coordinates
      final label = recognition['label']; // Object label
      final confidence = recognition['confidence']; // Confidence score

      canvas.drawRect(rect, paint);
      canvas.drawText(
        TextSpan(text: "$label $confidence", style: textStyle),
        Offset(rect.left, rect.top),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
