import 'package:flutter/material.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';

class PhoneInputWidget extends StatefulWidget {
  final TextEditingController phoneController;

  const PhoneInputWidget({super.key, required this.phoneController});

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  late CountryWithPhoneCode _selectedCountry;
  late LibPhonenumberTextFormatter _formatter;

  @override
  void initState() {
    super.initState();

    _selectedCountry = CountryManager().countries.firstWhere(
      (c) => c.countryCode == 'US',
    );

    _formatter = _buildFormatter(_selectedCountry);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFullFormatting();
      updatePhoneFormat(widget.phoneController.text);
    });
  }

  LibPhonenumberTextFormatter _buildFormatter(CountryWithPhoneCode c) {
    return LibPhonenumberTextFormatter(
      country: c,
      phoneNumberFormat: PhoneNumberFormat.national,
    );
  }

  void updatePhoneFormat(String raw) {
    if (raw.isEmpty) return;

    try {
      final formatted = FlutterLibphonenumber().formatNumberSync(
        raw,
        country: _selectedCountry,
        phoneNumberFormat: PhoneNumberFormat.national,
      );

      widget.phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (_) {}
  }

  void _applyFullFormatting() {
    final text = widget.phoneController.text;
    if (text.isEmpty) return;

    try {
      final formatted = FlutterLibphonenumber().formatNumberSync(
        text,
        country: _selectedCountry,
        phoneNumberFormat: PhoneNumberFormat.national,
      );

      widget.phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (_) {}
  }

  void _changeCountry(CountryWithPhoneCode newCountry) {
    setState(() {
      _selectedCountry = newCountry;
      _formatter = _buildFormatter(newCountry);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFullFormatting();
      updatePhoneFormat(widget.phoneController.text);
    });
  }

  String flag(String code) {
    return code.toUpperCase().codeUnits
        .map((c) => String.fromCharCode(c + 127397))
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Phone Number",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<CountryWithPhoneCode>(
                  value: _selectedCountry,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),

                  selectedItemBuilder: (_) {
                    return CountryManager().countries.map((c) {
                      return Row(
                        children: [
                          Text(flag(c.countryCode),
                              style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 4),
                          Text("+${c.phoneCode}",
                              style: const TextStyle(fontSize: 14)),
                        ],
                      );
                    }).toList();
                  },

                  items: CountryManager().countries.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Text(flag(c.countryCode),
                              style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 4),
                          Text("+${c.phoneCode}",
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),

                  onChanged: (c) {
                    if (c != null) _changeCountry(c);
                  },
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: TextFormField(
                  controller: widget.phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_formatter],
                  onChanged: (value) => updatePhoneFormat(value),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "123-456-7890",
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
