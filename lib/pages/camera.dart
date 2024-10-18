import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recomend.dart';
import 'dart:math' as math;

class CameraScreen extends StatefulWidget {
  const CameraScreen(
      {super.key, required this.audioPlayer, required this.songs});
  final AudioPlayer audioPlayer;
  final List<SongModel> songs;

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isModelLoaded = false;
  String? _prediction;

  @override
  void initState() {
    super.initState();
    widget.audioPlayer.stop();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![1], ResolutionPreset.high);
        await _controller?.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model:
            "assets/models/converted_model.tflite", // Ensure this path is correct
        labels: "assets/models/labels.txt", // Ensure this path is correct
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false,
      );
      if (res == "success") {
        setState(() {
          _isModelLoaded = true;
        });
        print("Model loaded successfully.");
      } else {
        print("Failed to load model.");
      }
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _classifyImage(String path) async {
    if (!_isModelLoaded) {
      print("Model is not loaded yet.");
      return;
    }

    try {
      var recognitions = await Tflite.runModelOnImage(
        path: path,
        numResults: 5,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        setState(() {
          _prediction = recognitions.first['label'];
        });

        // Print predicted label and confidence (accuracy)
        double confidence =
            recognitions.first['confidence'] ?? 0.0; // Confidence score
        print(
            "Predicted Label: $_prediction, Confidence: ${confidence * 100}%");
      } else {
        print('No Prediction');
      }

      // Navigate to the recommendation screen with the prediction
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReccomendationScreen(
            prediction: _prediction!,
            songs: widget.songs,
          ),
        ),
      );
    } catch (e) {
      print("Error classifying image: $e");
    }
  }

  Future<void> _captureAndClassify() async {
    try {
      final image = await _controller?.takePicture();
      if (image != null) {
        await _classifyImage(image.path);
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  @override
  void dispose() {
    // Dispose the camera controller if it's initialized
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }

    // Close the interpreter
    Tflite.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    'How are You Feeling',
                    style: GoogleFonts.openSans(
                      textStyle: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(15, 9, 104, 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isCameraInitialized && _controller != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40.0),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.73,
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(
                                math.pi), // Flip the preview horizontally
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _captureAndClassify,
                  child: Container(
                      height: 80.0,
                      width: 80.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                      child: Icon(Icons.camera_alt_sharp, size: 70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
