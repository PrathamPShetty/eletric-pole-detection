import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as imageLib;
import 'package:pole/tflite/recognition.dart';
import 'package:pole/tflite/recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'stats.dart';
class Classifier {
  static const String MODEL_FILE_NAME = "detect.tflite";
  static const String LABEL_FILE_NAME = "labelmap.txt";
  static const int INPUT_SIZE = 300;
  static const double THRESHOLD = 0.5;
  static const int NUM_RESULTS = 10;

  late Interpreter _interpreter;
  late List<String> _labels;
  ImageProcessor? imageProcessor;
  late int padSize;
  late List<List<int>> _outputShapes;
  late List<TfLiteType> _outputTypes;

  Classifier({Interpreter? interpreter, List<String>? labels}) {
    _loadModel(interpreter: interpreter);
    _loadLabels(labels: labels);
  }

  Future<void> _loadModel({Interpreter? interpreter}) async {
    try {
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            MODEL_FILE_NAME,
            options: InterpreterOptions()..threads = 4,
          );

      _outputShapes = _interpreter.getOutputTensors().map((tensor) => tensor.shape).toList();
      _outputTypes = _interpreter.getOutputTensors().map((tensor) => tensor.type).toList();
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _loadLabels({List<String>? labels}) async {
    try {
      _labels = labels ?? await FileUtil.loadLabels("assets/$LABEL_FILE_NAME");
    } catch (e) {
      print("Error loading labels: $e");
    }
  }

  TensorImage _getProcessedImage(TensorImage inputImage) {
    padSize = max(inputImage.height, inputImage.width);
    imageProcessor ??= ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR))
        .build();

    return imageProcessor!.process(inputImage);
  }

  Map<String, dynamic>? predict(imageLib.Image image) {
    if (_interpreter == null) {
      print("Interpreter not initialized.");
      return null;
    }

    final predictStartTime = DateTime.now().millisecondsSinceEpoch;

    TensorImage inputImage = TensorImage.fromImage(image);
    final preProcessStartTime = DateTime.now().millisecondsSinceEpoch;
    inputImage = _getProcessedImage(inputImage);
    final preProcessingTime = DateTime.now().millisecondsSinceEpoch - preProcessStartTime;

    TensorBuffer outputLocations = TensorBufferFloat(_outputShapes[0]);
    TensorBuffer outputClasses = TensorBufferFloat(_outputShapes[1]);
    TensorBuffer outputScores = TensorBufferFloat(_outputShapes[2]);
    TensorBuffer numLocations = TensorBufferFloat(_outputShapes[3]);

    final inputs = [inputImage.buffer];
    final outputs = {
      0: outputLocations.buffer,
      1: outputClasses.buffer,
      2: outputScores.buffer,
      3: numLocations.buffer,
    };

    final inferenceStartTime = DateTime.now().millisecondsSinceEpoch;
    _interpreter.runForMultipleInputs(inputs, outputs);
    final inferenceTime = DateTime.now().millisecondsSinceEpoch - inferenceStartTime;

    final resultsCount = min(NUM_RESULTS, numLocations.getIntValue(0));
    final recognitions = <Recognition>[];

    for (int i = 0; i < resultsCount; i++) {
      final score = outputScores.getDoubleValue(i);
      if (score > THRESHOLD) {
        final label = _labels[outputClasses.getIntValue(i) + 1];
        final rect = BoundingBoxUtils.convert(
          tensor: outputLocations,
          valueIndex: [1, 0, 3, 2],
          boundingBoxAxis: 2,
          boundingBoxType: BoundingBoxType.BOUNDARIES,
          coordinateType: CoordinateType.RATIO,
          height: INPUT_SIZE,
          width: INPUT_SIZE,
        )[i];
        recognitions.add(Recognition(i, label, score, rect));
      }
    }

    final totalPredictTime = DateTime.now().millisecondsSinceEpoch - predictStartTime;
    return {
      "recognitions": recognitions,
      "stats": Stats(
        totalPredictTime: totalPredictTime,
        inferenceTime: inferenceTime,
        preProcessingTime: preProcessingTime,
        totalElapsedTime: totalPredictTime, // Update if inter-isolate delay applies
      ),
    };
  }
}
