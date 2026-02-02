import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:image_cropper/image_cropper.dart';
import 'package:haticare/core/utils/document_quality_validator.dart';

class UploadDocumentScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const UploadDocumentScreen({
    super.key,
    this.title = 'Upload License Document',
    this.subtitle = 'Please capture or upload your license document',
  });

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  File? _selectedFile;
  String? selectedFileName;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final permission = await Permission.camera.request();
    if (permission.isGranted) {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = path.basename(file.path);
        final extension = path.extension(file.path).toLowerCase();

        // If it's a PDF, return directly without validation or cropping
        if (extension == '.pdf') {
          if (mounted) {
            Navigator.pop(context, {
              'file': file,
              'fileName': fileName,
            });
          }
          return;
        }

        // Show cropper first for images
        final croppedFile = await _cropImage(file);

        if (croppedFile != null) {
          // Show loading while validating
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          // Validate cropped image quality
          final validationResult = await DocumentQualityValidator.validateDocument(croppedFile);

          // Dismiss loading
          if (mounted) {
            Navigator.pop(context);
          }

          debugPrint('Gallery validation: isValid=${validationResult.isValid}, score=${validationResult.qualityScore}');

          if (!validationResult.isValid) {
            // Show warning but allow user to proceed
            if (mounted) {
              final shouldProceed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Image Quality Warning'),
                  content: Text(validationResult.errorMessage ?? 'Image quality may be poor'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Choose Another'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Use Anyway'),
                    ),
                  ],
                ),
              );

              if (shouldProceed != true) {
                return; // User wants to choose another image
              }
            }
          }

          final croppedFileName = path.basename(croppedFile.path);

          setState(() {
            _selectedFile = croppedFile;
            selectedFileName = croppedFileName;
          });

          // Return the cropped file
          if (mounted) {
            Navigator.pop(context, {
              'file': croppedFile,
              'fileName': croppedFileName,
            });

          }
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile picture = await _cameraController!.takePicture();
      final file = File(picture.path);

      // Show cropper to let user crop the captured image
      final croppedFile = await _cropImage(file);

      if (croppedFile != null) {
        // Show loading while validating
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // Validate cropped image quality
        final validationResult = await DocumentQualityValidator.validateDocument(croppedFile);

        // Dismiss loading
        if (mounted) {
          Navigator.pop(context);
        }

        debugPrint('Validation result: isValid=${validationResult.isValid}, score=${validationResult.qualityScore}');
        debugPrint('hasText=${validationResult.hasText}, isSharp=${validationResult.isSharp}, isWellLit=${validationResult.isWellLit}');

        if (!validationResult.isValid) {
          // Show warning but allow user to proceed or retake
          if (mounted) {
            final shouldProceed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Image Quality Warning'),
                content: Text(validationResult.errorMessage ?? 'Image quality may be poor'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Retake'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Use Anyway'),
                  ),
                ],
              ),
            );

            if (shouldProceed != true) {
              return; // User wants to retake
            }
          }
        }

        // Quality is good or user chose to proceed
        final fileName = path.basename(croppedFile.path);

        setState(() {
          _selectedFile = croppedFile;
          selectedFileName = fileName;
        });

        // Return the cropped file
        if (mounted) {
          Navigator.pop(context, {
            'file': croppedFile,
            'fileName': fileName,
          });
        }
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Document',
            toolbarColor: AppColors.primaryDark,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
          ),
          IOSUiSettings(
            title: 'Crop Document',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    DocumentQualityValidator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive camera preview size - smaller to fit everything
    final cameraWidth = (screenWidth * 0.85).clamp(280.0, 340.0);
    final cameraHeight = (cameraWidth * 0.75).clamp(200.0, 260.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: cameraWidth,
                        height: cameraHeight,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedFile != null
                              ? Image.file(
                                  _selectedFile!,
                                  fit: BoxFit.cover,
                                )
                              : (_isCameraReady
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _cameraController!.value.previewSize!.height,
                                          height: _cameraController!.value.previewSize!.width,
                                          child: CameraPreview(_cameraController!),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.black,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      )),
                        ),
                      ),
                      // Corner borders
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _buildCorner(top: true, left: true),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCorner(top: true, left: false),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _buildCorner(top: false, left: true),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _buildCorner(top: false, left: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                const SizedBox(height: 8),
                const Text(
                  'Hold the camera still\nMake sure there is enough lighting',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'or',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: (screenWidth * 0.65).clamp(220.0, 280.0),
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.primaryLight,
                          width: 2,
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: pickFromGallery,
                        child: const Center(
                          child: Text(
                            'Upload from Gallery',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: screenWidth - 48,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isCameraReady ? captureImage : null,
                        child: const Text(
                          'Capture',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorner({
    bool top = true,
    bool left = true,
    double size = 30,
    double borderWidth = 3,
    double borderRadius = 6,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: top && left ? Radius.circular(borderRadius) : Radius.zero,
          topRight: top && !left ? Radius.circular(borderRadius) : Radius.zero,
          bottomLeft: !top && left
              ? Radius.circular(borderRadius)
              : Radius.zero,
          bottomRight: !top && !left
              ? Radius.circular(borderRadius)
              : Radius.zero,
        ),
        border: Border(
          top: top
              ? BorderSide(color: Colors.blue, width: borderWidth)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: Colors.blue, width: borderWidth)
              : BorderSide.none,
          left: left
              ? BorderSide(color: Colors.blue, width: borderWidth)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: Colors.blue, width: borderWidth)
              : BorderSide.none,
        ),
      ),
    );
  }
}
