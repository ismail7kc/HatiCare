import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';
import 'package:haticare/features/doctor/presentation/viewModel/edit_viewModel.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final EditViewmodel editViewModel;

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController licenseNumberController;
  late TextEditingController yearsExperienceController;
  late TextEditingController licenseAuthorityController;
  late TextEditingController dobController;

  String gender = "Male";
  DateTime? selectedDate = DateTime(1992, 1, 8);
  String? selectedSpecialization;
  String? selectedLicenseType;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();
    final repository = RepositoryLayer(apiClient);
    editViewModel = EditViewmodel(repository);

    SaveDoctorResponse.loadDoctorModel().then((_) {
      final doctor = SaveDoctorResponse.doctorInstance;

      firstNameController = TextEditingController(
        text: SaveLoginResponse.loginData?['first_name'] ?? '',
      );
      lastNameController = TextEditingController(
        text: SaveLoginResponse.loginData?['last_name'] ?? '',
      );
      emailController = TextEditingController(
        text: SaveLoginResponse.loginData?['email'] ?? '',
      );
      phoneController = TextEditingController(
        text: SaveLoginResponse.loginData?['phone_number'] ?? '',
      );

      licenseNumberController = TextEditingController(
        text: doctor?.licenseNumber ?? '',
      );
      yearsExperienceController = TextEditingController(
        text: doctor?.yearsOfExperience.toString() ?? '',
      );
      licenseAuthorityController = TextEditingController(
        text: doctor?.licenseIssuingAuthority ?? '',
      );

      gender = (doctor?.gender ?? 'M') == 'M'
          ? 'Male'
          : (doctor?.gender ?? 'F') == 'F'
          ? 'Female'
          : 'Other';

      selectedDate = doctor?.dob ?? DateTime(1992, 1, 8);
      dobController = TextEditingController(
        text: DateFormat('MMM dd, yyyy').format(selectedDate!),
      );

      selectedSpecialization = doctor?.specialization;
      selectedLicenseType = doctor?.licenseType;

      setState(() {});
    });

    editViewModel.fetchSpecialization().then((_) {
      setState(() {});
    });
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Validation Error"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) {
      _showError("Please fill all fields correctly");
      return;
    }

    if (selectedLicenseType == null || selectedLicenseType!.isEmpty) {
      _showError("Please select License Type");
      return;
    }

    if (selectedSpecialization == null || selectedSpecialization!.isEmpty) {
      _showError("Please select Specialization");
      return;
    }

    editViewModel.updateDoctorInstanceFromControllers(
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      email: SaveLoginResponse.loginData?['email'],
      phoneNumber: phoneController.text,
      licenseNumber: licenseNumberController.text,
      licenseType: selectedLicenseType,
      specialization: selectedSpecialization,
      yearsExperience: yearsExperienceController.text,
      licenseAuthority: licenseAuthorityController.text,
      gender: gender,
      dob: selectedDate,
    );

    final response = await editViewModel.updateDoctorInfo();

    if (!context.mounted) return;

    if (response['success'] == true) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Doctor updated successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                PersistentNavBarNavigator.pushNewScreen(
                  context,
                  screen: DoctorHomeScreen(),
                  withNavBar: false,
                  pageTransitionAnimation: PageTransitionAnimation.cupertino,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
          "Edit profile",
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
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "First Name",
                        controller: firstNameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Required";
                          }
                          if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
                            return "Alphabets only";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "Last Name",
                        controller: lastNameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Required";
                          }
                          if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
                            return "Alphabets only";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  "Email",
                  controller: emailController,
                  isEmail: true,
                  validator: (_) => null,
                ),
                const SizedBox(height: 16),

                Text("Phone Number", style: _labelStyle()),
                const SizedBox(height: 6),
                Container(
                  decoration: _inputDecoration(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 0,
                  ),
                  child: IntlPhoneField(
                    controller: phoneController,
                    initialCountryCode: "US",
                    showDropdownIcon: true,
                    dropdownIconPosition: IconPosition.trailing,
                    flagsButtonMargin: const EdgeInsets.only(right: 8),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Phone Number",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (phone) {
                      phoneController.text = phone.number;
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return "Phone number is required";
                      }

                      final nationalNumber = phone.number.replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      final country = phone.countryISOCode;

                      if (country == "US") {
                        if (!RegExp(
                          r'^[2-9]\d{2}[2-9]\d{2}\d{4}$',
                        ).hasMatch(nationalNumber)) {
                          return "Enter a valid US phone number (10 digits)";
                        }
                      } else if (country == "NG") {
                        if (!RegExp(r'^[789]\d{9}$').hasMatch(nationalNumber)) {
                          return "Enter a valid Nigerian number (10 digits)";
                        }
                      } else {
                        return "Unsupported country";
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Text("Date of Birth", style: _labelStyle()),
                const SizedBox(height: 6),
                TextFormField(
                  controller: dobController,
                  decoration: InputDecoration(
                    hintText: 'Select Date',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFE6E6E6),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFE6E6E6),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFE6E6E6),
                        width: 1,
                      ),
                    ),
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey,
                    ),
                  ),
                  readOnly: false,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                        dobController.text = DateFormat(
                          'MMM dd, yyyy',
                        ).format(picked);
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Date of Birth is required";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                Text("Gender", style: _labelStyle()),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildGenderOption("Male"),
                    _buildGenderOption("Female"),
                    _buildGenderOption("Other"),
                  ],
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  "License Number",
                  controller: licenseNumberController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                _buildDropdownField(
                  label: "License Type",
                  items: ["CDLs", "IDP"],
                  value: selectedLicenseType,
                  onChanged: (val) => setState(() => selectedLicenseType = val),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "Years of Experience",
                        controller: yearsExperienceController,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        label: "Specialization",
                        items: editViewModel.specializationNames,
                        value: selectedSpecialization,
                        onChanged: (val) =>
                            setState(() => selectedSpecialization = val),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  "License Issuing Authority",
                  controller: licenseAuthorityController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Required" : null,
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: TextButton(
                    onPressed: _onSavePressed,
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    bool isEmail = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: isEmail,
          enabled: !isEmail,
          validator: validator,
          decoration: InputDecoration(
            hintText: label,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
            ),
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
            isExpanded: true,
            value: items.contains(value) ? value : null,
            hint: const Text('Select'),
            underline: const SizedBox(),
            items: items.map((name) {
              return DropdownMenuItem<String>(value: name, child: Text(name));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: gender,
          onChanged: (val) => setState(() => gender = val!),
          activeColor: const Color(0xFF1F2F98),
        ),
        Text(value),
        const SizedBox(width: 8),
      ],
    );
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      borderRadius: BorderRadius.circular(10),
    );
  }

  TextStyle _labelStyle() {
    return const TextStyle(
      fontSize: 14,
      color: Colors.black54,
      fontWeight: FontWeight.w500,
    );
  }
}
