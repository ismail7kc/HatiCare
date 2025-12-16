import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:haticare/core/theme/app_colors.dart';

class TakeSelfieScreen extends StatefulWidget {
  const TakeSelfieScreen({super.key});

  @override
  State<TakeSelfieScreen> createState() => _TakeSelfieScreenState();
}

class _TakeSelfieScreenState extends State<TakeSelfieScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera found on this device')),
        );
        return;
      }

      CameraDescription selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      if (!mounted) return;

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize camera')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Take a Selfie',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Please make sure there is enough lighting and keep your head straight while taking a photo.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 350,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _isCameraReady
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(3.14159),
                                  child: CameraPreview(_cameraController!),
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      ),

                      _buildCorner(Alignment.topLeft),
                      _buildCorner(Alignment.topRight),
                      _buildCorner(Alignment.bottomLeft),
                      _buildCorner(Alignment.bottomRight),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_isCameraReady || _cameraController == null) return;
                    try {
                      Navigator.pop(context, true);
                    } catch (e) {
                      debugPrint('Capture failed: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to capture image'),
                        ),
                      );
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Capture',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final bool isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final bool isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.black, width: 1)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.black, width: 1)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.black, width: 1)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.black, width: 1)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
