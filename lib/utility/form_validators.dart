class FormValidators {
  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Mobile number is required';
    if (v.length != 10 || !RegExp(r'^\d{10}$').hasMatch(v)) {
      return 'Enter a valid 10-digit number';
    }
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? pincode(String? v) {
    if (v == null || v.isEmpty) return 'Pincode is required';
    if (v.length != 6) return 'Enter a valid 6-digit pincode';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }
}
