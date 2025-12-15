import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';
import 'package:haticare/features/doctor/presentation/screens/phone_formatted.dart';
import 'package:haticare/features/doctor/presentation/viewModel/edit_viewModel.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

String countryCodeToEmoji(String countryCode) {
  return countryCode
      .toUpperCase()
      .codeUnits
      .map((c) => String.fromCharCode(c + 127397))
      .join();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final EditViewmodel editViewModel;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  TextEditingController licenseNumberController = TextEditingController();
  TextEditingController yearsExperienceController = TextEditingController();
  TextEditingController licenseAuthorityController = TextEditingController();
  TextEditingController dobController = TextEditingController();

  DateTime? selectedDate;
  String? gender;
  String? selectedSpecialization;
  String? selectedLicenseType;

  late Map<String, dynamic> originalData;

  // String gender = "Male";
  // DateTime? selectedDate = DateTime(1992, 1, 8);
  // String? selectedSpecialization;
  // String? selectedLicenseType;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();
    final repository = RepositoryLayer(apiClient);
    editViewModel = EditViewmodel(repository);

    _loadDoctor();

    originalData = {
      'firstName': SaveLoginResponse.loginData?['first_name'],
      'lastName': SaveLoginResponse.loginData?['last_name'],
      'email': SaveLoginResponse.loginData?['email'],
      'phoneNumber': SaveLoginResponse.loginData?['phone_number'],
    };

    editViewModel.fetchSpecialization().then((_) {
      setState(() {});
    });
  }

  Future<void> _loadDoctor() async {
    try {
      final response = await editViewModel.getSignleDocResponse();
      debugPrint("SINGLE DOCTOR RES: $response");

      if (response['success'] == true) {
        setInitialData();
      } else {
        debugPrint("Error fetching doctor");
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }
  }

  void setInitialData() {
    final doc = editViewModel.doctorInstance;
    if (doc == null) return;

    firstNameController = TextEditingController(text: doc.firstName ?? '');
    lastNameController = TextEditingController(text: doc.lastName ?? '');
    emailController = TextEditingController(text: doc.email ?? '');
    phoneController = TextEditingController(text: doc.phoneNumber ?? '');

    licenseNumberController = TextEditingController(
      text: doc.licenseNumber ?? '',
    );
    yearsExperienceController = TextEditingController(
      text: doc.yearsOfExperience?.toString() ?? '',
    );
    licenseAuthorityController = TextEditingController(
      text: doc.licenseIssuingAuthority ?? '',
    );

    gender = doc.gender == 'M'
        ? 'Male'
        : doc.gender == 'F'
        ? 'Female'
        : 'Other';

    selectedDate = doc.dob ?? DateTime(1992, 1, 8);

    dobController = TextEditingController(
      text: DateFormat('MMM dd, yyyy').format(selectedDate!),
    );

    selectedSpecialization = doc.specialization;
    selectedLicenseType = doc.licenseType;

    setState(() {});
  }

  bool _isDataChanged() {
    return firstNameController.text != originalData['firstName'] ||
        lastNameController.text != originalData['lastName'] ||
        phoneController.text != originalData['phoneNumber'] ||
        licenseNumberController.text != originalData['licenseNumber'] ||
        selectedLicenseType != originalData['licenseType'] ||
        selectedSpecialization != originalData['specialization'] ||
        yearsExperienceController.text != originalData['yearsExperience'] ||
        licenseAuthorityController.text != originalData['licenseAuthority'] ||
        gender != originalData['gender'] ||
        selectedDate != originalData['dob'];
  }

  bool _areAllFieldsFilled() {
    return firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        licenseNumberController.text.isNotEmpty &&
        selectedLicenseType != null &&
        selectedSpecialization != null &&
        yearsExperienceController.text.isNotEmpty &&
        licenseAuthorityController.text.isNotEmpty &&
        gender != null &&
        selectedDate != null;
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
    if (!_areAllFieldsFilled()) {
      _showError("Please fill all fields correctly");
      return;
    }

    if (!_isDataChanged()) {
      _showError("Nothing changed");
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
    } else {
      final errorMessage =
          response['message'] ?? "Something went wrong. Please try again.";
      showErrorDialog(context, errorMessage);
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
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z]'),
                          ),
                        ],
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
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z]'),
                          ),
                        ],
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
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhoneInputWidget(phoneController: phoneController),
                  ],
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

                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    LengthLimitingTextInputFormatter(20),
                  ],

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

                Column(
                  children: [
                    _buildTextField(
                      "Years of Experience",
                      controller: yearsExperienceController,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        NoZeroInputFormatter(),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Required";
                        }
                        final value = int.tryParse(v.trim());
                        if (value == null || value <= 0 || value > 99) {
                          return "Enter a value between 1 and 99";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),
                    _buildDropdownField(
                      label: "Specialization",
                      items: editViewModel.specializationNames,
                      value: selectedSpecialization,
                      onChanged: (val) =>
                          setState(() => selectedSpecialization = val),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  "License Issuing Authority",
                  controller: licenseAuthorityController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
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
    String? Function(String?)? validator,
    bool isEmail = false,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 6),
        Container(
          decoration: _inputDecoration(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextFormField(
            controller: controller,
            validator: validator,
            readOnly: readOnly,
            keyboardType: isEmail
                ? TextInputType.emailAddress
                : TextInputType.text,

            inputFormatters:
                inputFormatters ??
                (isEmail
                    ? [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9@._-]'),
                        ),
                        LengthLimitingTextInputFormatter(50),
                      ]
                    : null),

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

// TO PREVETN NON ZERO VALUE 🥹
class NoZeroInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text == "0" || text == "00") {
      return oldValue;
    }

    if (text.length > 2) {
      return oldValue;
    }

    return newValue;
  }
}
