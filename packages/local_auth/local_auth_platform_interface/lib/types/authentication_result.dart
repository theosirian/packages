/// Enumeration for `authenticate` function call result
enum AuthenticationResult {
  /// The authentication was successful, and no biometric checking was done.
  Success,

  /// The authentication was successful, and biometric checking was successful.
  SuccessValidated,

  /// The authentication was successful, and biometric checking was unsuccessful.
  SuccessInvalidated,

  /// The authentication was unsuccessful.
  Failure;

  /// Creates an `AuthenticationResult` object from a boolean value.
  static AuthenticationResult fromBool(bool b) {
    return b ? AuthenticationResult.Success : AuthenticationResult.Failure;
  }

  /// Whether this result has successfully authenticated the user.
  bool isSuccessful() {
    switch (this) {
      case AuthenticationResult.Success:
      case AuthenticationResult.SuccessValidated:
      case AuthenticationResult.SuccessInvalidated:
        return true;
      case AuthenticationResult.Failure:
        return false;
    }
  }

  /// Whether this result has successfully done biometric checking.
  bool? isBiometricValidated() {
    switch (this) {
      case AuthenticationResult.Success:
        return null;
      case AuthenticationResult.SuccessValidated:
        return true;
      case AuthenticationResult.SuccessInvalidated:
      case AuthenticationResult.Failure:
        return false;
    }
  }
}
