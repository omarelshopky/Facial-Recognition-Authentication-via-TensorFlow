import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';


class CameraService {
  // To build Singleton
  static final CameraService _cameraService = CameraService._internal();

  late CameraController _controller;
  late CameraDescription _description;
  late InputImageRotation _rotation;
  late String _imagePath;


  factory CameraService() {
    return _cameraService;
  }
  // To build Singleton
  CameraService._internal();


  // Getters for the attributes
  get cameraController => _controller;
  get rotation => _rotation;
  get imagePath => _imagePath;


  /// Initializes the attributes
  Future init(CameraDescription cameraDescription) async {
    _description = cameraDescription;

    _controller = CameraController(
      _description,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _rotation = _degreeToImageRotation(_description.sensorOrientation);

    return _controller.initialize();
  }


  /// Converts the camera orientation [degree] to image rotation
  InputImageRotation _degreeToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.Rotation_90deg;
      case 180:
        return InputImageRotation.Rotation_180deg;
      case 270:
        return InputImageRotation.Rotation_270deg;
      default:
        return InputImageRotation.Rotation_0deg;
    }
  }


  /// Releases the camera resource
  void dispose() {
    _controller.dispose();
  }


  /// Captures an image and return its file
  Future<XFile> takePicture() async {
    XFile file = await _controller.takePicture();
    _imagePath = file.path;
    return file;
  }


  /// Returns the image size as an object
  Size getImageSize() {
    return Size(
      _controller.value.previewSize!.height,
      _controller.value.previewSize!.width,
    );
  }
}
