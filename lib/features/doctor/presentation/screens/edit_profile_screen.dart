import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';
import 'package:haticare/features/doctor/presentation/viewModel/edit_viewModel.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final EditViewmodel editViewModel;

  String gender = "Male";
  DateTime? selectedDate = DateTime(1992, 1, 8);

  String? licenseNumber;
  String? selectedSpecialization;
  String? selectedLicenseType;
  String? years_Experience;
  String? license_issue_authority;

  @override
  void initState() {
    super.initState();
    SaveLoginResponse.loadLoginModel().then((_) {
      setState(() {});
    });

    final apiClient = ApiClient();
    final repository = RepositoryLayer(apiClient);
    editViewModel = EditViewmodel(repository);
    editViewModel.fetchSpecialization().then((_) {
      setState(() {}); // refreshh dropdown.
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
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
        centerTitle: false,
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
                        SaveLoginResponse.loginData?['first_name'] ?? '',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "Last Name",
                        SaveLoginResponse.loginData?['last_name'] ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  "Email",
                  SaveLoginResponse.loginData?['email'] ?? '',
                ),
                const SizedBox(height: 16),

                // --- Phone Number ---
                _buildTextField(
                  "Phone Number",
                  SaveLoginResponse.loginData?['phone_number'] ?? '',
                ),
                const SizedBox(height: 16),

                Text("Date of Birth", style: _labelStyle()),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: _inputDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null
                              ? DateFormat('MMM dd, yyyy').format(selectedDate!)
                              : 'Select Date',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text("Gender", style: _labelStyle()),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildGenderOption("Male"),
                    _buildGenderOption("Female"),
                    _buildGenderOption("Other"),
                  ],
                ),
                const SizedBox(height: 20),

                _buildTextField("License Number", "$licenseNumber"),
                const SizedBox(height: 16),

                _buildDropdownField("License Type", [
                  "Select Type",
                  "CDLs",
                  "IDP",
                ]),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "Years of Experience",
                        "$years_Experience",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        "Specialization",
                        editViewModel.specializationNames,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildTextField("License Issuing Authority", "00000000000"),
                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: TextButton(
                    onPressed: () async {
                      editViewModel.firstName =
                          SaveLoginResponse.loginData?['first_name'] ?? '';
                      editViewModel.lastName =
                          SaveLoginResponse.loginData?['last_name'] ?? '';
                      editViewModel.email =
                          SaveLoginResponse.loginData?['email'] ?? '';
                      editViewModel.phoneNumber =
                          SaveLoginResponse.loginData?['phone_number'] ?? '';
                          
                      editViewModel.licenseNumber = licenseNumber;
                      editViewModel.licenseType = selectedLicenseType ?? '';
                      editViewModel.specialization = selectedSpecialization ?? '';
                      editViewModel.yearsOfExperience = years_Experience;
                      editViewModel.licenseIssuingAuthority = license_issue_authority;
                      editViewModel.gender = gender;
                      editViewModel.dob = selectedDate;

                      await editViewModel.updateDoctorInfo();
                    },
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

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
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

  Widget _buildDropdownField(String label, List<String> items) {
    final selectedValue = label == "Specialization"
        ? selectedSpecialization
        : selectedLicenseType;

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
            value: selectedValue,
            hint: Text('Select'),
            underline: const SizedBox(),
            items: items.map((name) {
              return DropdownMenuItem<String>(value: name, child: Text(name));
            }).toList(),
            onChanged: items.isEmpty
                ? null
                : (value) {
                    setState(() {
                      if (label == "Specialization") {
                        selectedSpecialization = value;
                      } else if (label == "License Type") {
                        selectedLicenseType = value;
                      }
                    });
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: gender,
          onChanged: (val) {
            setState(() => gender = val!);
          },
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
