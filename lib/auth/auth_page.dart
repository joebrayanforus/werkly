import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_language.dart';
import '../pages/privacy_page.dart';
import '../services/auth_redirects.dart';
import 'auth_error_message.dart';

const _ink = Color(0xFF17231F);
const _green = Color(0xFF2F6B55);
const _orange = Color(0xFFE9A95B);
const _mint = Color(0xFFDDEDE4);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signUp = false;
  bool _accepted = false;
  bool _busy = false;
  bool _obscure = true;
  bool _confirmationPending = false;
  String? _notice;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_signUp && !_accepted) {
      setState(() => _notice = context.tr('privacyRequired'));
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_signUp) {
        final response = await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          emailRedirectTo: werklyAuthConfirmedUrlFor(
            AppLanguageController.language.value,
          ),
          data: {
            'full_name': _nameController.text.trim(),
            'preferred_language': AppLanguageController.language.value.name,
          },
        );
        if (response.session == null && mounted) {
          setState(() {
            _confirmationPending = true;
            _notice = context.tr('verifyEmail');
          });
        } else if (mounted) {
          Navigator.of(context).maybePop();
        }
      } else {
        final response = await auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (response.session != null && mounted) {
          Navigator.of(context).maybePop();
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _notice = localizedAuthErrorMessage(
            error.message,
            AppLanguageController.language.value,
          );
          if (authErrorNeedsConfirmation(error.message)) {
            _confirmationPending = true;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notice = context.tr('connectionFailed'));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: werklyGoogleOAuthRedirect(),
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _notice = localizedAuthErrorMessage(
            error.message,
            AppLanguageController.language.value,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notice = context.tr('connectionFailed'));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _notice = context.tr('enterEmailFirst'));
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: werklyAuthConfirmedUrlFor(
          AppLanguageController.language.value,
        ),
      );
      if (mounted) {
        setState(() => _notice = context.tr('confirmationResent'));
      }
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
      if (mounted) {
        setState(() => _notice = context.tr('connectionFailed'));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _notice = context.tr('enterEmailFirst'));
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: werklyPasswordRecoveryRedirect(),
      );
      if (mounted) {
        setState(() => _notice = context.tr('resetLinkSent'));
      }
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
      if (mounted) {
        setState(() => _notice = context.tr('connectionFailed'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Row(
              children: [
                if (wide)
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      color: _ink,
                      padding: const EdgeInsets.all(54),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AuthBrand(),
                          Spacer(),
                          Text(
                            context.tr('authHero'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 46,
                              height: 1.02,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.7,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            context.tr('authHeroBody'),
                            style: const TextStyle(
                              color: Color(0xFFC8D1CD),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _AuthFeature(
                            icon: Icons.auto_awesome_rounded,
                            label: context.tr('authFeatureMatching'),
                          ),
                          _AuthFeature(
                            icon: Icons.map_outlined,
                            label: context.tr('authFeatureNearby'),
                          ),
                          _AuthFeature(
                            icon: Icons.view_kanban_outlined,
                            label: context.tr('authFeatureTracking'),
                          ),
                          Spacer(),
                          Text(
                            context.tr('designedForStudents'),
                            style: const TextStyle(
                              color: Color(0xFF82918B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!wide) ...[
                                const _AuthBrand(dark: true),
                                const SizedBox(height: 44),
                              ],
                              Text(
                                _signUp
                                    ? context.tr('createProfile')
                                    : context.tr('welcomeBack'),
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _signUp
                                    ? context.tr('signupSubtitle')
                                    : context.tr('signinSubtitle'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 28),
                              if (_signUp) ...[
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: context.tr('nameField'),
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  validator: (value) =>
                                      (value ?? '').trim().length < 2
                                      ? context.tr('nameRequired')
                                      : null,
                                ),
                                const SizedBox(height: 14),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: context.tr('email'),
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                  ),
                                ),
                                validator: (value) =>
                                    !(value ?? '').contains('@')
                                    ? context.tr('invalidEmail')
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: context.tr('password'),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) => (value ?? '').length < 8
                                    ? context.tr('passwordLength')
                                    : null,
                              ),
                              if (!_signUp)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _busy ? null : _resetPassword,
                                    child: Text(context.tr('forgotPassword')),
                                  ),
                                ),
                              if (_signUp)
                                Column(
                                  children: [
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: _accepted,
                                      onChanged: (value) => setState(
                                        () => _accepted = value ?? false,
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(
                                        context.tr('acceptPrivacy'),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    const PrivacyPage(),
                                              ),
                                            ),
                                        icon: const Icon(
                                          Icons.privacy_tip_outlined,
                                          size: 17,
                                        ),
                                        label: Text(
                                          context.tr('readPrivacyPolicy'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (_notice != null) ...[
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
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              FilledButton(
                                onPressed: _busy ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _green,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 17,
                                  ),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _signUp
                                            ? context.tr('createAccount')
                                            : context.tr('signIn'),
                                      ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      context.tr('orDivider'),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 18),
                              OutlinedButton.icon(
                                onPressed: _busy ? null : _signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE4E8E1),
                                  ),
                                ),
                                icon: const _GoogleMark(),
                                label: Text(context.tr('continueWithGoogle')),
                              ),
                              if (_confirmationPending) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _busy ? null : _resendConfirmation,
                                  icon: const Icon(
                                    Icons.mark_email_read_outlined,
                                  ),
                                  label: Text(context.tr('resendConfirmation')),
                                ),
                              ],
                              const SizedBox(height: 18),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _signUp
                                        ? context.tr('alreadyRegistered')
                                        : context.tr('newToWerkly'),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _signUp = !_signUp;
                                      _confirmationPending = false;
                                      _notice = null;
                                    }),
                                    child: Text(
                                      _signUp
                                          ? context.tr('signIn')
                                          : context.tr('createAccount'),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: Text(context.tr('continueGuest')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand({this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'W',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'werkly',
          style: TextStyle(
            color: dark ? _ink : Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFE4E8E1)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}

class _AuthFeature extends StatelessWidget {
  const _AuthFeature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _mint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: _green),
          ),
          const SizedBox(width: 11),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
