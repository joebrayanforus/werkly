import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_language.dart';
import 'auth_error_message.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _notice;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('passwordUpdated'))));
      widget.onComplete();
    } on AuthException catch (error) {
      if (mounted) {
        setState(
          () => _notice = localizedAuthErrorMessage(
            error.message,
            AppLanguageController.language.value,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _notice = context.tr('connectionFailed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2F6B55);
    final email = Supabase.instance.client.auth.currentUser?.email;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFFDDEDE4),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            color: green,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          context.tr('chooseNewPassword'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email == null
                              ? context.tr('passwordRecoverySubtitle')
                              : context.trFormat('passwordRecoveryFor', {
                                  'email': email,
                                }),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: context.tr('newPassword'),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value ?? '').length < 8
                              ? context.tr('passwordLength')
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmationController,
                          obscureText: _obscureConfirmation,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _savePassword(),
                          decoration: InputDecoration(
                            labelText: context.tr('confirmNewPassword'),
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value != _passwordController.text
                              ? context.tr('passwordsDoNotMatch')
                              : null,
                        ),
                        if (_notice != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1DD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _notice!,
                              style: const TextStyle(
                                color: Color(0xFF8A551C),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _busy ? null : _savePassword,
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(context.tr('saveNewPassword')),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _cancel,
                          child: Text(context.tr('cancel')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
