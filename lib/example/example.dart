import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_advanced_cropper/flutter_advanced_cropper.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? imageFile;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = await _getImageFileFromAssets('assets/test.png');
    setState(() {
      imageFile = file;
    });
  }

  Future<File> _getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load(path);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/temp.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  void cropImage(BuildContext context, File originalImageFile) async {
    // Navigate to cropper screen
    final File? croppedFile = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCropperScreen(imageFile: originalImageFile),
      ),
    );

    if (croppedFile != null) {
      // Preview the cropped image in a new screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('Cropped Image Preview')),
                body: Center(child: Image.file(croppedFile)),
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Start Crop')),
        body: Center(
          child:
              imageFile == null
                  ? const CircularProgressIndicator()
                  : Builder(
                    builder:
                        (ctx) => ElevatedButton(
                          onPressed: () => cropImage(ctx, imageFile!),
                          child: const Text('Open Cropper'),
                        ),
                  ),
        ),
      ),
    );
  }
}
