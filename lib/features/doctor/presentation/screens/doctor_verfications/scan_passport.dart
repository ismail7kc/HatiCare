import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/api_client.dart';
import 'package:haticare/features/common/repository_layer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_verfications/identify_document.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanPassportScreen extends StatefulWidget {
  final DocumentType? documentType;
  final bool? isFromEditScreen;

  const ScanPassportScreen({
    super.key,
    this.documentType,
    this.isFromEditScreen,
  });

  @override
  State<ScanPassportScreen> createState() => _ScanPassportScreenState();
}

class _ScanPassportScreenState extends State<ScanPassportScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isUploading = false;
  File? _pickedImage;
  late RepositoryLayer repoLayer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    final apiClient = ApiClient();
    final repository = RepositoryLayer(apiClient);
    repoLayer = repository;
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
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }
  }

  Future<void> _uploadImage(File file) async {
    setState(() => _isUploading = true);

    late final Map<String, dynamic> data;

    switch (widget.documentType) {
      case DocumentType.passport:
        data = {"id_type": "passport", "id_document": file};
        break;

      case DocumentType.idCard:
        data = {"id_type": "Id_card", "id_document": file};
        break;

      case DocumentType.driverLicense:
        data = {"id_type": "nursing_license", "id_document": file};
        break;

      case null:
        data = {"license_document": file};
        break;
    }

    try {
      await repoLayer.updateDoctorInfo(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your media has been sent successfully to server'),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed, please try again')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> pickFromGallery() async {
    if (_isUploading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      _pickedImage = file;
      setState(() {});
      await _uploadImage(file);
    }
  }

  Future<void> captureImage() async {
    if (!_cameraController!.value.isInitialized) return;

    final XFile picture = await _cameraController!.takePicture();
    final file = File(picture.path);

    setState(() => _pickedImage = file);
    await _uploadImage(file);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  String get title {
    switch (widget.documentType) {
      case DocumentType.idCard:
        return "Scan your ID card";
      case DocumentType.driverLicense:
        return "Scan your license";
      case DocumentType.passport:
        return "Scan your Passport";
      case null:
        return "Nursing License";
    }
  }

  String get subText {
    switch (widget.documentType) {
      case DocumentType.idCard:
        return "Please scan your ID card";
      case DocumentType.driverLicense:
        return "Please scan your license";
      case DocumentType.passport:
        return "Please scan your Passport";
      case null:
        return "Please scan your nursing license";
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  subText,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 327,
                        height: 301,
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
                          child: _pickedImage != null
                              ? Image.file(
                                  _pickedImage!,
                                  width: 280,
                                  height: 180,
                                  fit: BoxFit.cover,
                                )
                              : (_isCameraReady
                                    ? CameraPreview(_cameraController!)
                                    : Container(
                                        color: Colors.black,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )),
                        ),
                      ),
                      // corners
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
                const SizedBox(height: 40),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.grey),
                          const SizedBox(height: 10),
                          const Text(
                            'Hold the camera still\nMake sure there is enough lighting',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'or',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: 236,
                          height: 45,
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onPressed: _isUploading ? null : pickFromGallery,
                              child: const Text(
                                'Upload from Gallery',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
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
                            onPressed: (_isCameraReady && !_isUploading)
                                ? captureImage
                                : null,
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
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
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
