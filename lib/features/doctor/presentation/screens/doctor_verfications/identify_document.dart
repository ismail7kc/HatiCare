import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IdentifyDocumentScreen extends StatefulWidget {
  const IdentifyDocumentScreen({super.key});

  @override
  State<IdentifyDocumentScreen> createState() => _IdentifyDocumentScreenState();
}

class _IdentifyDocumentScreenState extends State<IdentifyDocumentScreen> {
  String? _selectedCountry = 'USA';
  final List<String> _countries = ['USA', 'Canada', 'Mexico', 'United Kingdom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
             Navigator.pop(context); 
          },
        ),
        title: const Text(
          'Identify Document',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Select issuing country',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildCountryDropdown(),

            const SizedBox(height: 24),

            const Text(
              'Choose your document type',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildDocumentOption(
              icon: 'assets/icons/passport_alt.svg',
              label: 'Passport',
            ),
            const SizedBox(height: 12),
            _buildDocumentOption(
              icon: 'assets/icons/id_card.svg',
              label: 'ID Card',
            ),
            const SizedBox(height: 12),
            _buildDocumentOption(
              icon: 'assets/icons/id_card.svg',
              label: "Driver's License",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentOption({required String icon, required String label}) {
    return InkWell(
      onTap: () {
        print('$label tapped');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(icon),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCountry,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
        iconSize: 24,
        elevation: 8,
        style: const TextStyle(fontSize: 16, color: Colors.black),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCountry = newValue;
          });
        },
        items: _countries.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        dropdownColor: Colors.white,
      ),
    );
  }
}
