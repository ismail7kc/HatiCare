import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';
import 'package:haticare/features/doctor/presentation/screens/edit_profile_screen.dart';
import 'package:haticare/features/doctor/presentation/viewModel/edit_viewModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/core/widgets/custom_dropdown_dialog.dart';

class DoctorRequiredInfo extends StatefulWidget {
  const DoctorRequiredInfo({super.key});

  @override
  State<DoctorRequiredInfo> createState() => _DoctorRequiredInfoState();
}

class _DoctorRequiredInfoState extends State<DoctorRequiredInfo> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final EditViewmodel editViewModel;
  late final ValueNotifier<bool> isFormComplete = ValueNotifier(false);

  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController licenseAuthorityController =
      TextEditingController();
  final TextEditingController yearsExperienceController =
      TextEditingController();

  String? selectedLicenseType;
  String? selectedSpecialization;
  bool _isSubmitting = false;

  final List<String> licenseTypes = [
    "Permanent medical licenses",
    "Temporary medical license",
    "Locum tenens license",
    "Institutional practice limited license",
    "Faculty license",
    "Residency training license",
    "Fellowship training license"
  ];

  @override
  void initState() {
    super.initState();

    void listener() {
      isFormComplete.value = _areAllFieldsFilled();
    }

    licenseNumberController.addListener(listener);
    yearsExperienceController.addListener(listener);
    licenseAuthorityController.addListener(listener);

    final apiClient = ApiClient();
    final repository = RepositoryLayer(apiClient);
    editViewModel = EditViewmodel(repository);

    _loadDoctorFromPrefs();
    // _loadDoctorFromAPI();

    editViewModel.fetchSpecialization().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadDoctorFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await SaveLoginResponse.loadLoginModel();
    final doctorId = SaveLoginResponse.loginData?['id']?.toString() ?? '';

    if (doctorId.isNotEmpty) {
      licenseNumberController.text =
          prefs.getString('licenseNumber_$doctorId') ?? '';
      yearsExperienceController.text =
          prefs.getString('yearsExperience_$doctorId') ?? '';
      licenseAuthorityController.text =
          prefs.getString('licenseAuthority_$doctorId') ?? '';
      selectedLicenseType = prefs.getString('licenseType_$doctorId');
      selectedSpecialization = prefs.getString('specialization_$doctorId');
    }

    isFormComplete.value = _areAllFieldsFilled();

    if (mounted) setState(() {});
  }

  bool _areAllFieldsFilled() {
    return licenseNumberController.text.isNotEmpty &&
        selectedLicenseType != null &&
        selectedSpecialization != null &&
        yearsExperienceController.text.isNotEmpty &&
        licenseAuthorityController.text.isNotEmpty;
  }

  void _onLicenseTypeChanged(String? val) {
    setState(() => selectedLicenseType = val);
    isFormComplete.value = _areAllFieldsFilled();
  }

  void _onSpecializationChanged(String? val) {
    setState(() => selectedSpecialization = val);
    isFormComplete.value = _areAllFieldsFilled();
  }

  Future<void> _onSubmitPressed() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if all fields are filled
    if (!_areAllFieldsFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      editViewModel.updateDoctorInstanceFromControllers(
        licenseNumber: licenseNumberController.text,
        licenseType: selectedLicenseType,
        specialization: selectedSpecialization,
        yearsExperience: yearsExperienceController.text,
        licenseAuthority: licenseAuthorityController.text,
      );

      final response = await editViewModel.updateDoctorInfo();

      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await SaveLoginResponse.loadLoginModel();
        final doctorId = SaveLoginResponse.loginData?['id']?.toString() ?? '';

        if (doctorId.isNotEmpty) {
          await prefs.setString(
            'licenseNumber_$doctorId',
            licenseNumberController.text,
          );
          await prefs.setString(
            'yearsExperience_$doctorId',
            yearsExperienceController.text,
          );
          await prefs.setString(
            'licenseAuthority_$doctorId',
            licenseAuthorityController.text,
          );
          await prefs.setString('licenseType_$doctorId', selectedLicenseType!);
          await prefs.setString(
            'specialization_$doctorId',
            selectedSpecialization!,
          );
          await prefs.setBool('isRequiredInfoFilled_$doctorId', true);
        }

        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          showErrorDialog(
            context,
            response['message'] ?? "Something went wrong. Please try again.",
          );
        }
      }
    } catch (e) {
      debugPrint("Submit error: $e");
      if (mounted) {
        showErrorDialog(context, "Failed to submit. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Doctor Required Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // License Number
                _buildTextField(
                  label: 'License Number',
                  controller: licenseNumberController,
                  hintText: 'Enter license number',
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'License number is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // License Type Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'License Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: selectedLicenseType ?? '',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Select license type',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primaryDark,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        suffixIcon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[400],
                        ),
                      ),
                      onTap: () async {
                        // Dismiss keyboard first
                        FocusScope.of(context).unfocus();

                        final selected = await showCustomDropdownDialog(
                          context: context,
                          title: 'Select License Type',
                          items: licenseTypes,
                          selectedValue: selectedLicenseType,
                          searchHint: 'Search license type...',
                        );
                        if (selected != null) {
                          setState(() => selectedLicenseType = selected);
                          isFormComplete.value = _areAllFieldsFilled();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Years of Experience
                _buildTextField(
                  label: 'Years of Experience',
                  controller: yearsExperienceController,
                  hintText: 'Enter years of experience',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    NoZeroInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Years of experience is required';
                    final value = int.tryParse(v.trim());
                    if (value == null || value <= 0 || value > 99) {
                      return 'Enter a value between 1 and 99';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Specialization Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Specialization',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: selectedSpecialization ?? '',
                      ),
                      decoration: InputDecoration(
                        hintText: editViewModel.specializationNames.isEmpty
                            ? 'Loading specializations...'
                            : 'Select specialization',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primaryDark,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        suffixIcon: editViewModel.specializationNames.isEmpty
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[400],
                              ),
                      ),
                      onTap: editViewModel.specializationNames.isEmpty
                          ? null
                          : () async {
                              // Dismiss keyboard first
                              FocusScope.of(context).unfocus();

                              debugPrint(
                                'Opening specialization dialog with ${editViewModel.specializationNames.length} items',
                              );
                              final selected = await showCustomDropdownDialog(
                                context: context,
                                title: 'Select Specialization',
                                items: editViewModel.specializationNames,
                                selectedValue: selectedSpecialization,
                                searchHint: 'Search specializations...',
                              );
                              if (selected != null) {
                                setState(
                                  () => selectedSpecialization = selected,
                                );
                                isFormComplete.value = _areAllFieldsFilled();
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // License Issuing Authority
                _buildTextField(
                  label: 'License Issuing Authority',
                  controller: licenseAuthorityController,
                  hintText: 'Enter license issuing authority',
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9\s.,-]'),
                    ),
                    LengthLimitingTextInputFormatter(40),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'License issuing authority is required';
                    }
                    if (v.trim().length < 3) {
                      return 'Authority name is too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSubmitting ? null : _onSubmitPressed,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          autovalidateMode: AutovalidateMode.onUnfocus,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
