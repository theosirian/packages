// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    swiftOut:
        'darwin/local_auth_darwin/Sources/local_auth_darwin/messages.g.swift',
    copyrightHeader: 'pigeons/copyright.txt',
  ),
)
/// Pigeon version of IOSAuthMessages, plus the authorization reason.
///
/// See auth_messages_ios.dart for details.
class AuthStrings {
  /// Constructs a new instance.
  const AuthStrings({
    required this.reason,
    required this.cancelButton,
    required this.localizedFallbackTitle,
  });

  final String reason;
  final String cancelButton;
  final String? localizedFallbackTitle;
}

/// Possible outcomes of an authentication attempt.
enum AuthResult {
  /// The user authenticated successfully.
  success,

  /// The user authenticated successfully, and biometric checking was true.
  successValidated,

  /// The user authenticated successfully, and biometric checking was false.
  successInvalidated,

  /// The user failed to successfully authenticate.
  failure,

  /// Native UI needed to be displayed, but couldn't be.
  uiUnavailable,

  // LAError codes; see
  // https://developer.apple.com/documentation/localauthentication/laerror-swift.struct/code
  appCancel,
  systemCancel,
  userCancel,
  biometryDisconnected,
  biometryLockout,
  biometryNotAvailable,
  biometryNotEnrolled,
  biometryNotPaired,
  authenticationFailed,
  invalidContext,
  invalidDimensions,
  notInteractive,
  passcodeNotSet,
  userFallback,

  /// An error other than the expected types occurred.
  unknownError,

  /// No biometrics are enrolled.
  errorNotEnrolled,

  /// No passcode is set.
  errorPasscodeNotSet,

  /// Biometric checking failed.
  errorBiometricChecking,
}

class AuthOptions {
  AuthOptions(
      {required this.biometricOnly,
      required this.sticky,
      this.checkBiometricInvalidationForKey = false});
  final bool biometricOnly;
  final bool sticky;
  final bool checkBiometricInvalidationForKey;
}

class AuthResultDetails {
  AuthResultDetails({
    required this.result,
    this.errorMessage,
    this.errorDetails,
  });

  /// The result of authenticating.
  final AuthResult result;

  /// A system-provided error message, if any.
  final String? errorMessage;

  /// System-provided error details, if any.
  final String? errorDetails;
}

/// Pigeon equivalent of the subset of BiometricType used by iOS.
enum AuthBiometric { face, fingerprint }

@HostApi()
abstract class LocalAuthApi {
  /// Returns true if this device supports authentication.
  bool isDeviceSupported();

  /// Returns true if this device can support biometric authentication, whether
  /// any biometrics are enrolled or not.
  bool deviceCanSupportBiometrics();

  /// Returns the biometric types that are enrolled, and can thus be used
  /// without additional setup.
  List<AuthBiometric> getEnrolledBiometrics();

  /// Attempts to authenticate the user with the provided [options], and using
  /// [strings] for any UI.
  @async
  AuthResultDetails authenticate(AuthOptions options, AuthStrings strings);

  /// Clear biometric checking variables
  void clearBiometricChecking();
}
