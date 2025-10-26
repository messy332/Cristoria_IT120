import 'package:flutter/material.dart';

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Allow app to run even if Firebase isn't configured yet
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Cups Variety Scanner',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CoffeeScannerPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
  Interpreter? _interpreter;
  List<String> _labels = [];
  String? _predictedClass;
  double? _accuracy;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      final labelsStr = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsStr
          .split('\n')
          .where((e) => e.trim().isNotEmpty)
          .toList();
      _interpreter = await Interpreter.fromAsset('model_unquant.tflite');
      setState(() {});
    } catch (e) {
      debugPrint('Model/labels load error: $e');
      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _predictedClass = null;
        _accuracy = null;
      });
    }
  }

  Future<void> _classify() async {
    if (_imageFile == null || _interpreter == null || _labels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Model or image not ready. Ensure assets/model.tflite and assets/labels.txt exist.',
          ),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final bytes = await _imageFile!.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Unable to decode image');
      }
      const inputSize = 224;
      final resized = img.copyResize(
        decoded,
        width: inputSize,
        height: inputSize,
      );

      final input = _imageToFloat32(resized);
      final output = List.generate(
        1,
        (_) => List<double>.filled(_labels.length, 0.0),
      );
      _interpreter!.run(input, output);

      final scores = output[0];
      int maxIdx = 0;
      double maxVal = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxVal) {
          maxVal = scores[i];
          maxIdx = i;
        }
      }

      final predicted = _labels[maxIdx];
      final accuracy = (maxVal.isFinite ? maxVal : 0.0) * 100.0;

      setState(() {
        _predictedClass = predicted;
        _accuracy = accuracy;
      });

      try {
        final ref = FirebaseDatabase.instance.ref('coffee_predictions').push();
        await ref.set({
          'predicted_class': predicted,
          'accuracy_rate': double.parse(accuracy.toStringAsFixed(2)),
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Firebase write failed: $e');
      }
    } catch (e) {
      debugPrint('Classification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Classification failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _testWrite() async {
    try {
      final ref = FirebaseDatabase.instance.ref('coffee_predictions').push();
      await ref.set({
        'predicted_class': 'TEST',
        'accuracy_rate': 50.0,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Test write succeeded')));
      }
    } catch (e) {
      debugPrint('Test write failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Test write failed: $e')));
      }
    }
  }

  List<List<List<List<double>>>> _imageToFloat32(img.Image image) {
    const inputSize = 224;
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(inputSize, (_) => List<double>.filled(3, 0.0)),
      ),
    );
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        input[0][y][x][0] = r;
        input[0][y][x][1] = g;
        input[0][y][x][2] = b;
      }
    }
    return input;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Coffee Cups Variety Scanner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220,
              color: Colors.grey.shade200,
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                  : const Center(child: Text('No image selected')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _testWrite,
              child: const Text('Test Firebase Write'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _classify,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
            const SizedBox(height: 16),
            if (_predictedClass != null) ...[
              Text(
                'Predicted Variety: $_predictedClass',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_accuracy != null)
                Text('Accuracy Rate: ${_accuracy!.toStringAsFixed(2)}%'),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Accuracy History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(height: 240, child: _AccuracyChart()),
          ],
        ),
      ),
    );
  }
}

class _AccuracyChart extends StatelessWidget {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref(
    'coffee_predictions',
  );

  _AccuracyChart();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data?.snapshot.value;
        if (data == null || data is! Map) {
          return const Center(child: Text('No data'));
        }
        final entries = <Map<String, dynamic>>[];
        data.forEach((key, value) {
          if (value is Map) {
            entries.add({
              'accuracy_rate':
                  (value['accuracy_rate'] as num?)?.toDouble() ?? 0.0,
              'timestamp':
                  DateTime.tryParse(value['timestamp'] ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
            });
          }
        });
        entries.sort(
          (a, b) => (a['timestamp'] as DateTime).compareTo(
            b['timestamp'] as DateTime,
          ),
        );
        final spots = <FlSpot>[];
        for (int i = 0; i < entries.length; i++) {
          spots.add(
            FlSpot(i.toDouble(), (entries[i]['accuracy_rate'] as double)),
          );
        }
        if (spots.isEmpty) {
          return const Center(child: Text('No accuracy history'));
        }
        return LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: const FlGridData(show: true),
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                dotData: const FlDotData(show: true),
                color: Theme.of(context).colorScheme.primary,
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        );
      },
    );
  }
}
