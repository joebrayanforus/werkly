import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/home_page.dart';
import 'password_recovery_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final GoTrueClient _auth;
  StreamSubscription<AuthState>? _subscription;
  Session? _session;
  bool _recoveringPassword = false;

  @override
  void initState() {
    super.initState();
    _auth = Supabase.instance.client.auth;
    _session = _auth.currentSession;
    _subscription = _auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() {
        _session = state.session;
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _recoveringPassword = true;
        } else if (state.event == AuthChangeEvent.signedOut) {
          _recoveringPassword = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_recoveringPassword) {
      return PasswordRecoveryPage(
        onComplete: () {
          if (mounted) setState(() => _recoveringPassword = false);
        },
      );
    }
    final userId = _session?.user.id ?? 'guest';
    return HomePage(key: ValueKey(userId));
  }
}
