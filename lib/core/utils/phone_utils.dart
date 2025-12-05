import 'package:intl_phone_field/phone_number.dart';

class PhoneUtils {
  static Map<String, String> parsePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return {'countryCode': 'US', 'number': ''};
    }

    // Extract country code
    String countryCode = 'US';
    String number = phoneNumber;

    // Check if number starts with +
    if (phoneNumber.startsWith('+')) {
      // Find the end of country code (usually 1-3 digits)
      for (int i = 4; i >= 1; i--) {
        if (phoneNumber.length > i) {
          String potentialCode = phoneNumber.substring(1, i + 1);
          String remainingNumber = phoneNumber.substring(i + 1);
          
          // Map country codes to ISO codes
          final countryMap = {
            '1': 'US',
            '44': 'GB', 
            '92': 'PK',
            '91': 'IN',
            '86': 'CN',
            '81': 'JP',
            '33': 'FR',
            '49': 'DE',
            '39': 'IT',
            '34': 'ES',
            '61': 'AU',
            '64': 'NZ',
            '27': 'ZA',
            '55': 'BR',
            '52': 'MX',
          };
          
          if (countryMap.containsKey(potentialCode)) {
            countryCode = countryMap[potentialCode]!;
            number = remainingNumber;
            break;
          }
        }
      }
    }

    return {'countryCode': countryCode, 'number': number};
  }

  static String? normalizePhoneNumber(PhoneNumber? phone) {
    if (phone == null) return null;
    final sanitizedCountryCode = phone.countryCode.replaceAll(RegExp(r'[^0-9]'), '');
    final sanitizedPhone = phone.number.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitizedPhone.isEmpty) return null;
    return sanitizedCountryCode.isEmpty
        ? sanitizedPhone
        : '+$sanitizedCountryCode$sanitizedPhone';
  }

  static String normalizeCountryCodeString(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('+') ? trimmed : '+$trimmed';
  }
}
