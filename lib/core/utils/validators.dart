/// Form and input validators for HabitGuard.
class Validators {
  /// Regular expression for international and local mobile numbers (E.164 and 7-15 digits)
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[0-9]{1,4}?[-. ]?\(?[0-9]{1,4}?\)?[-. ]?[0-9]{1,4}[-. ]?[0-9]{1,9}$',
  );

  /// Strict check: At least 7 to 15 digits total
  static final RegExp _digitsOnlyRegex = RegExp(r'^\d{7,15}$');

  /// Validates Guardian Name
  static String? validateGuardianName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Guardian name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    return null;
  }

  /// Validates Mobile Number
  static String? validateMobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Guardian mobile number is required';
    }

    final sanitized = value.replaceAll(RegExp(r'[\s\-()]'), '');

    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid mobile phone number';
    }

    // Strip leading '+' for digits count check
    final digits = sanitized.startsWith('+') ? sanitized.substring(1) : sanitized;
    if (!_digitsOnlyRegex.hasMatch(digits)) {
      return 'Phone number must contain between 7 and 15 digits';
    }

    return null;
  }

  /// Validates Email address
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Normalizes mobile number to standard E.164 format given a country code
  static String normalizePhoneNumber(String rawNumber, {String defaultCountryCode = '+91'}) {
    var cleaned = rawNumber.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    final prefix = defaultCountryCode.startsWith('+') ? defaultCountryCode : '+$defaultCountryCode';
    return '$prefix$cleaned';
  }
}
