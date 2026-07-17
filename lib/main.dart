import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MaterialApp(home: CameraScreen(), debugShowCheckedModeBanner: false));
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  FlutterTts flutterTts = FlutterTts();
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: const String.fromEnvironment('GEMINI_API_KEY'));

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    _controller = CameraController(cameras[0], ResolutionPreset.low);
    await _controller.initialize();
    setState(() {});
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('first_launch') ?? true) {
      await flutterTts.setLanguage("hi-IN");
      await flutterTts.speak("नमस्ते, मुझे चंद्रेश भाई ने बनाया है।");
      await prefs.setBool('first_launch', false);
    }
  }

  Future<void> _processImage() async {
    final image = await _controller.takePicture();
    final bytes = await image.readAsBytes();
    final response = await model.generateContent([
      Content.multi([TextPart("सामने क्या है? बहुत छोटा जवाब दें।"), DataPart('image/jpeg', base64Encode(bytes))])
    ]);
    await flutterTts.speak(response.text ?? "समझ नहीं आया");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _controller.value.isInitialized ? CameraPreview(_controller) : Container()),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _processImage,
              child: const Text('तस्वीर देखें और बोलें'),
            ),
          )
        ],
      ),
    );
  }
}
