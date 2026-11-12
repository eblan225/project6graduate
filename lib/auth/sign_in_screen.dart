import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import 'google_auth.dart';
import 'google_button.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, required this.auth, required this.onGuest});
  final GoogleAuth auth;
  final VoidCallback onGuest;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AppPage(
        children: [
          const SizedBox(height: 64),
          const Icon(Icons.school_outlined, size: 56, color: AppStyle.purple),
          const SizedBox(height: 24),
          const Text(
            'Graduate!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppStyle.purple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your next chapter starts here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          googleButton(
            onPressed: auth.ready && !auth.busy ? auth.signIn : null,
          ),
          if (auth.busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!auth.configured)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Google sign-in is awaiting app setup. You can explore the preview below.',
                textAlign: TextAlign.center,
              ),
            ),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                auth.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: auth.busy ? null : onGuest,
            child: const Text('Explore without signing in'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Google shares your basic profile and email to sign you in. Schedules are saved on this device; goals remain in this session. Cloud sync is not connected yet.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5, color: Color(0xFF767085)),
          ),
        ],
      ),
    ),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final auth = GoogleAuth();
  bool guest = false;
  @override
  void initState() {
    super.initState();
    auth.initialize();
  }

  @override
  void dispose() {
    auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (context, _) {
      if (!guest && auth.user == null) {
        return SignInScreen(
          auth: auth,
          onGuest: () => setState(() => guest = true),
        );
      }
      return Column(
        children: [
          SafeArea(
            bottom: false,
            child: Material(
              color: Colors.white,
              child: ListTile(
                leading: Icon(
                  guest ? Icons.person_outline : Icons.account_circle_outlined,
                ),
                title: Text(
                  guest
                      ? 'Guest preview'
                      : auth.user!.displayName ?? 'Google account',
                ),
                subtitle: guest ? null : Text(auth.user!.email),
                trailing: TextButton(
                  onPressed: auth.busy
                      ? null
                      : () async {
                          // Guest session goals reset when the app returns to this gate.
                          if (guest) {
                            setState(() => guest = false);
                          } else {
                            await auth.signOut();
                          }
                        },
                  child: Text(guest ? 'Sign in' : 'Sign out'),
                ),
              ),
            ),
          ),
          if (auth.error != null) Text(auth.error!),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AbsorbPointer(absorbing: auth.busy, child: widget.child),
                if (auth.busy)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
