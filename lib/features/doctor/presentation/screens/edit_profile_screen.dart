import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_dropdown_field.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';
import 'package:haticare/features/doctor/presentation/viewModel/edit_viewModel.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../providers/doctor_user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool isSubmitting = false;
  bool isLoading = true;

  late final EditViewmodel editViewModel;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController licenseTypeController = TextEditingController();
  TextEditingController specializationController = TextEditingController();
  TextEditingController licenseNumberController = TextEditingController();
  TextEditingController yearsExperienceController = TextEditingController();
  TextEditingController licenseAuthorityController = TextEditingController();

  DateTime? selectedDate;
  String? gender;
  String? selectedSpecialization;
  String? selectedLicenseType;
  String? completePhoneNumber;
  String countryCode = 'US';
  String? initialPhoneNumber;

  late Map<String, dynamic> originalData;
  final _formKey = GlobalKey<FormState>();

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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void setInitialData() {
    final doc = editViewModel.doctorInstance;
    if (doc == null) return;

    firstNameController = TextEditingController(text: doc.firstName ?? '');
    lastNameController = TextEditingController(text: doc.lastName ?? '');
    emailController = TextEditingController(text: doc.email ?? '');

    // Parse phone number for IntlPhoneField
    String? phoneNum = doc.phoneNumber;
    if (phoneNum != null && phoneNum.isNotEmpty) {
      // Try to extract country code and number
      // Assuming format like +1234567890 or similar
      if (phoneNum.startsWith('+')) {
        // Extract country code (assuming 1-3 digits after +)
        final match = RegExp(r'^\+(\d{1,3})(.*)').firstMatch(phoneNum);
        if (match != null) {
          String code = match.group(1)!;
          String number = match.group(2)!.replaceAll(RegExp(r'[^\d]'), '');

          // Map common country codes
          if (code == '1') {
            countryCode = 'US';
          } else if (code == '92') {
            countryCode = 'PK';
          } else if (code == '44') {
            countryCode = 'GB';
          } else {
            countryCode = 'US'; // Default
          }

          initialPhoneNumber = number;
          completePhoneNumber = phoneNum;
        } else {
          initialPhoneNumber = phoneNum.replaceAll(RegExp(r'[^\d]'), '');
          completePhoneNumber = phoneNum;
        }
      } else {
        initialPhoneNumber = phoneNum.replaceAll(RegExp(r'[^\d]'), '');
        completePhoneNumber = phoneNum;
      }
    }

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

    genderController = TextEditingController(text: gender);

    selectedDate = doc.dob ?? DateTime(1992, 1, 8);

    dobController = TextEditingController(
      text: DateFormat('MMM dd, yyyy').format(selectedDate!),
    );

    selectedSpecialization = doc.specialization;
    specializationController = TextEditingController(text: selectedSpecialization);

    selectedLicenseType = doc.licenseType;
    licenseTypeController = TextEditingController(text: selectedLicenseType);

    setState(() {});
  }

  bool _isDataChanged() {
    return firstNameController.text != originalData['firstName'] ||
        lastNameController.text != originalData['lastName'] ||
        completePhoneNumber != originalData['phoneNumber'] ||
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
        completePhoneNumber != null &&
        completePhoneNumber!.isNotEmpty &&
        licenseNumberController.text.isNotEmpty &&
        selectedLicenseType != null &&
        selectedSpecialization != null &&
        yearsExperienceController.text.isNotEmpty &&
        licenseAuthorityController.text.isNotEmpty &&
        gender != null &&
        selectedDate != null;
  }

  Future<void> _onSubmitPressed() async {
    if (!_areAllFieldsFilled()) {
      _showSnackBar("Please fill all fields correctly", isError: true);
      return;
    }

    if (!_isDataChanged()) {
      _showSnackBar("Nothing changed", isError: true);
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      editViewModel.updateDoctorInstanceFromControllers(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: SaveLoginResponse.loginData?['email'],
        phoneNumber: completePhoneNumber ?? '',
        licenseNumber: licenseNumberController.text,
        licenseType: selectedLicenseType,
        specialization: selectedSpecialization,
        yearsExperience: yearsExperienceController.text,
        licenseAuthority: licenseAuthorityController.text,
        gender: gender,
        dob: selectedDate,
      );

      final response = await editViewModel.updateDoctorInfo();

      debugPrint('=== UPDATE DOCTOR RESPONSE ===');
      debugPrint('Full Response: $response');
      debugPrint('Success: ${response['success']}');
      debugPrint('Message: ${response['message']}');
      debugPrint('Data: ${response['data']}');
      debugPrint('Status Code: ${response['code']}');
      debugPrint('=============================');

      if (response['success'] == true) {
        final firstName = response['data']['first_name'];
        final lastName = response['data']['last_name'];

        SaveLoginResponse.loginData?['first_name'] = firstName;
        SaveLoginResponse.loginData?['last_name'] = lastName;

        ProfileNotifier.doctorName.value = '$firstName $lastName';

        if (mounted) {
          // Update the provider to refresh doctor data
          context.read<DoctorUserProvider>().updateDoctorName(firstName, lastName);

          _showSnackBar('Doctor profile updated successfully', isError: false);
          
          // Navigate back after a short delay to show the success message
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        final errorMsg = response['message'] ?? "Something went wrong. Please try again.";
        if (mounted) {
          _showSnackBar(errorMsg, isError: true);
        }
      }
    } catch (e) {
      debugPrint("Error updating doctor: $e");
      debugPrint("Stack trace: ${StackTrace.current}");
      if (mounted) {
        _showSnackBar("Something went wrong. Please try again.", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of input fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9FAFB),
          elevation: 0,
          title: const Text(
            'Edit Doctor Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildEditableField(
                        label: "First Name",
                        controller: firstNameController,
                        hintText: "Enter first name",
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
                      child: _buildEditableField(
                        label: "Last Name",
                        controller: lastNameController,
                        hintText: "Enter last name",
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

                _buildNonEditableField(
                  label: "Email",
                  controller: emailController,
                ),
                const SizedBox(height: 16),

                // Phone Number Field using IntlPhoneField
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C7278),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntlPhoneField(
                      initialValue: initialPhoneNumber,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      initialCountryCode: countryCode,
                      showCountryFlag: true,
                      showDropdownIcon: true,
                      dropdownIconPosition: IconPosition.trailing,
                      dropdownIcon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      flagsButtonPadding: const EdgeInsets.only(left: 12, right: 8),
                      onChanged: (phone) {
                        completePhoneNumber = phone.completeNumber;
                      },
                      validator: (value) {
                        if (value == null || value.number.isEmpty) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Gender and Date of Birth in Row
                Row(
                  children: [
                    // Gender Dropdown
                    Expanded(
                      child: AppDropdownField<String>(
                        label: 'Gender',
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        value: gender,
                        onChanged: (value) {
                          setState(() {
                            gender = value;
                            genderController.text = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Gender is required';
                          }
                          return null;
                        },
                        hint: 'Select gender',
                        prefixIcon: const Icon(Icons.person_2_outlined, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date of Birth
                    Expanded(
                      child: AppDropdownField<String>(
                        label: 'Date of Birth',
                        items: const [],
                        value: dobController.text.isEmpty ? null : dobController.text,
                        onChanged: (value) {
                          // This will be handled by onTap
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Date of Birth is required';
                          }
                          return null;
                        },
                        hint: 'Select Date',
                        prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
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
                              dobController.text = DateFormat('MMM dd, yyyy').format(picked);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildEditableField(
                  label: "License Number",
                  controller: licenseNumberController,
                  hintText: "Enter license number",
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Required" : null,
                ),

                const SizedBox(height: 16),

                // License Type Dropdown
                AppDropdownField<String>(
                  label: 'License Type',
                  items: const [
                    DropdownMenuItem(value: 'CDLs', child: Text('CDLs')),
                    DropdownMenuItem(value: 'IDP', child: Text('IDP')),
                  ],
                  value: selectedLicenseType,
                  onChanged: (value) {
                    setState(() {
                      selectedLicenseType = value;
                      licenseTypeController.text = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'License Type is required';
                    }
                    return null;
                  },
                  hint: 'Select license type',
                  prefixIcon: const Icon(Icons.card_membership_outlined, color: AppColors.primary),
                ),

                const SizedBox(height: 16),

                _buildEditableField(
                  label: "Years of Experience",
                  controller: yearsExperienceController,
                  hintText: "Enter years of experience",
                  keyboardType: TextInputType.number,
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

                const SizedBox(height: 16),

                // Specialization Dropdown
                AppDropdownField<String>(
                  label: 'Specialization',
                  items: editViewModel.specializationNames.map((spec) {
                    return DropdownMenuItem(value: spec, child: Text(spec));
                  }).toList(),
                  value: selectedSpecialization,
                  onChanged: (value) {
                    setState(() {
                      selectedSpecialization = value;
                      specializationController.text = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Specialization is required';
                    }
                    return null;
                  },
                  hint: 'Select specialization',
                  prefixIcon: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                ),

                const SizedBox(height: 16),

                _buildEditableField(
                  label: "License Issuing Authority",
                  controller: licenseAuthorityController,
                  hintText: "Enter license issuing authority",
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                    LengthLimitingTextInputFormatter(50),
                  ],
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Required" : null,
                ),

                const SizedBox(height: 24),

                AppPrimaryButton(
                  label: isSubmitting ? "Submitting..." : "Submit",
                  onPressed: isSubmitting ? null : _onSubmitPressed,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6C7278),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNonEditableField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6C7278),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: false,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// TO PREVENT NON ZERO VALUE
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
