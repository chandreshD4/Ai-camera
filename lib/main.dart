import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('कैमरा शुरू करने में समस्या: $e');
  }
  runApp(const AiCameraApp());
}

class AiCameraApp extends StatelessWidget {
  const AiCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ai Camera',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  FlutterTts flutterTts = FlutterTts();
  
  // GitHub Actions बनाते समय यह API Key खुद डाल देगा
  static const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    _initializeCamera();
    _checkFirstLaunch();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('first_launch') ?? true;
    
    if (isFirstLaunch) {
      await flutterTts.setLanguage("hi-IN");
      await flutterTts.speak("मुझे चंद्रेश भाई ने बनाया है");
      // इसे false सेट करें ताकि अगली बार न बोले
      await prefs.setBool('first_launch', false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty || !_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Camera by Chandresh'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CameraPreview(_controller),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('फोटो खींचे और पूछें', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                // यहाँ हम आगे चलकर फोटो खींचने और Gemini से पूछने का कोड डालेंगे
                flutterTts.speak("मैं तस्वीर देख रहा हूँ, कृपया प्रतीक्षा करें");
              },
            ),
          )
        ],
      ),
    );
  }
}
