import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as imageLib;
import 'package:pole/tflite/classifier.dart';
import 'package:pole/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String DEBUG_NAME = "InferenceIsolate";

  late Isolate _isolate;
  final ReceivePort _receivePort = ReceivePort();
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );

    _sendPort = await _receivePort.first;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final message in port) {
      try {
        if (message is IsolateData) {
          Classifier classifier = Classifier(
            interpreter: Interpreter.fromAddress(message.interpreterAddress),
            labels: message.labels,
          );
          imageLib.Image? image = ImageUtils.convertCameraImage(message.cameraImage);

          if (image == null) {
            throw Exception("Image conversion failed.");
          }

          // Rotate image for Android (if needed)
          if (Platform.isAndroid) {
            image = imageLib.copyRotate(image, 90);
          }

          // Run inference and send results
          Map<String, dynamic> results = classifier.predict(image);
          message.responsePort.send(results);
        } else {
          throw Exception("Invalid message type: ${message.runtimeType}");
        }
      } catch (e) {
        print("Error in isolate: $e");
        if (message is IsolateData) {
          message.responsePort.send({"error": e.toString()});
        }
      }
    }
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  final CameraImage cameraImage;
  final int interpreterAddress;
  final List<String> labels;
  final SendPort responsePort;

  IsolateData(
      this.cameraImage,
      this.interpreterAddress,
      this.labels,
      this.responsePort,
      );
}
