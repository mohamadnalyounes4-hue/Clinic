import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration supplied through --dart-define values.
///
/// Native google-services.json / GoogleService-Info.plist configuration is used
/// automatically when these values are absent.
class AppFirebaseOptions {
  const AppFirebaseOptions._();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.example.nabad',
  );

  static FirebaseOptions? get currentPlatform {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return null;
    }
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final appId = isAndroid ? _androidAppId : _iosAppId;
    if (_apiKey.isEmpty ||
        _projectId.isEmpty ||
        _senderId.isEmpty ||
        appId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      iosBundleId: isAndroid ? null : _iosBundleId,
    );
  }
}
