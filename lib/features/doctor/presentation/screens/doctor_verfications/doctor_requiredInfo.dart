import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';
import 'package:haticare/features/doctor/presentation/screens/edit_profile_screen.dart';
import 'package:haticare/features/doctor/presentation/viewModel/edit_viewModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';

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

  final List<String> licenseTypes = ["CDLs", "IDP"];

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
      licenseNumberController.text = prefs.getString('licenseNumber_$doctorId') ?? '';
      yearsExperienceController.text = prefs.getString('yearsExperience_$doctorId') ?? '';
      licenseAuthorityController.text = prefs.getString('licenseAuthority_$doctorId') ?? '';
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

  Future<void> _onSavePressed() async {
    if (!_areAllFieldsFilled()) {
      _showError("Please fill all fields correctly");
      return;
    }

    final response = await editViewModel.updateDoctorInfo();

    if (response['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await SaveLoginResponse.loadLoginModel();
      final doctorId = SaveLoginResponse.loginData?['id']?.toString() ?? '';

      if (doctorId.isNotEmpty) {
        await prefs.setString('licenseNumber_$doctorId', licenseNumberController.text);
        await prefs.setString('yearsExperience_$doctorId', yearsExperienceController.text);
        await prefs.setString('licenseAuthority_$doctorId', licenseAuthorityController.text);
        await prefs.setString('licenseType_$doctorId', selectedLicenseType!);
        await prefs.setString('specialization_$doctorId', selectedSpecialization!);
        await prefs.setBool('isRequiredInfoFilled_$doctorId', true);
      }

      Navigator.pop(context, true);
    } else {
      showErrorDialog(
        context,
        response['message'] ?? "Something went wrong. Please try again.",
      );
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
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Doctor Required Info",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  "License Number",
                  controller: licenseNumberController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 18),

                _buildDropdownField(
                  label: "License Type",
                  items: licenseTypes,
                  value: selectedLicenseType,
                  onChanged: _onLicenseTypeChanged,
                ),
                const SizedBox(height: 18),

                _buildTextField(
                  "Years of Experience",
                  controller: yearsExperienceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    NoZeroInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Required";
                    final value = int.tryParse(v.trim());
                    if (value == null || value <= 0 || value > 99) {
                      return "Enter a value between 1 and 99";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                _buildDropdownField(
                  label: "Specialization",
                  items: editViewModel.specializationNames,
                  value: selectedSpecialization,
                  onChanged: _onSpecializationChanged,
                ),
                const SizedBox(height: 18),

                _buildTextField(
                  "License Issuing Authority",
                  controller: licenseAuthorityController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9\s.,-]'),
                    ),
                    LengthLimitingTextInputFormatter(40),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "License Authority is required.";
                    }
                    if (v.trim().length < 3) {
                      return "Authority name is too short.";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                ValueListenableBuilder<bool>(
                  valueListenable: isFormComplete,
                  builder: (context, isEnabled, _) {
                    return Opacity(
                      opacity: isEnabled ? 1.0 : 0.4,
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: isEnabled
                              ? AppColors.primaryGradient
                              : const LinearGradient(
                                  colors: [Colors.grey, Colors.grey],
                                ),
                        ),
                        child: TextButton(
                          onPressed: isEnabled ? _onSavePressed : null,
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
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

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _inputDecoration(),
          child: TextFormField(
            controller: controller,
            validator: validator,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: _inputDecoration(),
          child: DropdownButton<String>(
            value: value,
            hint: const Text("Select"),
            isExpanded: true,
            underline: const SizedBox(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
    );
  }

  TextStyle _labelStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.black54,
    );
  }
}
