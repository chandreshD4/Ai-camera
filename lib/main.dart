import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(home: CameraScreen(camera: cameras.first), debugShowCheckedModeBanner: false));
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({super.key, required this.camera});
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
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      flutterTts.speak("नमस्ते चंद्रेश भाई, मैं तैयार हूँ। बटन दबाएं।");
    });
  }

  Future<void> _takeAndAnalyze() async {
    try {
      flutterTts.speak("तस्वीर ले रहा हूँ, प्रतीक्षा करें।");
      final XFile image = await _controller.takePicture();
      final Uint8List bytes = await image.readAsBytes();
      
      final response = await model.generateContent([
        Content.multi([TextPart("सामने क्या है? बहुत छोटा जवाब दें।"), DataPart('image/jpeg', bytes)])
      ]);
      flutterTts.speak(response.text ?? "क्षमा करें, मुझे कुछ समझ नहीं आया।");
    } catch (e) {
      flutterTts.speak("तस्वीर लेने में दिक्कत हुई।");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized 
        ? Column(children: [Expanded(child: CameraPreview(_controller)), ElevatedButton(onPressed: _takeAndAnalyze, child: const Text('तस्वीर देखें और बोलें'))])
        : const Center(child: CircularProgressIndicator()),
    );
  }
}
