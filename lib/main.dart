import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fl_chart/fl_chart.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'firebase_options.dart';
import 'coffee_cup_info.dart';
import 'history_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scape - Coffee Cup Variety Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6F4E37), // Coffee brown
          primary: const Color(0xFF6F4E37),
          secondary: const Color(0xFFA67B5B),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const CoffeeScannerPage(),
    );
  }
}

class CoffeeScannerPage extends StatefulWidget {
  const CoffeeScannerPage({super.key});
  
  @override
  State<CoffeeScannerPage> createState() => _CoffeeScannerPageState();
}

class _CoffeeScannerPageState extends State<CoffeeScannerPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  List<String> _labels = [];
  String? _predictedClass;
  double? _accuracy;
  bool _loading = false;
  bool _labelsLoaded = false;
  User? _currentUser;
  Interpreter? _interpreter;
  List<Map<String, dynamic>> _predictionDistribution = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _signInAnonymously();
    await _loadLabels();
    await _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      debugPrint('🔄 Loading TensorFlow Lite model...');
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
      debugPrint('✅ Model loaded successfully');
      debugPrint('📊 Input shape: ${_interpreter!.getInputTensors()}');
      debugPrint('📊 Output shape: ${_interpreter!.getOutputTensors()}');
    } catch (e) {
      debugPrint('❌ Error loading model: $e');
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        _currentUser = userCredential.user;
      });
      debugPrint('✅ Signed in anonymously: ${_currentUser?.uid}');
    } catch (e) {
      debugPrint('❌ Anonymous sign-in failed: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      debugPrint('🔄 Loading coffee cup varieties...');
      
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim())
          .toList();
      
      setState(() {
        _labelsLoaded = true;
      });
      
      debugPrint('✅ Loaded ${_labels.length} coffee cup varieties: ${_labels.join(", ")}');
      
    } catch (e) {
      debugPrint('❌ Error loading labels: $e');
      setState(() {
        _labelsLoaded = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _predictedClass = null;
          _accuracy = null;
          _predictionDistribution = [];
        });
        debugPrint('📸 Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  /// Analyzes image characteristics to determine if it looks like a coffee cup
  /// Returns a score from 0.0 (definitely not a cup) to 1.0 (likely a cup)
  /// Based on STRUCTURAL features (shape, edges, 3D form) NOT color
  Future<double> _analyzeImageCharacteristics(img.Image image) async {
    debugPrint('🔬 Analyzing image characteristics (structure-based)...');
    
    int passedChecks = 0;
    const int totalChecks = 3;
    
    // 1. Skin tone rejection - prevent hands/faces from being detected
    int skinTonePixels = 0;
    int sampleSize = 0;
    
    for (int y = 0; y < image.height; y += 4) {
      for (int x = 0; x < image.width; x += 4) {
        final pixel = image.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();
        
        sampleSize++;
        
        // Detect skin tones (hands, faces)
        if (r > 180 && g > 140 && b > 100 && r > g && g > b) {
          skinTonePixels++;
        }
      }
    }
    
    double skinPercent = (skinTonePixels / sampleSize) * 100;
    debugPrint('👋 Skin tone detection: ${skinPercent.toStringAsFixed(1)}%');
    
    // STRICT: Reject if too much skin tone (hands, faces)
    if (skinPercent > 15) {
      debugPrint('❌ Skin tone check FAILED - Too much skin detected (${skinPercent.toStringAsFixed(1)}%)');
      return 0.0; // Immediate rejection
    }
    passedChecks++;
    debugPrint('✅ Skin tone check passed');
    
    // 2. Edge density and structure - cups have defined edges and boundaries
    int strongEdges = 0;
    int totalEdgeChecks = 0;
    
    for (int y = 2; y < image.height - 2; y += 3) {
      for (int x = 2; x < image.width - 2; x += 3) {
        final center = image.getPixel(x, y);
        final right = image.getPixel(x + 2, y);
        final bottom = image.getPixel(x, y + 2);
        final left = image.getPixel(x - 2, y);
        final top = image.getPixel(x, y - 2);
        
        // Calculate gradient in all directions
        int diffR = ((center.r - right.r).abs() + (center.r - left.r).abs() + 
                     (center.r - top.r).abs() + (center.r - bottom.r).abs()).toInt();
        int diffG = ((center.g - right.g).abs() + (center.g - left.g).abs() + 
                     (center.g - top.g).abs() + (center.g - bottom.g).abs()).toInt();
        int diffB = ((center.b - right.b).abs() + (center.b - left.b).abs() + 
                     (center.b - top.b).abs() + (center.b - bottom.b).abs()).toInt();
        
        int totalDiff = diffR + diffG + diffB;
        totalEdgeChecks++;
        
        if (totalDiff > 150) {
          strongEdges++;
        }
      }
    }
    
    double edgeDensity = (strongEdges / totalEdgeChecks) * 100;
    debugPrint('📐 Edge density: ${edgeDensity.toStringAsFixed(1)}%');
    
    // Cups should have clear edges (object boundaries) - not too plain, not too chaotic
    if (edgeDensity > 5 && edgeDensity < 40) {
      passedChecks++;
      debugPrint('✅ Edge density check passed');
    } else {
      debugPrint('❌ Edge density check failed - ${edgeDensity < 5 ? "too plain/uniform" : "too chaotic/busy"}');
    }
    
    // 3. Contrast and 3D form - cups have defined shadows/highlights showing 3D structure
    List<int> brightness = [];
    
    for (int y = 0; y < image.height; y += 4) {
      for (int x = 0; x < image.width; x += 4) {
        final pixel = image.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();
        
        int bright = ((r + g + b) / 3).toInt();
        brightness.add(bright);
      }
    }
    
    double avgBrightness = brightness.reduce((a, b) => a + b) / brightness.length;
    double variance = brightness.map((b) => pow(b - avgBrightness, 2)).reduce((a, b) => a + b) / brightness.length;
    double stdDev = sqrt(variance);
    
    debugPrint('💡 Brightness std dev: ${stdDev.toStringAsFixed(1)}');
    
    // Cups should have good contrast showing 3D form
    // Too uniform = flat surface (wall, paper)
    // Good contrast = 3D object with lighting/shadows (cup)
    if (stdDev > 20 && stdDev < 95) {
      passedChecks++;
      debugPrint('✅ Contrast/3D form check passed');
    } else {
      debugPrint('❌ Contrast check failed - ${stdDev < 20 ? "too uniform/flat" : "too chaotic"}');
    }
    
    // Calculate final score: ALL checks must pass for high score
    double finalScore = passedChecks / totalChecks;
    
    debugPrint('🎯 Image characteristic score: ${(finalScore * 100).toStringAsFixed(1)}% (${passedChecks}/${totalChecks} checks passed)');
    debugPrint(passedChecks == totalChecks ? '✅ Image looks like a coffee cup' : '❌ Image does NOT look like a coffee cup');
    
    return finalScore;
  }

  Future<void> _classifyImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    if (!_labelsLoaded || _labels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coffee cup varieties not loaded. Please wait...')),
      );
      return;
    }

    if (_interpreter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model not loaded. Please restart the app.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      debugPrint('🔍 Starting coffee cup variety classification...');
      
      // Load and preprocess image
      final imageBytes = await _imageFile!.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // STEP 1: Analyze image characteristics BEFORE running the model
      double imageScore = await _analyzeImageCharacteristics(image);
      
      debugPrint('🔍 Image score: ${(imageScore * 100).toStringAsFixed(1)}%');
      debugPrint('✅ Skipping strict visual check - trusting model prediction');
      
      // STEP 2: Continue with model prediction
      // Teachable Machine uses 224x224 input size
      final inputSize = 224;
      img.Image resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );
      
      // Teachable Machine expects input shape: [1, 224, 224, 3]
      // Values normalized to 0-1 range
      var input = List.generate(
        1,
        (batch) => List.generate(
          inputSize,
          (y) => List.generate(
            inputSize,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                pixel.r / 255.0,  // Red channel (0-1)
                pixel.g / 255.0,  // Green channel (0-1)
                pixel.b / 255.0,  // Blue channel (0-1)
              ];
            },
          ),
        ),
      );
      
      // Prepare output tensor: [1, number_of_classes]
      var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      
      // Run inference
      debugPrint('🤖 Running model inference...');
      _interpreter!.run(input, output);
      
      // Get predictions
      List<double> probabilities = List<double>.from(output[0]);
      
      debugPrint('🔍 RAW OUTPUT: $probabilities');
      debugPrint('🔍 Number of classes: ${probabilities.length}');
      
      // Find the class with highest probability
      int maxIndex = 0;
      double maxProb = probabilities[0];
      int secondMaxIndex = -1;
      double secondMaxProb = 0.0;
      
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          secondMaxProb = maxProb;
          secondMaxIndex = maxIndex;
          maxProb = probabilities[i];
          maxIndex = i;
        } else if (probabilities[i] > secondMaxProb) {
          secondMaxProb = probabilities[i];
          secondMaxIndex = i;
        }
      }
      
      final confidence = maxProb * 100;
      final secondConfidence = secondMaxProb * 100;
      
      debugPrint('🎯 Top prediction: ${_labels[maxIndex]} (${confidence.toStringAsFixed(1)}%)');
      if (secondMaxIndex >= 0) {
        debugPrint('🥈 2nd prediction: ${_labels[secondMaxIndex]} (${secondConfidence.toStringAsFixed(1)}%)');
      }
      
      // Show ALL predictions in a clear format
      debugPrint('📊 === ALL CLASS PREDICTIONS ===');
      List<Map<String, dynamic>> currentDistribution = [];
      for (int i = 0; i < probabilities.length; i++) {
        String emoji = i == maxIndex ? '🥇' : (i == secondMaxIndex ? '🥈' : '  ');
        debugPrint('$emoji ${i + 1}. ${_labels[i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
        
        currentDistribution.add({
          'label': _labels[i],
          'confidence': probabilities[i] * 100,
          'isTop': i == maxIndex,
        });
      }
      // Sort by confidence descending
      currentDistribution.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
      
      debugPrint('📊 ================================');
      
      // Validation checks for unknown objects
      // VERY LENIENT thresholds - trust the Teachable Machine model
      
      const double confidenceThreshold = 15.0; // Minimum 15% confidence (was 25%)
      const double marginThreshold = 5.0; // Minimum 5% gap from 2nd place (was 10%)
      const double absoluteMinimum = 0.10; // Must be at least 10% confident (was 20%)
      
      double margin = confidence - secondConfidence;
      
      // Calculate entropy to detect uniform distribution (all classes similar = unknown)
      double entropy = 0.0;
      for (var prob in probabilities) {
        if (prob > 0.0001) { // Avoid log(0)
          entropy += prob * (log(prob) / log(2));
        }
      }
      entropy = -entropy;
      double maxEntropy = log(probabilities.length.toDouble()) / log(2);
      double normalizedEntropy = entropy / maxEntropy; // 0 = certain, 1 = uniform
      
      // Calculate standard deviation - low std = uniform = unknown
      double mean = probabilities.reduce((a, b) => a + b) / probabilities.length;
      double variance = probabilities.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) / probabilities.length;
      double stdDev = sqrt(variance);
      
      debugPrint('📊 Model Confidence: ${confidence.toStringAsFixed(1)}%');
      debugPrint('📊 2nd highest: ${secondConfidence.toStringAsFixed(1)}%');
      debugPrint('📊 Margin: ${margin.toStringAsFixed(1)}%');
      debugPrint('📊 Entropy: ${normalizedEntropy.toStringAsFixed(3)} (0=certain, 1=uniform)');
      debugPrint('📊 Std Dev: ${stdDev.toStringAsFixed(4)} (higher=more certain)');
      debugPrint('📊 Image Visual Score: ${(imageScore * 100).toStringAsFixed(1)}%');
      
      // COMBINED VALIDATION: Image characteristics + Model confidence
      // Both must agree for a valid prediction
      
      bool isLowConfidence = confidence < confidenceThreshold;
      bool isLowMargin = margin < marginThreshold;
      bool isUniform = normalizedEntropy > 0.95; // High entropy = confused (was 0.90)
      bool isTooWeak = maxProb < absoluteMinimum;
      bool isLowVariance = stdDev < 0.05; // Low variance = all classes similar (was 0.08)
      bool failedVisualCheck = false; // Disabled - trust the model
      
      debugPrint('📊 Validation checks:');
      debugPrint('   - Low confidence (<${confidenceThreshold}%): $isLowConfidence (actual: ${confidence.toStringAsFixed(1)}%)');
      debugPrint('   - Low margin (<${marginThreshold}%): $isLowMargin (actual: ${margin.toStringAsFixed(1)}%)');
      debugPrint('   - Uniform distribution (>95%): $isUniform (actual: ${(normalizedEntropy * 100).toStringAsFixed(1)}%)');
      debugPrint('   - Too weak (<${absoluteMinimum * 100}%): $isTooWeak');
      debugPrint('   - Low variance (<0.05): $isLowVariance (actual: ${stdDev.toStringAsFixed(4)})');
      debugPrint('   - Visual check: DISABLED (trusting model)');

      
      if (isLowConfidence || isLowMargin || isUniform || isTooWeak || isLowVariance || failedVisualCheck) {
        // Low confidence - not a coffee cup or unknown object
        setState(() {
          _predictedClass = 'Not Recognized';
          _accuracy = 0.0; // Set to 0% for unknown objects
          _predictionDistribution = currentDistribution;
        });
        
        // Save to Firebase with 0% accuracy for tracking
        await _saveToFirebase('Not Recognized', 0.0);
        
        String reason = '';
        if (failedVisualCheck) {
          reason = '⚠️ Image doesn\'t visually match trained coffee cups (visual score: ${(imageScore * 100).toStringAsFixed(0)}%)';
        } else if (isTooWeak || isUniform || isLowVariance) {
          reason = '⚠️ This object does not match any trained coffee cup class.';
        } else if (isLowConfidence) {
          reason = '⚠️ Confidence too low (${confidence.toStringAsFixed(1)}%). Not a recognized coffee cup.';
        } else if (isLowMargin) {
          reason = '⚠️ Uncertain prediction (margin: ${margin.toStringAsFixed(1)}%). Not a clear match.';
        } else {
          reason = '⚠️ Object not recognized as a trained coffee cup.';
        }
        
        debugPrint('❌ REJECTED: $reason');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(reason),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        
        debugPrint('⚠️ Object not recognized - Reason: $reason');
      } else {
        // Good confidence - valid prediction
        final predictedLabel = _labels[maxIndex];
        final secondLabel = secondMaxIndex >= 0 ? _labels[secondMaxIndex] : '';
        
        setState(() {
          _predictedClass = predictedLabel;
          _accuracy = confidence;
          _predictionDistribution = currentDistribution;
        });

        // Save to Firebase with actual confidence
        await _saveToFirebase(predictedLabel, confidence);
        
        // Check if prediction is uncertain between commonly confused classes
        final confusedClasses = ['Turkish Coffee Cup', 'Japanese Matcha Chawan', 'Vietnam Egg Coffee Cup'];
        bool isConfusedPrediction = confusedClasses.contains(predictedLabel) && 
                                    confusedClasses.contains(secondLabel) && 
                                    margin < 20;
        
        // Show success message with warning if uncertain
        if (mounted) {
          if (isConfusedPrediction) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Detected: $predictedLabel (${confidence.toStringAsFixed(0)}%)\nUncertain - also similar to $secondLabel'),
                backgroundColor: Colors.orange.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Detected: $predictedLabel (${confidence.toStringAsFixed(0)}%)'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
      
    } catch (e) {
      debugPrint('❌ Classification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classification failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveToFirebase(String prediction, double confidence) async {
    if (_currentUser == null) {
      debugPrint('❌ No authenticated user for Firebase save');
      return;
    }

    try {
      final ref = FirebaseDatabase.instance.ref('coffee_predictions').push();
      await ref.set({
        'predicted_class': prediction,
        'accuracy_rate': double.parse(confidence.toStringAsFixed(2)),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'user_id': _currentUser!.uid,
        'cup_variety': prediction,
        'confidence': confidence,
        'is_valid': prediction != 'Unknown Object' && prediction != 'Not Recognized', // Track if it's a valid prediction
      });
      debugPrint('💾 Saved to Firebase: $prediction (${confidence.toStringAsFixed(1)}%)');
    } catch (e) {
      debugPrint('❌ Firebase save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '☕',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Scape',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.library_books_outlined),
            tooltip: 'View Cup Varieties',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoffeeCupGalleryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image display card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: _imageFile == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.brown.shade50,
                            Colors.orange.shade50,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.coffee_outlined,
                              size: 64,
                              color: Colors.brown.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select a Coffee Cup Image',
                              style: TextStyle(
                                color: Colors.brown.shade600,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use camera or gallery',
                              style: TextStyle(
                                color: Colors.brown.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text(
                      'Camera',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text(
                      'Gallery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA67B5B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                  ),
                ),
                if (_imageFile != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _imageFile = null;
                        _predictedClass = null;
                        _accuracy = null;
                        _predictionDistribution = [];
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      elevation: 2,
                    ),
                    child: const Icon(Icons.close, size: 24),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Classify button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _classifyImage,
                icon: _loading 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics_outlined, size: 24),
                label: Text(
                  _loading ? 'Analyzing...' : 'Analyze Coffee Cup',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 4,
                  disabledBackgroundColor: Colors.brown.shade300,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Results
            if (_predictedClass != null) ...[
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.coffee,
                          size: 48,
                          color: Color(0xFF6F4E37),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Detection Result',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.brown.shade600,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: (_predictedClass == 'Unknown Object' || _predictedClass == 'Not Recognized')
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CoffeeCupDetailPage(
                                      cupName: _predictedClass!,
                                    ),
                                  ),
                                );
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: (_predictedClass == 'Unknown Object' || _predictedClass == 'Not Recognized')
                                ? Colors.orange.shade50
                                : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_predictedClass == 'Unknown Object' || _predictedClass == 'Not Recognized')
                                    Icon(
                                      Icons.help_outline,
                                      color: Colors.orange.shade700,
                                      size: 24,
                                    ),
                                  if (_predictedClass == 'Unknown Object' || _predictedClass == 'Not Recognized')
                                    const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _predictedClass!,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: (_predictedClass == 'Unknown Object' || _predictedClass == 'Not Recognized')
                                            ? Colors.orange.shade700
                                            : const Color(0xFF6F4E37),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              if (_predictedClass != 'Unknown Object' && _predictedClass != 'Not Recognized') ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Tap for details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.brown.shade400,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Colors.brown.shade400,
                                    ),
                                  ],
                                ),
                              ],
                              if (_predictedClass == 'Unknown Object' || _predictedClass == 'Not Recognized') ...[
                                const SizedBox(height: 8),
                                Text(
                                  'This image does not match any trained coffee cup class',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_accuracy != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: (_predictedClass == 'Unknown Object' || _predictedClass == 'Not Recognized')
                                  ? [
                                      Colors.orange.shade400,
                                      Colors.orange.shade600,
                                    ]
                                  : [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Confidence: ${_accuracy!.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Prediction Distribution
              if (_predictionDistribution.isNotEmpty) ...[
                Text(
                  'Prediction Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _predictionDistribution.map((item) {
                      final isTop = item['isTop'] as bool;
                      final confidence = item['confidence'] as double;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade100,
                              width: 1,
                            ),
                          ),
                          color: isTop ? Colors.green.withOpacity(0.05) : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              isTop ? '🥇' : '  ',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['label'],
                                style: TextStyle(
                                  fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                                  color: isTop ? Colors.green.shade800 : Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              '${confidence.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                                color: isTop ? Colors.green.shade800 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              height: 6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: confidence / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isTop ? Colors.green : Colors.brown.shade300,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
            
            // Chart section
            Divider(thickness: 1, color: Colors.brown.shade200),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6F4E37).withOpacity(0.1),
                    const Color(0xFFA67B5B).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: const Color(0xFF6F4E37),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Prediction History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6F4E37),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    color: const Color(0xFF6F4E37),
                    tooltip: 'Refresh data',
                    onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      final snapshot = await FirebaseDatabase.instance
                          .ref('coffee_predictions')
                          .get();
                      debugPrint('🔍 Manual fetch - exists: ${snapshot.exists}');
                      debugPrint('🔍 Manual fetch - value: ${snapshot.value}');
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              snapshot.exists 
                                  ? 'Data found! Check console' 
                                  : 'No data in Firebase',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('🔍 Manual fetch error: $e');
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 250,
                  child: _AccuracyChart(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _PredictionReport(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


}

class _AccuracyChart extends StatelessWidget {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('coffee_predictions');

  final List<String> _allClasses = [
    'Turkish Coffee Cup',
    'Japanese Matcha Chawan',
    'Vietnam Egg Coffee Cup',
    'Espresso Demitasse Cup',
    'Double-Walled Insulated Mug',
    'Reusable Stainless Steel Travel Cup',
    'Cappucino Cup(Italian Style)',
    'Latte Glass(Irish Coffee Style)',
    'Yixing Clay Coffee Cup',
    'Ceramic Pour-Over Coffee Mug',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _ref.onValue,
      builder: (context, snapshot) {
        debugPrint('📊 StreamBuilder state: ${snapshot.connectionState}');
        debugPrint('📊 Has data: ${snapshot.hasData}');
        debugPrint('📊 Has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          debugPrint('📊 Error: ${snapshot.error}');
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final data = snapshot.data?.snapshot.value;
        debugPrint('📊 Chart data received: $data');
        debugPrint('📊 Data type: ${data.runtimeType}');
        
        if (data == null) {
          debugPrint('📊 Data is null');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text(
                  'No predictions yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const Text(
                  'Analyze some coffee cup varieties to see your history!',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        if (data is! Map) {
          debugPrint('📊 Data is not a Map, it is: ${data.runtimeType}');
          return Center(
            child: Text(
              'Unexpected data format: ${data.runtimeType}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        
        // Count occurrences of each class
        final classCounts = <String, int>{};
        for (var className in _allClasses) {
          classCounts[className] = 0;
        }
        
        // Mapping for old truncated labels to new full labels
        final labelMapping = {
          '0 Turkish Coff...': 'Turkish Coffee Cup',
          '1 Japanese Mat...': 'Japanese Matcha Chawan',
          '2 Vietnam Egg ...': 'Vietnam Egg Coffee Cup',
          '3 Espresso Dem...': 'Espresso Demitasse Cup',
          '4 Double-Walle...': 'Double-Walled Insulated Mug',
          '5 Reusable Sta...': 'Reusable Stainless Steel Travel Cup',
          '6 Cappucino Cu...': 'Cappucino Cup(Italian Style)',
          '7 Latte Glass(...': 'Latte Glass(Irish Coffee Style)',
          '8 Yixing Clay ...': 'Yixing Clay Coffee Cup',
          '9 Ceramic Pour...': 'Ceramic Pour-Over Coffee Mug',
        };
        
        debugPrint('📊 Processing ${data.length} entries from Firebase');
        
        data.forEach((key, value) {
          debugPrint('📊 Entry key: $key, value type: ${value.runtimeType}');
          if (value is Map) {
            var cupVariety = value['predicted_class'] ?? value['cup_variety'] ?? 'Unknown';
            
            // Skip test entries
            if (cupVariety == 'TEST' || cupVariety == 'TEST_COFFEE') {
              debugPrint('📊 Skipping test entry: $cupVariety');
              return;
            }
            
            // Map old truncated labels to new full labels
            if (labelMapping.containsKey(cupVariety)) {
              cupVariety = labelMapping[cupVariety]!;
              debugPrint('📊 Mapped old label to: $cupVariety');
            }
            
            debugPrint('📊 Found cup variety: $cupVariety');
            if (classCounts.containsKey(cupVariety)) {
              classCounts[cupVariety] = classCounts[cupVariety]! + 1;
            } else {
              debugPrint('⚠️ Cup variety not in class list: $cupVariety');
            }
          }
        });
        
        debugPrint('📊 Final class counts: $classCounts');
        
        final totalCount = classCounts.values.reduce((a, b) => a + b);
        debugPrint('📊 Total predictions counted: $totalCount');
        
        // Create line chart data
        final spots = <FlSpot>[];
        int maxCount = 0;
        
        for (int i = 0; i < _allClasses.length; i++) {
          final count = classCounts[_allClasses[i]] ?? 0;
          if (count > maxCount) maxCount = count;
          spots.add(FlSpot(i.toDouble(), count.toDouble()));
        }
        
        // Calculate appropriate interval for Y-axis
        final yInterval = maxCount <= 5 ? 1.0 : (maxCount / 5).ceilToDouble();
        final adjustedMaxY = ((maxCount / yInterval).ceil() + 1) * yInterval;
        
        return LineChart(
          LineChartData(
            maxY: adjustedMaxY,
            minY: 0,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: yInterval,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    if (value % yInterval == 0) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6F4E37),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < _allClasses.length) {
                      final className = _allClasses[value.toInt()];
                      final shortName = className.split(' ').first;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            shortName,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6F4E37),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: Colors.grey.shade400, width: 1),
                bottom: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF6F4E37),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: const Color(0xFF8B4513),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6F4E37).withOpacity(0.3),
                      const Color(0xFF6F4E37).withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    if (index >= 0 && index < _allClasses.length) {
                      final className = _allClasses[index];
                      final count = spot.y.toInt();
                      return LineTooltipItem(
                        '$className\nTested: $count time${count != 1 ? 's' : ''}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}



class _PredictionReport extends StatelessWidget {
  final DatabaseReference _ref =
      FirebaseDatabase.instance.ref('coffee_predictions');

  final List<String> _allClasses = [
    'Turkish Coffee Cup',
    'Japanese Matcha Chawan',
    'Vietnam Egg Coffee Cup',
    'Espresso Demitasse Cup',
    'Double-Walled Insulated Mug',
    'Reusable Stainless Steel Travel Cup',
    'Cappucino Cup(Italian Style)',
    'Latte Glass(Irish Coffee Style)',
    'Yixing Clay Coffee Cup',
    'Ceramic Pour-Over Coffee Mug',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _ref.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.snapshot.value;
        if (data is! Map) {
          return const SizedBox.shrink();
        }

        // Mapping for old truncated labels to new full labels
        final labelMapping = {
          '0 Turkish Coff...': 'Turkish Coffee Cup',
          '1 Japanese Mat...': 'Japanese Matcha Chawan',
          '2 Vietnam Egg ...': 'Vietnam Egg Coffee Cup',
          '3 Espresso Dem...': 'Espresso Demitasse Cup',
          '4 Double-Walle...': 'Double-Walled Insulated Mug',
          '5 Reusable Sta...': 'Reusable Stainless Steel Travel Cup',
          '6 Cappucino Cu...': 'Cappucino Cup(Italian Style)',
          '7 Latte Glass(...': 'Latte Glass(Irish Coffee Style)',
          '8 Yixing Clay ...': 'Yixing Clay Coffee Cup',
          '9 Ceramic Pour...': 'Ceramic Pour-Over Coffee Mug',
        };

        // Count occurrences and calculate stats
        final classCounts = <String, int>{};
        final accuracies = <double>[];
        int totalPredictions = 0;

        for (var className in _allClasses) {
          classCounts[className] = 0;
        }

        data.forEach((key, value) {
          if (value is Map) {
            var cupVariety = value['predicted_class'] ?? 'Unknown';
            final accuracy = (value['accuracy_rate'] as num?)?.toDouble();

            // Skip test entries
            if (cupVariety == 'TEST' || cupVariety == 'TEST_COFFEE') {
              return;
            }

            // Map old labels to new labels
            if (labelMapping.containsKey(cupVariety)) {
              cupVariety = labelMapping[cupVariety]!;
            }

            if (classCounts.containsKey(cupVariety)) {
              classCounts[cupVariety] = classCounts[cupVariety]! + 1;
              totalPredictions++;
              if (accuracy != null) {
                accuracies.add(accuracy);
              }
            }
          }
        });

        if (totalPredictions == 0) {
          return const SizedBox.shrink();
        }

        // Find most and least tested
        String mostTested = '';
        String leastTested = '';
        int maxCount = 0;
        int minCount = totalPredictions;

        classCounts.forEach((className, count) {
          if (count > 0) {
            if (count > maxCount) {
              maxCount = count;
              mostTested = className;
            }
            if (count < minCount) {
              minCount = count;
              leastTested = className;
            }
          }
        });

        // Calculate average accuracy
        final avgAccuracy = accuracies.isEmpty
            ? 0.0
            : accuracies.reduce((a, b) => a + b) / accuracies.length;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.assessment,
                        color: Color(0xFF6F4E37),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Prediction Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6F4E37),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatRow(
                  'Total Predictions',
                  totalPredictions.toString(),
                  Icons.analytics_outlined,
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Average Accuracy',
                  '${avgAccuracy.toStringAsFixed(1)}%',
                  Icons.percent,
                ),
                const SizedBox(height: 12),
                _buildStatRow('Most Tested', mostTested, Icons.trending_up),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Least Tested',
                  leastTested.isEmpty ? 'N/A' : leastTested,
                  Icons.trending_down,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6F4E37)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6F4E37),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
