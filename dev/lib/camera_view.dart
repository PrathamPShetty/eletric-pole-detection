import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'Scannercontroller.dart';


class CameraView extends StatelessWidget {
  const CameraView({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: GetBuilder<ScanController>(
      init: ScanController(),
      builder: (controller) {
    if(controller.isCameraInitialized.value){
    return CameraPreview(controller.cameraController);
    }
    else{
    return Center(child: CircularProgressIndicator());
    }
    },
    ),
    );}}