import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_v2/tflite_v2.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initModel();
  }

  dispose() {
    cameraController.dispose();
    super.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
var cameraCount = 0;
  initCamera() async {
    if(await Permission.camera.request().isGranted) {

    cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await cameraController.initialize().then((value) {
      cameraController.startImageStream((image) {
        cameraCount++;
        if (cameraCount % 10 == 0) {
          cameraCount = 0;
          objectDetection(image);
        }
        update();
      });
    });
    isCameraInitialized.value = true;
    update();
  }
  else{
    Get.snackbar('Permission Required', 'Please allow camera permission');
    }
    }

    initModel() async {
    await Tflite.loadModel(
      model: 'assets/detect.tflite',
      labels: 'assets/labelmap.txt',
      );
    }

    objectDetection(CameraImage image) async {
 var detectedObjects = await Tflite.runModelOnFrame(
    bytesList: image.planes.map((plane) {
      return plane.bytes;
    }).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 2,
      threshold: 0.1,
      );
 if (detectedObjects != null) {
    print(detectedObjects);
    }
    }
}