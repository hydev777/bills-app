/// Returns true if [email] is non-empty and contains '@' and '.'.
bool isValidEmail(String email) =>
    email.isNotEmpty && email.contains('@') && email.contains('.');
