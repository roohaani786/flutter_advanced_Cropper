import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'crop_overlay_painter.dart';

class ImageCropperScreen extends StatefulWidget {
  final File imageFile;
  const ImageCropperScreen({super.key, required this.imageFile});

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen>
    with TickerProviderStateMixin {
  bool _isHighResLoaded = false;
  Rect? cropRect;
  bool _cropRectInitialized = false;
  final double _handleSize = 32.0; // Visual handle size
  final double _touchRadius =
      60.0; // Extended touch area for better accessibility
  final double _minCropSize = 80.0;
  double _displayWidth = 0.0;
  double _displayHeight = 0.0;

  // Added for loading indicator
  bool _isProcessing = false;

  // Image dimensions and positioning
  int _originalImageWidth = 0;
  int _originalImageHeight = 0;
  bool _imageDimensionsLoaded =
      false; // Tracks if original image dims are loaded
  double _imageDisplayWidth = 0.0;
  double _imageDisplayHeight = 0.0;
  Offset _imageOffset = Offset.zero;

  // Controls state
  double _rotation = 0.0;
  // Removed: _isFreeform and _aspectRatios variables

  // Animation controllers for smooth handle feedback
  late AnimationController _handleAnimationController;
  late Animation<double> _handleScaleAnimation;
  int _activeHandle = -1; // -1: none, 0: TL, 1: TR, 2: BL, 3: BR

  // Crop interaction state
  bool _isDraggingCrop = false;
  Offset _dragStartPoint = Offset.zero;
  Rect _dragStartRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    // Reset state first to ensure clean initialization for the current imageFile
    _resetImageAndCropState();
    // Load image dimensions (this will then trigger _calculateImageDisplayDimensions)
    _loadImageDimensions();

    _handleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _handleScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _handleAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ImageCropperScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Crucial for re-initializing when the widget's imageFile changes
    // even if it's logically the "same" image but a new File instance.
    if (widget.imageFile.path != oldWidget.imageFile.path) {
      _resetImageAndCropState();
      _loadImageDimensions(); // Reload dimensions for the new image
    }
  }

  @override
  void dispose() {
    _handleAnimationController.dispose();
    super.dispose();
  }

  // Resets all relevant state variables for a fresh image load
  void _resetImageAndCropState() {
    _isHighResLoaded = false;
    cropRect = null; // Forces recalculation of initial cropRect
    _cropRectInitialized = false; // Allows initial cropRect to be set again
    _originalImageWidth = 0;
    _originalImageHeight = 0;
    _imageDimensionsLoaded = false; // Forces _loadImageDimensions to run
    _imageDisplayWidth = 0.0;
    _imageDisplayHeight = 0.0;
    _imageOffset = Offset.zero;
    _rotation = 0.0; // Reset rotation for new image
    _isDraggingCrop = false;
    _activeHandle = -1;
    _dragStartPoint = Offset.zero;
    _dragStartRect = Rect.zero;
    // No setState here, as it will be called by _loadImageDimensions or LayoutBuilder
  }

  Future<void> _loadImageDimensions() async {
    // Only load if not already loaded, or if state was reset
    if (!_imageDimensionsLoaded) {
      try {
        final bytes = await widget.imageFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        _originalImageWidth = image.width;
        _originalImageHeight = image.height;
        _imageDimensionsLoaded = true; // Mark as loaded
        image.dispose();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // Now that original dimensions are known and layout dimensions are set by LayoutBuilder,
              // calculate display dimensions and initial cropRect
              _calculateImageDisplayDimensions();
            });
          }
        });
      } catch (e) {
        debugPrint("Error loading image dimensions: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load image: ${e.toString()}')),
          );
          // Potentially pop the screen or show a different error state
        }
      }
    }
  }

  void _calculateImageDisplayDimensions() {
    // This is called initially by _loadImageDimensions's post-frame callback
    // and on subsequent layout changes by LayoutBuilder.
    if (_displayWidth == 0 || _displayHeight == 0 || !_imageDimensionsLoaded) {
      return; // Not ready to calculate yet
    }

    final imageAspectRatio = _originalImageWidth / _originalImageHeight;
    final displayAspectRatio = _displayWidth / _displayHeight;

    if (imageAspectRatio > displayAspectRatio) {
      _imageDisplayWidth = _displayWidth;
      _imageDisplayHeight = _displayWidth / imageAspectRatio;
      _imageOffset = Offset(0, (_displayHeight - _imageDisplayHeight) / 2);
    } else {
      _imageDisplayHeight = _displayHeight;
      _imageDisplayWidth = _displayHeight * imageAspectRatio;
      _imageOffset = Offset((_displayWidth - _imageDisplayWidth) / 2, 0);
    }

    // Only set initial cropRect if it hasn't been done for this image
    if (!_cropRectInitialized) {
      final cropSize = math.min(_imageDisplayWidth, _imageDisplayHeight) * 0.7;
      final centerX = _imageOffset.dx + _imageDisplayWidth / 2;
      final centerY = _imageOffset.dy + _imageDisplayHeight / 2;

      cropRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: cropSize,
        height: cropSize,
      );
      _cropRectInitialized = true;
      // setState will be called by the addPostFrameCallback in _loadImageDimensions
      // or by LayoutBuilder if this is a subsequent layout change
    }
  }

  Rect _constrainCropRect(Rect rect) {
    // Constrain to image bounds
    final imageBounds = Rect.fromLTWH(
      _imageOffset.dx,
      _imageOffset.dy,
      _imageDisplayWidth,
      _imageDisplayHeight,
    );

    // Apply main image bounds first
    Rect constrainedRect = Rect.fromLTRB(
      math.max(rect.left, imageBounds.left),
      math.max(rect.top, imageBounds.top),
      math.min(rect.right, imageBounds.right),
      math.min(rect.bottom, imageBounds.bottom),
    );

    // Ensure minimum size
    final minSize = _minCropSize;
    if (constrainedRect.width < minSize || constrainedRect.height < minSize) {
      // If either dimension is too small, expand to minSize, maintaining aspect if possible
      final newWidth = math.max(constrainedRect.width, minSize);
      final newHeight = math.max(constrainedRect.height, minSize);

      // Adjust to keep it centered as much as possible if expanding
      constrainedRect = Rect.fromCenter(
        center: constrainedRect.center,
        width: newWidth,
        height: newHeight,
      ).intersect(imageBounds); // Re-intersect with image bounds
    }

    return constrainedRect;
  }

  void _onHandlePanStart(int handleIndex, DragStartDetails details) {
    setState(() {
      _isDraggingCrop = true;
      _activeHandle = handleIndex;
      _dragStartPoint = details.globalPosition;
      _dragStartRect = cropRect!;
    });

    HapticFeedback.selectionClick();
    _handleAnimationController.forward();
  }

  void _onHandlePanUpdate(int handleIndex, DragUpdateDetails details) {
    if (!_isDraggingCrop) return;

    setState(() {
      final delta = details.globalPosition - _dragStartPoint;
      Rect newRect = _dragStartRect;

      switch (handleIndex) {
        case 0: // Top-left
          newRect = Rect.fromLTRB(
            _dragStartRect.left + delta.dx,
            _dragStartRect.top + delta.dy,
            _dragStartRect.right,
            _dragStartRect.bottom,
          );
          break;
        case 1: // Top-right
          newRect = Rect.fromLTRB(
            _dragStartRect.left,
            _dragStartRect.top + delta.dy,
            _dragStartRect.right + delta.dx,
            _dragStartRect.bottom,
          );
          break;
        case 2: // Bottom-left
          newRect = Rect.fromLTRB(
            _dragStartRect.left + delta.dx,
            _dragStartRect.top,
            _dragStartRect.right,
            _dragStartRect.bottom + delta.dy,
          );
          break;
        case 3: // Bottom-right
          newRect = Rect.fromLTRB(
            _dragStartRect.left,
            _dragStartRect.top,
            _dragStartRect.right + delta.dx,
            _dragStartRect.bottom + delta.dy,
          );
          break;
      }
      cropRect = _constrainCropRect(newRect);
    });
  }

  void _onHandlePanEnd(int handleIndex, DragEndDetails details) {
    setState(() {
      _isDraggingCrop = false;
      _activeHandle = -1;
    });

    _handleAnimationController.reverse();
    HapticFeedback.lightImpact();
  }

  Future<void> _cropAndReturn() async {
    if (cropRect == null ||
        !_imageDimensionsLoaded ||
        _imageDisplayWidth == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image not ready or no crop area selected.'),
        ),
      );
      return;
    }

    // --- FIX: Defer setState to avoid "called during build" error ---
    // This ensures the current build frame completes before a new build is triggered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isProcessing = true; // Show loading indicator
        });
      }
    });

    ui.Image? originalImage;
    ui.Image? croppedImage;
    File? outFile;

    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      originalImage = frame.image;

      final scaleX = _originalImageWidth / _imageDisplayWidth;
      final scaleY = _originalImageHeight / _imageDisplayHeight;

      final cropLeft = ((cropRect!.left - _imageOffset.dx) * scaleX);
      final cropTop = ((cropRect!.top - _imageOffset.dy) * scaleY);
      final cropWidth = (cropRect!.width * scaleX);
      final cropHeight = (cropRect!.height * scaleY);

      final finalCropRect = Rect.fromLTWH(
        cropLeft.clamp(0.0, _originalImageWidth.toDouble()),
        cropTop.clamp(0.0, _originalImageHeight.toDouble()),
        cropWidth.clamp(1.0, _originalImageWidth.toDouble()),
        cropHeight.clamp(1.0, _originalImageHeight.toDouble()),
      );

      final correctedCropRect = Rect.fromLTWH(
        finalCropRect.left,
        finalCropRect.top,
        math.min(finalCropRect.width, _originalImageWidth - finalCropRect.left),
        math.min(
          finalCropRect.height,
          _originalImageHeight - finalCropRect.top,
        ),
      );

      const double maxOutputDimension = 2000.0;

      double targetWidth = correctedCropRect.width;
      double targetHeight = correctedCropRect.height;

      if (targetWidth > maxOutputDimension ||
          targetHeight > maxOutputDimension) {
        final double aspectRatio = targetWidth / targetHeight;
        if (targetWidth > targetHeight) {
          targetWidth = maxOutputDimension;
          targetHeight = targetWidth / aspectRatio;
        } else {
          targetHeight = maxOutputDimension;
          targetWidth = targetHeight * aspectRatio;
        }
      }

      final outputWidth = targetWidth.toInt();
      final outputHeight = targetHeight.toInt();

      if (outputWidth <= 0 || outputHeight <= 0) {
        throw Exception(
          'Invalid crop area selected. Please select a larger area.',
        );
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint =
          Paint()
            ..isAntiAlias = true
            ..filterQuality = FilterQuality.high;

      if (_rotation != 0) {
        canvas.translate(outputWidth / 2.0, outputHeight / 2.0);
        canvas.rotate(_rotation);
        canvas.translate(-outputWidth / 2.0, -outputHeight / 2.0);
      }

      canvas.drawImageRect(
        originalImage,
        correctedCropRect,
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
        paint,
      );

      final picture = recorder.endRecording();
      croppedImage = await picture.toImage(outputWidth, outputHeight);

      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final bytesToSave = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${directory.path}/cropped_$timestamp.png';
      outFile = File(outPath);
      await outFile.writeAsBytes(bytesToSave);

      if (mounted) {
        Navigator.pop(context, outFile);
      }
    } catch (e) {
      debugPrint("Error during crop and return: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to crop image: ${e.toString()}')),
        );
      }
    } finally {
      originalImage?.dispose();
      croppedImage?.dispose();
      // Ensure processing state is reset in the next frame as well,
      // in case of errors that might not trigger a rebuild immediately.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: AppBar(
              backgroundColor: Colors.white.withAlpha((0.1 * 255).round()),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.back, color: Colors.white),
              ),
              elevation: 0,
              centerTitle: true,
              title: const Text(
                "Crop Image",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                // TextButton(
                //   onPressed: _cropAndReturn,
                //   child: const Text(
                //     "Done",
                //     style: TextStyle(
                //       color: Colors.white,
                //       fontSize: 16.0,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _displayWidth = constraints.maxWidth;
          _displayHeight = constraints.maxHeight;
          // Calculate display dimensions whenever layout changes
          _calculateImageDisplayDimensions();

          return Stack(
            children: [
              // Display image if dimensions are loaded and calculated
              // This ensures at least the low-res version shows immediately
              if (_imageDimensionsLoaded && _imageDisplayWidth > 0)
                Positioned.fill(
                  child: Transform.rotate(
                    angle: _rotation,
                    child: Stack(
                      children: [
                        // Low-res preview (always visible until high-res loads/fades in)
                        Positioned(
                          left: _imageOffset.dx,
                          top: _imageOffset.dy,
                          child: Image.file(
                            widget.imageFile,
                            width: _imageDisplayWidth,
                            height: _imageDisplayHeight,
                            fit: BoxFit.fill,
                            cacheWidth: 800, // Optimize cache size for low-res
                            cacheHeight: 800,
                            filterQuality: FilterQuality.low,
                          ),
                        ),
                        // High-res overlay (fades in once loaded)
                        Positioned(
                          left: _imageOffset.dx,
                          top: _imageOffset.dy,
                          child: AnimatedOpacity(
                            opacity: _isHighResLoaded ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Image.file(
                              widget.imageFile,
                              width: _imageDisplayWidth,
                              height: _imageDisplayHeight,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium,
                              frameBuilder: (
                                context,
                                child,
                                frame,
                                wasSynchronouslyLoaded,
                              ) {
                                if (frame != null && !_isHighResLoaded) {
                                  // This callback is called after the first frame of the image is available
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(() {
                                        _isHighResLoaded = true;
                                      });
                                    }
                                  });
                                }
                                return child;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else // Show a loading indicator if image dimensions are not yet loaded
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Crop overlay (the dimmed area and border)
              if (cropRect != null)
                IgnorePointer(
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: CropOverlayPainter(
                      cropRect: cropRect!,
                      isDragging: _isDraggingCrop,
                    ),
                  ),
                ),

              // Crop handles with smooth interaction
              if (cropRect != null) ..._buildSmoothCropHandles(),

              // Control buttons (visible only when not dragging)
              if (!_isDraggingCrop) _buildControlButtons(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSmoothCropHandles() {
    return [
      // Top-left handle
      _buildSmoothHandle(0, cropRect!.left, cropRect!.top),
      // Top-right handle
      _buildSmoothHandle(1, cropRect!.right, cropRect!.top),
      // Bottom-left handle
      _buildSmoothHandle(2, cropRect!.left, cropRect!.bottom),
      // Bottom-right handle
      _buildSmoothHandle(3, cropRect!.right, cropRect!.bottom),
    ];
  }

  Widget _buildSmoothHandle(int handleIndex, double x, double y) {
    return Positioned(
      left: x - _touchRadius / 2,
      top: y - _touchRadius / 2,
      child: AnimatedBuilder(
        animation: _handleScaleAnimation,
        builder: (context, child) {
          final scale =
              _activeHandle == handleIndex ? _handleScaleAnimation.value : 1.0;

          return GestureDetector(
            onPanStart: (details) => _onHandlePanStart(handleIndex, details),
            onPanUpdate: (details) => _onHandlePanUpdate(handleIndex, details),
            onPanEnd: (details) => _onHandlePanEnd(handleIndex, details),
            child: Container(
              width: _touchRadius,
              height: _touchRadius,
              color:
                  Colors
                      .transparent, // Extended invisible touch area for easier tapping
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.3 * 255).round()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((0.3 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Adjusted spacing
        children: [
          // Removed Freeform/Aspect Ratio button
          _buildGlassButton(
            icon: Icons.rotate_90_degrees_ccw,
            label: "Rotate",
            onPressed: () {
              setState(() {
                _rotation = (_rotation + math.pi / 2) % (2 * math.pi);
              });
            },
          ),
          // Removed Reset button
          _isProcessing
              ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : _buildGlassButton(
                icon: Icons.check,
                label: "Done",
                onPressed: _cropAndReturn,
              ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withAlpha((0.3 * 255).round()),
                ),
              ),
              child: IconButton(
                icon: Icon(icon, color: Colors.white),
                onPressed: onPressed,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
