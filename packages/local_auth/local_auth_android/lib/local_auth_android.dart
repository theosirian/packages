// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:local_auth_platform_interface/types/authentication_result.dart';

import 'src/auth_messages_android.dart';
import 'src/messages.g.dart';

export 'package:local_auth_android/src/auth_messages_android.dart';
export 'package:local_auth_platform_interface/types/auth_messages.dart';
export 'package:local_auth_platform_interface/types/auth_options.dart';
export 'package:local_auth_platform_interface/types/biometric_type.dart';

/// The implementation of [LocalAuthPlatform] for Android.
class LocalAuthAndroid extends LocalAuthPlatform {
  /// Creates a new plugin implementation instance.
  LocalAuthAndroid({@visibleForTesting LocalAuthApi? api})
    : _api = api ?? LocalAuthApi();

  /// Registers this class as the default instance of [LocalAuthPlatform].
  static void registerWith() {
    LocalAuthPlatform.instance = LocalAuthAndroid();
  }

  final LocalAuthApi _api;

  @override
  Future<AuthenticationResult> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    assert(localizedReason.isNotEmpty);
    final AuthResult result = await _api.authenticate(
<<<<<<< HEAD
      AuthOptions(
        biometricOnly: options.biometricOnly,
        sensitiveTransaction: options.sensitiveTransaction,
        sticky: options.stickyAuth,
      ),
      _pigeonStringsFromAuthMessages(localizedReason, authMessages),
    );
    switch (result.code) {
      case AuthResultCode.success:
        return true;
      case AuthResultCode.negativeButton:
      case AuthResultCode.userCanceled:
        // Variants of user cancelation format are not currently distinguished,
        // but could be if there's a use case for it in the future.
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.userCanceled,
        );
      case AuthResultCode.systemCanceled:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.systemCanceled,
        );
      case AuthResultCode.timeout:
        throw const LocalAuthException(code: LocalAuthExceptionCode.timeout);
      case AuthResultCode.alreadyInProgress:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.authInProgress,
        );
      case AuthResultCode.noActivity:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.uiUnavailable,
          description: 'No Activity available.',
        );
      case AuthResultCode.notFragmentActivity:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.uiUnavailable,
          description: 'The current Activity must be a FragmentActivity.',
        );
      case AuthResultCode.noCredentials:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.noCredentialsSet,
        );
      case AuthResultCode.noHardware:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.noBiometricHardware,
        );
      case AuthResultCode.hardwareUnavailable:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable,
        );
      case AuthResultCode.notEnrolled:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.noBiometricsEnrolled,
        );
      case AuthResultCode.lockedOutTemporarily:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.temporaryLockout,
        );
      case AuthResultCode.lockedOutPermanently:
        throw const LocalAuthException(
          code: LocalAuthExceptionCode.biometricLockout,
        );
      case AuthResultCode.noSpace:
        throw LocalAuthException(
          code: LocalAuthExceptionCode.deviceError,
          description: 'Not enough space available: ${result.errorMessage}',
        );
      case AuthResultCode.securityUpdateRequired:
        throw LocalAuthException(
          code: LocalAuthExceptionCode.deviceError,
          description: 'Security update required: ${result.errorMessage}',
        );
      case AuthResultCode.unknownError:
        throw LocalAuthException(
          code: LocalAuthExceptionCode.unknownError,
          description: result.errorMessage,
        );
||||||| parent of bfc81e78e ([local_auth] Add Biometric Checking)
        AuthOptions(
            biometricOnly: options.biometricOnly,
            sensitiveTransaction: options.sensitiveTransaction,
            sticky: options.stickyAuth,
            useErrorDialgs: options.useErrorDialogs),
        _pigeonStringsFromAuthMessages(localizedReason, authMessages));
    // TODO(stuartmorgan): Replace this with structured errors, coordinated
    // across all platform implementations, per
    // https://github.com/flutter/flutter/blob/master/docs/ecosystem/contributing/README.md#platform-exception-handling
    // The PlatformExceptions thrown here are for compatibiilty with the
    // previous Java implementation.
    switch (result) {
      case AuthResult.success:
        return true;
      case AuthResult.failure:
        return false;
      case AuthResult.errorAlreadyInProgress:
        throw PlatformException(
            code: 'auth_in_progress', message: 'Authentication in progress');
      case AuthResult.errorNoActivity:
        throw PlatformException(
            code: 'no_activity',
            message: 'local_auth plugin requires a foreground activity');
      case AuthResult.errorNotFragmentActivity:
        throw PlatformException(
            code: 'no_fragment_activity',
            message:
                'local_auth plugin requires activity to be a FragmentActivity.');
      case AuthResult.errorNotAvailable:
        throw PlatformException(
            code: 'NotAvailable',
            message: 'Security credentials not available.');
      case AuthResult.errorNotEnrolled:
        throw PlatformException(
            code: 'NotEnrolled',
            message: 'No Biometrics enrolled on this device.');
      case AuthResult.errorLockedOutTemporarily:
        throw PlatformException(
            code: 'LockedOut',
            message: 'The operation was canceled because the API is locked out '
                'due to too many attempts. This occurs after 5 failed '
                'attempts, and lasts for 30 seconds.');
      case AuthResult.errorLockedOutPermanently:
        throw PlatformException(
            code: 'PermanentlyLockedOut',
            message: 'The operation was canceled because ERROR_LOCKOUT '
                'occurred too many times. Biometric authentication is disabled '
                'until the user unlocks with strong authentication '
                '(PIN/Pattern/Password)');
=======
        AuthOptions(
            biometricOnly: options.biometricOnly,
            sensitiveTransaction: options.sensitiveTransaction,
            sticky: options.stickyAuth,
            useErrorDialgs: options.useErrorDialogs,
            checkBiometricInvalidationForKey:
                options.checkBiometricInvalidationForKey),
        _pigeonStringsFromAuthMessages(localizedReason, authMessages));
    // TODO(stuartmorgan): Replace this with structured errors, coordinated
    // across all platform implementations, per
    // https://github.com/flutter/flutter/blob/master/docs/ecosystem/contributing/README.md#platform-exception-handling
    // The PlatformExceptions thrown here are for compatibiilty with the
    // previous Java implementation.
    switch (result) {
      case AuthResult.success:
        return AuthenticationResult.Success;
      case AuthResult.successValidated:
        return AuthenticationResult.SuccessValidated;
      case AuthResult.successInvalidated:
        return AuthenticationResult.SuccessInvalidated;
      case AuthResult.failure:
        return AuthenticationResult.Failure;
      case AuthResult.errorAlreadyInProgress:
        throw PlatformException(
            code: 'auth_in_progress', message: 'Authentication in progress');
      case AuthResult.errorNoActivity:
        throw PlatformException(
            code: 'no_activity',
            message: 'local_auth plugin requires a foreground activity');
      case AuthResult.errorNotFragmentActivity:
        throw PlatformException(
            code: 'no_fragment_activity',
            message:
                'local_auth plugin requires activity to be a FragmentActivity.');
      case AuthResult.errorNotAvailable:
        throw PlatformException(
            code: 'NotAvailable',
            message: 'Security credentials not available.');
      case AuthResult.errorNotEnrolled:
        throw PlatformException(
            code: 'NotEnrolled',
            message: 'No Biometrics enrolled on this device.');
      case AuthResult.errorLockedOutTemporarily:
        throw PlatformException(
            code: 'LockedOut',
            message: 'The operation was canceled because the API is locked out '
                'due to too many attempts. This occurs after 5 failed '
                'attempts, and lasts for 30 seconds.');
      case AuthResult.errorLockedOutPermanently:
        throw PlatformException(
            code: 'PermanentlyLockedOut',
            message: 'The operation was canceled because ERROR_LOCKOUT '
                'occurred too many times. Biometric authentication is disabled '
                'until the user unlocks with strong authentication '
                '(PIN/Pattern/Password)');
      case AuthResult.errorBiometricChecking:
        throw PlatformException(
            code: 'BiometricCheckingFailed',
            message: 'The biometric checking step failed');
>>>>>>> bfc81e78e ([local_auth] Add Biometric Checking)
    }
  }

  @override
  Future<bool> deviceSupportsBiometrics() async {
    return _api.deviceCanSupportBiometrics();
  }

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async {
    final List<AuthClassification>? result = await _api.getEnrolledBiometrics();
    if (result == null) {
      throw const LocalAuthException(
        code: LocalAuthExceptionCode.uiUnavailable,
        description: 'No Activity available.',
      );
    }
    return result.map((AuthClassification value) {
      switch (value) {
        case AuthClassification.weak:
          return BiometricType.weak;
        case AuthClassification.strong:
          return BiometricType.strong;
      }
    }).toList();
  }

  @override
  Future<bool> isDeviceSupported() async => _api.isDeviceSupported();

  @override
  Future<bool> stopAuthentication() async => _api.stopAuthentication();

  @override
  Future<void> clearBiometricChecking() async => _api.clearBiometricChecking();

  AuthStrings _pigeonStringsFromAuthMessages(
    String localizedReason,
    Iterable<AuthMessages> messagesList,
  ) {
    AndroidAuthMessages? messages;
    for (final entry in messagesList) {
      if (entry is AndroidAuthMessages) {
        messages = entry;
      }
    }
    return AuthStrings(
      reason: localizedReason,
      signInHint: messages?.signInHint ?? androidSignInHint,
      cancelButton: messages?.cancelButton ?? androidCancelButton,
      signInTitle: messages?.signInTitle ?? androidSignInTitle,
    );
  }
}
