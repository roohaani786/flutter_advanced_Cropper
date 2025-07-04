# Advanced Image Cropper

A powerful and intuitive Flutter package for cropping images with advanced features including rotation, smooth animations, and high-quality output.

## Features

- **Smooth Interactive Cropping**: Drag handles with haptic feedback and smooth animations
- **Image Rotation**: Built-in rotation support with 90-degree increments
- **High-Quality Output**: Maintains image quality with configurable maximum dimensions
- **Responsive Design**: Adapts to different screen sizes and orientations
- **Modern UI**: Glass-morphism design with backdrop blur effects
- **Performance Optimized**: Dual-layer rendering (low-res preview + high-res overlay)
- **Gesture-Friendly**: Extended touch areas for better accessibility
- **Memory Efficient**: Proper image disposal and memory management

## Screenshots

<img src="assets/cropper_preview.jpeg" alt="Cropper Screenshot" width="300" height="600" />
<img src ="https://raw.githubusercontent.com/roohaani786/flutter_advanced_Cropper/refs/heads/main/assets/cropper_preview.jpeg" alt="Cropper Screenshot" width="300" height="600" />

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_advanced_cropper: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
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
```

### AdvancedImageCropper

The main widget for cropping images.

#### Constructor

```dart
AdvancedImageCropper({
Key? key,
required File imageFile,
})
```

#### Parameters

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `imageFile` | `File` | The image file to be cropped | Yes |

#### Methods

The cropper automatically handles the cropping process and returns a `File` object containing the cropped image when the user taps "Done".

### Configuration Options

The cropper comes with several built-in configurations:

- **Maximum Output Dimension**: Images are automatically resized to a maximum of 2000px on the longest side to balance quality and file size
- **Minimum Crop Size**: 80px minimum to ensure usable crop areas
- **Output Format**: PNG format for maximum quality
- **Handle Size**: 32px visual handles with 60px touch areas for better usability

## Customization

### Styling

The cropper uses a modern dark theme with glass-morphism effects. Key styling elements include:

- **Background**: Pure black for maximum contrast
- **Overlay**: Semi-transparent dark overlay on non-crop areas
- **Handles**: White circular handles with shadows and smooth animations
- **Controls**: Glass-effect buttons with backdrop blur
- **App Bar**: Translucent app bar with blur effect

### Behavior

- **Haptic Feedback**: Provides tactile feedback during interactions
- **Smooth Animations**: 150ms duration animations for handle interactions
- **Rotation**: 90-degree increments for precise alignment
- **Constraint System**: Automatic bounds checking and minimum size enforcement

## Performance Considerations

### Memory Management

- Images are properly disposed after use
- Dual-layer rendering reduces memory pressure
- Temporary files are saved to system temp directory

### Optimization Features

- **Progressive Loading**: Low-res preview with high-res overlay
- **Smart Caching**: Optimized cache sizes for different quality levels
- **Efficient Rendering**: Uses Flutter's optimized image rendering pipeline

## Error Handling

The cropper includes comprehensive error handling:

```dart
// Example of handling cropper errors
Future<File?> customCropImage(File imageFile) async {
  final cropped = await Navigator.push<File?>(
    Get.context!,
    MaterialPageRoute(
      builder: (_) => ImageCropperScreen(imageFile: imageFile),
    ),
  );
  return cropped;
}
```

## Requirements

- **Flutter**: SDK >=2.17.0
- **Dart**: >=2.17.0
- **iOS**: 11.0+
- **Android**: API level 21+

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  path_provider: ^2.0.0
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## Support

- 📧 Email: [amankanaa@gmail.com](mailto:amankanaa@gmail.com)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/flutter_advanced_cropper/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/flutter_advanced_cropper/discussions)

## Acknowledgments

- Thanks to the Flutter team for the excellent framework
- Special thanks to contributors and testers

---

**Made with ❤️ for the Flutter community**