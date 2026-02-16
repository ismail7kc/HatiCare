import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/laboratory_user_provider.dart';

class LaboratoryReportUploadScreen extends StatefulWidget {
  const LaboratoryReportUploadScreen({super.key, required this.prescription});

  final Map<String, dynamic> prescription;

  @override
  State<LaboratoryReportUploadScreen> createState() =>
      _LaboratoryReportUploadScreenState();
}

class _LaboratoryReportUploadScreenState
    extends State<LaboratoryReportUploadScreen> {
  final List<UploadedFile> _uploadedFiles = [];
  final Map<int, TestResultInput> _testResults = {}; // index -> result
  final Map<int, bool> _expandedTests = {}; // index -> expanded state
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final prescriptionId =
        widget.prescription['prescription_id']?.toString() ?? '';
    final patientName =
        widget.prescription['patient_name']?.toString() ?? 'Unknown';
    final labTests = widget.prescription['lab_tests'] as List<dynamic>? ?? [];

    final hasData =
        _testResults.values.any((r) => r.value.isNotEmpty) ||
        _uploadedFiles.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Test Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prescription Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.science_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prescription #$prescriptionId',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                patientName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tests Section
                  const Text(
                    'Lab Tests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap on each test to add results',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Expandable Test Items
                  ...labTests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final test = entry.value;
                    return _buildExpandableTestItem(index, test);
                  }),

                  const SizedBox(height: 24),

                  // File Upload Section
                  const Text(
                    'Supporting Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload images or PDF files (optional)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Upload Area
                  GestureDetector(
                    onTap: _showUploadOptions,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to upload files',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Images or PDFs',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Uploaded Files List
                  if (_uploadedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ..._uploadedFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return _buildFileItem(file, index);
                    }),
                  ],

                  const SizedBox(height: 100), // Space for submit button
                ],
              ),
            ),
          ),

          // Submit Button
          if (hasData)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _submitReports,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit Reports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableTestItem(int index, Map<String, dynamic> test) {
    final testName = test['name']?.toString() ?? 'Unknown Test';
    final unit = test['unit']?.toString() ?? '';
    final referenceRange = test['reference_range']?.toString() ?? '';
    final value = test['value']?.toString() ?? '';
    final indicator = test['indicator']?.toString() ?? '';

    final isExpanded = _expandedTests[index] ?? false;
    final hasValue = _testResults[index]?.value.isNotEmpty ?? false;

    // Initialize test result if not exists
    if (!_testResults.containsKey(index)) {
      _testResults[index] = TestResultInput(
        name: testName,
        unit: unit,
        referenceRange: referenceRange,
        value: value,
        indicator: indicator,
      );
    }

    final result = _testResults[index]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey[200]!,
          width: hasValue ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedTests[index] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status Indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hasValue ? Colors.green : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Test Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        if (hasValue) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${result.value} ${result.unit}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Expand Icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Value Input
                  TextField(
                    controller: TextEditingController(text: result.value)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: result.value.length),
                      ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Value *',
                      hintText: 'Enter value',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        result.value = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Unit Input
                  TextField(
                    controller: TextEditingController(text: result.unit)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: result.unit.length),
                      ),
                    decoration: InputDecoration(
                      labelText: 'Unit *',
                      hintText: 'e.g., g/dL, mg/L',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        result.unit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Reference Range Input
                  TextField(
                    controller:
                        TextEditingController(text: result.referenceRange)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: result.referenceRange.length),
                          ),
                    decoration: InputDecoration(
                      labelText: 'Reference Range *',
                      hintText: 'e.g., 12.0 - 16.0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        result.referenceRange = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Indicator Dropdown (Custom with proper anchoring)
                  Builder(
                    builder: (BuildContext dropdownContext) {
                      return GestureDetector(
                        onTap: () async {
                          final RenderBox renderBox =
                              dropdownContext.findRenderObject() as RenderBox;
                          final offset = renderBox.localToGlobal(Offset.zero);
                          final size = renderBox.size;

                          final selected = await showMenu<String>(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              offset.dx,
                              offset.dy + size.height, // Right below the field
                              MediaQuery.of(context).size.width -
                                  offset.dx -
                                  size.width,
                              offset.dy + size.height + 300,
                            ),
                            constraints: BoxConstraints(
                              minWidth: size.width,
                              maxWidth: size.width,
                            ),
                            items: [
                              PopupMenuItem(
                                value: 'low',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      color: Colors.orange,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Low'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'normal',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Normal'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'high',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('High'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'positive',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Positive'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'negative',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.remove_circle,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Negative'),
                                  ],
                                ),
                              ),
                            ],
                            elevation: 8,
                          );

                          if (selected != null) {
                            setState(() {
                              result.indicator = selected;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    result.indicator == 'low'
                                        ? Icons.arrow_downward
                                        : result.indicator == 'high'
                                        ? Icons.arrow_upward
                                        : result.indicator == 'positive'
                                        ? Icons.add_circle
                                        : result.indicator == 'negative'
                                        ? Icons.remove_circle
                                        : Icons.check_circle,
                                    color: result.indicator == 'low'
                                        ? Colors.orange
                                        : result.indicator == 'high'
                                        ? Colors.red
                                        : result.indicator == 'positive'
                                        ? Colors.blue
                                        : result.indicator == 'negative'
                                        ? Colors.grey
                                        : Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    result.indicator == 'low'
                                        ? 'Low'
                                        : result.indicator == 'high'
                                        ? 'High'
                                        : result.indicator == 'positive'
                                        ? 'Positive'
                                        : result.indicator == 'negative'
                                        ? 'Negative'
                                        : 'Normal',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileItem(UploadedFile file, int index) {
    final isImage = file.type == UploadedFileType.image;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // File icon/preview
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isImage
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(file.path), fit: BoxFit.cover),
                  )
                : Icon(Icons.picture_as_pdf, color: Colors.red[700], size: 24),
          ),
          const SizedBox(width: 12),

          // File name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isImage ? 'Image' : 'PDF Document',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () => _removeFile(index),
            icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload Files',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImages();
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
              title: const Text('Select PDF Files'),
              onTap: () {
                Navigator.pop(context);
                _pickPDFs();
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _uploadedFiles.add(
            UploadedFile(
              name: image.name,
              path: image.path,
              type: UploadedFileType.image,
            ),
          );
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _uploadedFiles.add(
                UploadedFile(
                  name: file.name,
                  path: file.path!,
                  type: UploadedFileType.image,
                ),
              );
            }
          }
        });
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _pickPDFs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _uploadedFiles.add(
                UploadedFile(
                  name: file.name,
                  path: file.path!,
                  type: UploadedFileType.pdf,
                ),
              );
            }
          }
        });
      }
    } catch (e) {
      _showError('Failed to pick PDFs: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
    });
  }

  Future<void> _submitReports() async {
    // Try status_id first (used by API), fallback to prescription_id
    final statusId = widget.prescription['lab_status_id']?.toString() ?? '';
    // final prescriptionId =
    //     widget.prescription['prescription_id']?.toString() ?? '';

    // final idToUse = statusId.isNotEmpty ? statusId : prescriptionId;

    // if (idToUse.isEmpty) {
    //   _showError('Invalid prescription ID. Please try again.');
    //   debugPrint('Prescription data: ${widget.prescription}');
    //   return;
    // }

    // Collect filled test results
    final filledResults = <Map<String, dynamic>>[];
    for (var result in _testResults.values) {
      if (result.value.isNotEmpty) {
        filledResults.add(result.toJson());
      }
    }

    if (filledResults.isEmpty && _uploadedFiles.isEmpty) {
      _showError('Please add at least one test result or file');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final files = _uploadedFiles.map((f) => File(f.path)).toList();
    final provider = context.read<LaboratoryUserProvider>();

    debugPrint('statusID $statusId');
    debugPrint('files $files');
    debugPrint('filled Result is here $filledResults');

    final success = await provider.uploadReport(
      statusId,
      files,
      labResults: filledResults.isNotEmpty ? filledResults : null,
    );

    if (!mounted) return;

    // Hide loading indicator
    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reports submitted successfully!'),
          backgroundColor: Colors.green[700],
        ),
      );
      // Navigate back
      Navigator.pop(context);
    } else {
      _showError(provider.errorMessage ?? 'Failed to submit reports');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }
}

enum UploadedFileType { image, pdf }

class UploadedFile {
  final String name;
  final String path;
  final UploadedFileType type;

  UploadedFile({required this.name, required this.path, required this.type});
}

class TestResultInput {
  final String name;
  String unit;
  String referenceRange;
  String value;
  String indicator;

  TestResultInput({
    required this.name,
    required this.unit,
    required this.referenceRange,
    required this.value,
    required this.indicator,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'reference_range': referenceRange,
      'indicator': indicator,
    };
  }
}
