import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../degree_planning/degree_plan_repository.dart';
import '../schedules/schedule_repository.dart';
import 'user_planning_data_cleanup.dart';

/// Identity only. This does not upload schedules or create a backend session.
class GoogleAuth extends ChangeNotifier {
  GoogleAuth({
    UserPlanningDataCleanup? planningDataCleanup,
    this.signOutIdentity,
  }) : _planningDataCleanup =
           planningDataCleanup ??
           UserPlanningDataCleanup(
             schedules: PreferencesScheduleRepository(),
             degreePlans: PreferencesDegreePlanRepository(),
           );

  static const clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  final _google = GoogleSignIn.instance;
  final UserPlanningDataCleanup _planningDataCleanup;
  final Future<void> Function()? signOutIdentity;
  static Future<void>? _initialization;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  GoogleSignInAccount? user;
  bool _disposed = false;
  bool ready = false;
  bool busy = false;
  String? error;

  bool get supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  bool get configured =>
      supported &&
      (kIsWeb
          ? clientId.isNotEmpty
          : defaultTargetPlatform == TargetPlatform.android
          ? serverClientId.isNotEmpty
          : clientId.isNotEmpty);

  Future<void> initialize() async {
    if (!configured) return;
    try {
      _initialization ??= _google.initialize(
        clientId: clientId.isEmpty ? null : clientId,
        serverClientId: kIsWeb || serverClientId.isEmpty
            ? null
            : serverClientId,
      );
      await _initialization;
      if (_disposed) return;
      _subscription = _google.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) user = event.user;
          if (event is GoogleSignInAuthenticationEventSignOut) user = null;
          error = null;
          notifyListeners();
        },
        onError: (Object e) {
          error = _message(e);
          notifyListeners();
        },
      );
      ready = true;
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  String _message(Object e) =>
      e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled
      ? 'Sign-in canceled. You can try again.'
      : 'Google sign-in could not finish. Check your connection and Google app setup, then try again.';

  Future<void> signIn() async {
    if (!ready || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _google.authenticate();
    } catch (e) {
      error = _message(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> signOut() async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _planningDataCleanup.clear();
    } catch (_) {
      error = 'Could not clear local planning data. You are still signed in; please try again.';
      busy = false;
      notifyListeners();
      return false;
    }
    try {
      await (signOutIdentity ?? _google.signOut)();
      user = null;
      return true;
    } catch (e) {
      error = 'Could not sign out. Your local planning data was cleared.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
