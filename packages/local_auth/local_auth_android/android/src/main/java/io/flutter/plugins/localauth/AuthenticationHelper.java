// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.localauth;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.DialogInterface.OnClickListener;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyPermanentlyInvalidatedException;
import android.security.keystore.KeyProperties;
import android.util.Log;
import android.view.ContextThemeWrapper;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import io.flutter.plugins.localauth.Messages.AuthResult;
import io.flutter.plugins.localauth.Messages.AuthResultCode;

import java.io.IOException;
import java.nio.charset.Charset;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.Executor;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.KeyGenerator;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;

/**
 * Authenticates the user with biometrics and sends corresponding response back to Flutter.
 *
 * <p>One instance per call is generated to ensure readable separation of executable paths across
 * method calls.
 */
class AuthenticationHelper extends BiometricPrompt.AuthenticationCallback
        implements Application.ActivityLifecycleCallbacks, DefaultLifecycleObserver {
    /**
     * The callback that handles the result of this authentication process.
     */
    interface AuthCompletionHandler {
        /**
         * Called when authentication attempt is complete.
         */
        void complete(AuthResult authResult);
    }

    private final Lifecycle lifecycle;
    private final FragmentActivity activity;
    private final AuthCompletionHandler completionHandler;
    private final Messages.AuthStrings strings;
    private final BiometricPrompt.PromptInfo promptInfo;
    private final boolean isAuthSticky;
    private final UiThreadExecutor uiThreadExecutor;
    private boolean activityPaused = false;
    private BiometricPrompt biometricPrompt;
    private final boolean biometricChecking;

    AuthenticationHelper(
            Lifecycle lifecycle,
            FragmentActivity activity,
            @NonNull Messages.AuthOptions options,
            @NonNull Messages.AuthStrings strings,
            @NonNull AuthCompletionHandler completionHandler,
            boolean allowCredentials) {
        this.lifecycle = lifecycle;
        this.activity = activity;
        this.completionHandler = completionHandler;
        this.strings = strings;
        this.isAuthSticky = options.getSticky();
        this.biometricChecking = options.getCheckBiometricInvalidationForKey();
        this.uiThreadExecutor = new UiThreadExecutor();

        BiometricPrompt.PromptInfo.Builder promptBuilder =
                new BiometricPrompt.PromptInfo.Builder()
                        .setDescription(strings.getReason())
                        .setTitle(strings.getSignInTitle())
                        .setSubtitle(strings.getSignInHint())
                        .setConfirmationRequired(options.getSensitiveTransaction());

        int allowedAuthenticators =
                BiometricManager.Authenticators.BIOMETRIC_WEAK
                        | BiometricManager.Authenticators.BIOMETRIC_STRONG;

        if (allowCredentials) {
            allowedAuthenticators |= BiometricManager.Authenticators.DEVICE_CREDENTIAL;
        } else {
            promptBuilder.setNegativeButtonText(strings.getCancelButton());
        }

        promptBuilder.setAllowedAuthenticators(allowedAuthenticators);
        this.promptInfo = promptBuilder.build();
    }

    /**
     * Start the biometric listener.
     */
    @RequiresApi(api = Build.VERSION_CODES.R)
    void authenticate() {
        if (lifecycle != null) {
            lifecycle.addObserver(this);
        } else {
            activity.getApplication().registerActivityLifecycleCallbacks(this);
        }
        biometricPrompt = new BiometricPrompt(activity, uiThreadExecutor, this);
        if (biometricChecking) {
            final Cipher cipher;
            try {
                cipher = prepareBiometricCheck();
            } catch (NoSuchPaddingException | NoSuchAlgorithmException | UnrecoverableKeyException |
                     CertificateException | KeyStoreException | IOException | InvalidKeyException |
                     InvalidAlgorithmParameterException | NoSuchProviderException e) {
                Log.d("BIO_CHECK", "Some Error: " + e);
                completionHandler.complete(
                        new AuthResult.Builder()
                                .setCode(AuthResultCode.ERROR_BIOMETRIC_CHECKING)
                                .setErrorMessage(e.toString()).build());
                stop();
                return;
            }
            if (cipher == null) {
                biometricPrompt.authenticate(promptInfo);
            } else {
                biometricPrompt.authenticate(promptInfo, new BiometricPrompt.CryptoObject(cipher));
            }
        } else {
            biometricPrompt.authenticate(promptInfo);
        }
    }

    /**
     * Cancels the biometric authentication.
     */
    void stopAuthentication() {
        if (biometricPrompt != null) {
            biometricPrompt.cancelAuthentication();
            biometricPrompt = null;
        }
    }

    /**
     * Stops the biometric listener.
     */
    private void stop() {
        if (lifecycle != null) {
            lifecycle.removeObserver(this);
            return;
        }
        activity.getApplication().unregisterActivityLifecycleCallbacks(this);
    }

    @SuppressLint("SwitchIntDef")
    @Override
    public void onAuthenticationError(int errorCode, @NonNull CharSequence errString) {
        AuthResultCode code;
        switch (errorCode) {
            case BiometricPrompt.ERROR_USER_CANCELED:
                code = AuthResultCode.USER_CANCELED;
                break;
            case BiometricPrompt.ERROR_NEGATIVE_BUTTON:
                code = AuthResultCode.NEGATIVE_BUTTON;
                break;
            case BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL:
                code = AuthResultCode.NO_CREDENTIALS;
                break;
            case BiometricPrompt.ERROR_NO_BIOMETRICS:
                code = AuthResultCode.NOT_ENROLLED;
                break;
            case BiometricPrompt.ERROR_HW_UNAVAILABLE:
                code = AuthResultCode.HARDWARE_UNAVAILABLE;
                break;
            case BiometricPrompt.ERROR_HW_NOT_PRESENT:
                code = AuthResultCode.NO_HARDWARE;
                break;
            case BiometricPrompt.ERROR_LOCKOUT:
                code = AuthResultCode.LOCKED_OUT_TEMPORARILY;
                break;
            case BiometricPrompt.ERROR_LOCKOUT_PERMANENT:
                code = AuthResultCode.LOCKED_OUT_PERMANENTLY;
                break;
            case BiometricPrompt.ERROR_CANCELED:
                // If we are doing sticky auth and the activity has been paused,
                // ignore this error. We will start listening again when resumed.
                if (activityPaused && isAuthSticky) {
                    return;
                }
                code = AuthResultCode.SYSTEM_CANCELED;
                break;
            case BiometricPrompt.ERROR_TIMEOUT:
                code = AuthResultCode.TIMEOUT;
                break;
            case BiometricPrompt.ERROR_NO_SPACE:
                code = AuthResultCode.NO_SPACE;
                break;
            case BiometricPrompt.ERROR_SECURITY_UPDATE_REQUIRED:
                code = AuthResultCode.SECURITY_UPDATE_REQUIRED;
                break;
            default:
                code = AuthResultCode.UNKNOWN_ERROR;
                break;
        }
        completionHandler.complete(
                new AuthResult.Builder().setCode(code).setErrorMessage(errString.toString()).build());
        stop();
    }

    public static final String BIOMETRIC_CHECK_KEY = "check-biometrics";

    private static SecretKey getSecretKey() throws KeyStoreException, CertificateException, IOException, NoSuchAlgorithmException, UnrecoverableKeyException {
        final KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);
        return ((SecretKey) keyStore.getKey(BIOMETRIC_CHECK_KEY, null));
    }

    private static boolean keyExists() throws KeyStoreException, CertificateException, IOException, NoSuchAlgorithmException, UnrecoverableKeyException {
        final KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        // Before the keystore can be accessed, it must be loaded.
        keyStore.load(null);
        return keyStore.containsAlias(BIOMETRIC_CHECK_KEY) && keyStore.isKeyEntry(BIOMETRIC_CHECK_KEY);
    }

    @RequiresApi(api = Build.VERSION_CODES.R)
    private static void generateBiometricCheckingKey() throws NoSuchAlgorithmException, NoSuchProviderException, InvalidAlgorithmParameterException {
        final KeyGenerator generator = KeyGenerator
                .getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");

        final KeyGenParameterSpec spec = new KeyGenParameterSpec
                .Builder(BIOMETRIC_CHECK_KEY,
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setUserAuthenticationRequired(true)
                .setInvalidatedByBiometricEnrollment(true)
                .setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                .build();

        generator.init(spec);
        generator.generateKey();
    }

    @Nullable
    @RequiresApi(api = Build.VERSION_CODES.R)
    private Cipher prepareBiometricCheck() throws NoSuchPaddingException, NoSuchAlgorithmException, UnrecoverableKeyException, CertificateException, KeyStoreException, IOException, InvalidKeyException, InvalidAlgorithmParameterException, NoSuchProviderException {
        if (!keyExists()) {
            generateBiometricCheckingKey();
        }
        try {
            final Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            final SecretKey secretKey = getSecretKey();
            cipher.init(Cipher.ENCRYPT_MODE, secretKey);
            return cipher;
        } catch (KeyPermanentlyInvalidatedException e) {
            Log.d("BIO_CHECK", "Key is Invalidated");
            return null;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.R)
    @Override
    public void onAuthenticationSucceeded(@NonNull BiometricPrompt.AuthenticationResult result) {
        if (biometricChecking) {
            if (result.getCryptoObject() == null) {
                completionHandler.complete(new AuthResult.Builder().setCode(AuthResultCode.SUCCESS_INVALIDATED).build());
            } else {
                completionHandler.complete(new AuthResult.Builder().setCode(AuthResultCode.SUCCESS_VALIDATED).build());
            }
        } else {
            completionHandler.complete(new AuthResult.Builder().setCode(AuthResultCode.SUCCESS).build());
        }
        stop();
    }

    @Override
    public void onAuthenticationFailed() {
        // No-op; this is called for incremental failures. Wait for a final
        // resolution via the success or error callbacks.
    }

    /**
     * If the activity is paused, we keep track because biometric dialog simply returns "User
     * cancelled" when the activity is paused.
     */
    @Override
    public void onActivityPaused(Activity ignored) {
        if (isAuthSticky) {
            activityPaused = true;
        }
    }

    @Override
    public void onActivityResumed(Activity ignored) {
        if (isAuthSticky) {
            activityPaused = false;
            final BiometricPrompt prompt = new BiometricPrompt(activity, uiThreadExecutor, this);
            // When activity is resuming, we cannot show the prompt right away. We need to post it to the
            // UI queue.
            uiThreadExecutor.handler.post(() -> prompt.authenticate(promptInfo));
        }
    }

    @Override
    public void onPause(@NonNull LifecycleOwner owner) {
        onActivityPaused(null);
    }

    @Override
    public void onResume(@NonNull LifecycleOwner owner) {
        onActivityResumed(null);
    }

    // Unused methods for activity lifecycle.

    @Override
    public void onActivityCreated(Activity activity, Bundle bundle) {
    }

    @Override
    public void onActivityStarted(Activity activity) {
    }

    @Override
    public void onActivityStopped(Activity activity) {
    }

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle bundle) {
    }

    @Override
    public void onActivityDestroyed(Activity activity) {
    }

    @Override
    public void onDestroy(@NonNull LifecycleOwner owner) {
    }

    @Override
    public void onStop(@NonNull LifecycleOwner owner) {
    }

    @Override
    public void onStart(@NonNull LifecycleOwner owner) {
    }

    @Override
    public void onCreate(@NonNull LifecycleOwner owner) {
    }

    static class UiThreadExecutor implements Executor {
        final Handler handler = new Handler(Looper.getMainLooper());

        @Override
        public void execute(Runnable command) {
            handler.post(command);
        }
    }
}
