import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LicenseCaptureScreen extends StatefulWidget {
  static const String routeName = "licenseCaptureScreen";

  const LicenseCaptureScreen({super.key});

  @override
  State<LicenseCaptureScreen> createState() => _LicenseCaptureScreenState();
}

class _LicenseCaptureScreenState extends State<LicenseCaptureScreen>
    with TickerProviderStateMixin {
  // Controllers for animations
  late AnimationController _flipController;
  late AnimationController _pulseController;
  late Animation<double> _flipAnimation;
  late Animation<double> _pulseAnimation;

  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // Captured images
  File? _frontImage;
  File? _backImage;

  // Current side (true = front, false = back)
  bool _isShowingFront = true;
  bool _isCapturing = false;
  bool _showImagePreview = false;
  File? _capturedImagePreview;

  @override
  void initState() {
    super.initState();

    // Initialize flip animation
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    // Initialize pulse animation for capture button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Initialize camera
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        // Use back camera instead of front camera to avoid mirror effect
        final camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras![0],
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // Capture image function
  Future<void> _captureImage() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      final XFile image = await _cameraController!.takePicture();

      // Show image preview for confirmation
      setState(() {
        _capturedImagePreview = File(image.path);
        _showImagePreview = true;
      });
    } catch (e) {
      if (mounted) {
        final lang = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lang.captureError}: $e')),
        );
      }
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  // Confirm captured image
  void _confirmImage() {
    if (_capturedImagePreview != null) {
      setState(() {
        if (_isShowingFront) {
          _frontImage = _capturedImagePreview;
        } else {
          _backImage = _capturedImagePreview;
        }
        _showImagePreview = false;
        _capturedImagePreview = null;
      });

      // Auto flip to back side after capturing front
      if (_isShowingFront && _backImage == null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _flipToBack();
        });
      }
    }
  }

  // Retake image
  void _retakeImage() {
    setState(() {
      _showImagePreview = false;
      _capturedImagePreview = null;
    });
  }

  // Flip to back side
  void _flipToBack() {
    setState(() {
      _isShowingFront = false;
    });
    _flipController.forward();
  }

  // Continue to next step
  void _continueToNext() {
    if (_frontImage != null && _backImage != null) {
      // Pass the images back to the previous screen or continue signup
      Navigator.pop(context, {
        'frontImage': _frontImage,
        'backImage': _backImage,
      });
    } else {
      final lang = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.pleaseCaptureBothSides),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isLight ? Colors.white : const Color(0xFF01122A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, lang, isLight, size),

            // Main content
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Instructions
                  _buildInstructions(context, lang, isLight, size),

                  const SizedBox(height: 30),

                  // License frame
                  Expanded(
                    child: _buildLicenseFrame(context, lang, isLight, size),
                  ),

                  const SizedBox(height: 30),

                  // Controls
                  _buildControls(context, lang, isLight, size),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build header
  Widget _buildHeader(
      BuildContext context, AppLocalizations lang, bool isLight, Size size) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: isLight ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lang.licenseCaptureTitle,
              style: TextStyle(
                fontSize: size.width * 0.055,
                fontWeight: FontWeight.bold,
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
          ),
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isLight ? const Color(0xFF86A5D9) : const Color(0xFF023A87),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${_frontImage != null ? 1 : 0} + ${_backImage != null ? 1 : 0} / 2',
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build instructions
  Widget _buildInstructions(
      BuildContext context, AppLocalizations lang, bool isLight, Size size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFF86A5D9).withOpacity(0.1)
            : const Color(0xFF023A87).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight
              ? const Color(0xFF86A5D9).withOpacity(0.3)
              : const Color(0xFF023A87).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isShowingFront ? Icons.credit_card : Icons.flip_to_back,
            color: isLight ? const Color(0xFF023A87) : const Color(0xFF86A5D9),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isShowingFront
                  ? lang.placeLicenseInFrameFront
                  : lang.flipLicenseAndCaptureBack,
              style: TextStyle(
                fontSize: size.width * 0.04,
                color: isLight ? const Color(0xFF023A87) : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build license frame
  Widget _buildLicenseFrame(
      BuildContext context, AppLocalizations lang, bool isLight, Size size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isShowingFront = _flipAnimation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_flipAnimation.value * 3.14159),
            child: Container(
              width: double.infinity,
              height: size.height * 0.35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLight
                      ? const Color(0xFF86A5D9)
                      : const Color(0xFF023A87),
                  width: 3,
                ),
                color: isLight ? Colors.white : const Color(0xFF01122A),
                boxShadow: [
                  BoxShadow(
                    color: (isLight
                            ? const Color(0xFF86A5D9)
                            : const Color(0xFF023A87))
                        .withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateY(_flipAnimation.value > 0.5 ? 3.14159 : 0),
                  child: Stack(
                    children: [
                      // Background pattern
                      _buildBackgroundPattern(isLight),

                      // License preview
                      if (isShowingFront && _frontImage != null)
                        _buildImagePreview(_frontImage!, isLight)
                      else if (!isShowingFront && _backImage != null)
                        _buildImagePreview(_backImage!, isLight)
                      else
                        _buildPlaceholder(lang, isLight, size, isShowingFront),

                      // Corner guides
                      _buildCornerGuides(isLight),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build background pattern
  Widget _buildBackgroundPattern(bool isLight) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  const Color(0xFF86A5D9).withOpacity(0.05),
                  const Color(0xFF023A87).withOpacity(0.05),
                ]
              : [
                  const Color(0xFF023A87).withOpacity(0.1),
                  const Color(0xFF86A5D9).withOpacity(0.1),
                ],
        ),
      ),
      child: CustomPaint(
        painter: DottedPatternPainter(
          color: (isLight ? const Color(0xFF86A5D9) : const Color(0xFF023A87))
              .withOpacity(0.1),
        ),
        size: Size.infinite,
      ),
    );
  }

  // Build image preview
  Widget _buildImagePreview(File image, bool isLight) {
    final lang = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.1),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  lang.completed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build placeholder
  Widget _buildPlaceholder(
      AppLocalizations lang, bool isLight, Size size, bool isShowingFront) {
    // Show image preview if available
    if (_showImagePreview && _capturedImagePreview != null) {
      return Stack(
        children: [
          // Image preview
          Positioned.fill(
            child: Image.file(
              _capturedImagePreview!,
              fit: BoxFit.cover,
            ),
          ),
          // Confirmation overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Retake button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _retakeImage,
                            icon: const Icon(Icons.refresh),
                            label: Text(lang.retakePhoto),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Confirm button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _confirmImage,
                            icon: const Icon(Icons.check),
                            label: Text(lang.confirm),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Show camera preview if camera is initialized
    if (_isCameraInitialized && _cameraController != null) {
      return Stack(
        children: [
          // Camera preview - using back camera so no mirror needed
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          // Overlay with instructions - this will NOT be mirrored
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateY(_flipAnimation.value > 0.5 ? 3.14159 : 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isShowingFront
                              ? lang.placeLicenseHereFront
                              : lang.placeLicenseHereBack,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show loading or placeholder if camera not ready
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isCameraInitialized)
            const CircularProgressIndicator()
          else
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(
                    isShowingFront ? Icons.credit_card : Icons.flip_to_back,
                    size: size.width * 0.15,
                    color: (isLight
                            ? const Color(0xFF86A5D9)
                            : const Color(0xFF023A87))
                        .withOpacity(0.6),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateY(_flipAnimation.value > 0.5 ? 3.14159 : 0),
            child: Text(
              !_isCameraInitialized
                  ? lang.preparingCamera
                  : isShowingFront
                      ? lang.placeLicenseHereFront
                      : lang.placeLicenseHereBack,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: size.width * 0.04,
                color: (isLight
                        ? const Color(0xFF86A5D9)
                        : const Color(0xFF023A87))
                    .withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build corner guides
  Widget _buildCornerGuides(bool isLight) {
    final color = isLight ? const Color(0xFF86A5D9) : const Color(0xFF023A87);

    return Stack(
      children: [
        // Top left
        Positioned(
          top: 10,
          left: 10,
          child: _buildCornerGuide(color, [
            Alignment.topLeft,
            Alignment.topCenter,
            Alignment.centerLeft,
          ]),
        ),
        // Top right
        Positioned(
          top: 10,
          right: 10,
          child: _buildCornerGuide(color, [
            Alignment.topRight,
            Alignment.topCenter,
            Alignment.centerRight,
          ]),
        ),
        // Bottom left
        Positioned(
          bottom: 10,
          left: 10,
          child: _buildCornerGuide(color, [
            Alignment.bottomLeft,
            Alignment.bottomCenter,
            Alignment.centerLeft,
          ]),
        ),
        // Bottom right
        Positioned(
          bottom: 10,
          right: 10,
          child: _buildCornerGuide(color, [
            Alignment.bottomRight,
            Alignment.bottomCenter,
            Alignment.centerRight,
          ]),
        ),
      ],
    );
  }

  // Build single corner guide
  Widget _buildCornerGuide(Color color, List<Alignment> alignments) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: alignments.contains(Alignment.topLeft) ||
                  alignments.contains(Alignment.topRight) ||
                  alignments.contains(Alignment.topCenter)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          bottom: alignments.contains(Alignment.bottomLeft) ||
                  alignments.contains(Alignment.bottomRight) ||
                  alignments.contains(Alignment.bottomCenter)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          left: alignments.contains(Alignment.topLeft) ||
                  alignments.contains(Alignment.bottomLeft) ||
                  alignments.contains(Alignment.centerLeft)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          right: alignments.contains(Alignment.topRight) ||
                  alignments.contains(Alignment.bottomRight) ||
                  alignments.contains(Alignment.centerRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  // Build controls
  Widget _buildControls(
      BuildContext context, AppLocalizations lang, bool isLight, Size size) {
    // Don't show controls when in preview mode
    if (_showImagePreview) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Flip button (only show if front is captured)
          if (_frontImage != null && _backImage == null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _flipToBack,
                    icon: const Icon(Icons.flip_to_back),
                    label: Text(lang.flipToBack),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLight
                          ? const Color(0xFF86A5D9)
                          : const Color(0xFF023A87),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main action buttons
          Row(
            children: [
              // Retake button
              if ((_isShowingFront && _frontImage != null) ||
                  (!_isShowingFront && _backImage != null))
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_isShowingFront) {
                            _frontImage = null;
                          } else {
                            _backImage = null;
                          }
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(lang.retake),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ),

              // Capture button
              Expanded(
                flex: (_isShowingFront && _frontImage != null) ||
                        (!_isShowingFront && _backImage != null)
                    ? 1
                    : 2,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isCapturing ? 0.95 : 1.0,
                      child: ElevatedButton.icon(
                        onPressed: _isCapturing ? null : _captureImage,
                        icon: _isCapturing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: 24 * _pulseAnimation.value,
                              ),
                        label: Text(
                          _isCapturing
                              ? lang.capturing
                              : (_isShowingFront && _frontImage == null)
                                  ? lang.captureFront
                                  : (!_isShowingFront && _backImage == null)
                                      ? lang.captureBack
                                      : lang.retake,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLight
                              ? const Color(0xFF023A87)
                              : const Color(0xFF86A5D9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Continue button
          if (_frontImage != null && _backImage != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _continueToNext,
                icon: const Icon(Icons.check_circle),
                label: Text(lang.continueNext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for dotted pattern
class DottedPatternPainter extends CustomPainter {
  final Color color;

  DottedPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const dotSize = 2.0;
    const spacing = 20.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
