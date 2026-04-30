import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/firebase/auth_service.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _busy = false;
  String? _message;

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      setState(() => _message = 'Verification email sent.');
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).reloadUser();
      await FirebaseAuth.instance.currentUser?.reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify email'),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => ref.read(authServiceProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We sent a verification link to:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(user?.email ?? '(unknown email)'),
              const SizedBox(height: 16),
              const Text('Verify your email, then come back and press Refresh.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton(
                    onPressed: _busy ? null : _refresh,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : _resend,
                    child: const Text('Resend email'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_message != null) Text(_message!),
            ],
          ),
        ),
      ),
    );
  }
}

