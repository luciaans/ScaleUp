import 'package:firebase_core/firebase_core.dart';

/// Firebase app identifiers are public configuration, supplied at build time.
/// Never put a Gemini API key in the Flutter client.
abstract final class FirebaseConfig {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform => FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain.isEmpty ? null : _authDomain,
  );

  static Future<void> initialize() async {
    if (!isConfigured) return;
    try {
      await Firebase.initializeApp(options: currentPlatform);
    } catch (_) {
      // Keep local tracking usable if Firebase is not configured correctly yet.
    }
  }
}
