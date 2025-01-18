import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pole/tflite/classifier.dart';
import 'package:pole/tflite/recognition.dart';
import 'package:pole/tflite/stats.dart';
import 'package:pole/ui/camera_view_singleton.dart';
import 'package:pole/utils/isolate_utils.dart';


class CameraView extends StatefulWidget {
  final Function(List<Recognition> recognitions) resultsCallback;
  final Function(Stats stats) statsCallback;

  const CameraView(this.resultsCallback, this.statsCallback, {Key? key})
      : super(key: key);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  late CameraController? cameraController;
  late List<CameraDescription> cameras;
  late bool predicting;
  late Classifier classifier;
  late IsolateUtils isolateUtils;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  Future<void> initStateAsync() async {
    WidgetsBinding.instance.addObserver(this);

    try {
      isolateUtils = IsolateUtils();
      await isolateUtils.start();

      classifier = Classifier();

      cameras = await availableCameras();
      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.low,
        enableAudio: false,
      );

      await cameraController?.initialize();

      if (cameraController?.value.isInitialized == true) {
        await cameraController?.startImageStream(onLatestImageAvailable);

        Size? previewSize = cameraController?.value.previewSize;
        CameraViewSingleton.inputImageSize = previewSize!;

        Size screenSize = MediaQuery.of(context).size;
        CameraViewSingleton.screenSize = screenSize;
        CameraViewSingleton.ratio = screenSize.width / previewSize.height;
      }

      predicting = false;
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !(cameraController?.value.isInitialized ?? false)) {
      return Container();
    }

    return AspectRatio(
      aspectRatio: cameraController!.value.aspectRatio,
      child: CameraPreview(cameraController!),
    );
  }

  Future<void> onLatestImageAvailable(CameraImage cameraImage) async {
    if (predicting || classifier.interpreter == null || classifier.labels == null) {
      return;
    }

    setState(() {
      predicting = true;
    });

    try {
      var uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;

      var isolateData = IsolateData(
        cameraImage,
        classifier.interpreter.address,
        classifier.labels,
      );

      Map<String, dynamic> inferenceResults = await inference(isolateData);

      var uiThreadInferenceElapsedTime =
          DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

      widget.resultsCallback(inferenceResults["recognitions"]);
      widget.statsCallback((inferenceResults["stats"] as Stats)
        ..totalElapsedTime = uiThreadInferenceElapsedTime);
    } catch (e) {
      print("Error during inference: $e");
    } finally {
      setState(() {
        predicting = false;
      });
    }
  }

  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort.send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results as Map<String, dynamic>;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        await cameraController?.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (!(cameraController?.value.isStreamingImages ?? false)) {
          await cameraController?.startImageStream(onLatestImageAvailable);
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    isolateUtils.dispose();
    super.dispose();
  }
}
