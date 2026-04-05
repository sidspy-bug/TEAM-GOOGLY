import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _auth = AuthService();

  bool _usePhone = false;
  bool _otpSent = false;
  bool _canLogin = false;
  bool _socialLoading = false;
  bool _emailLoading = false;
  bool _phoneLoading = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_updateLoginState);
    _passCtrl.addListener(_updateLoginState);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _updateLoginState() {
    final canLogin =
        _emailCtrl.text.trim().isNotEmpty && _passCtrl.text.trim().isNotEmpty;
    if (canLogin != _canLogin) {
      setState(() => _canLogin = canLogin);
    }
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _emailLoading = true);
    try {
      final cred = await _auth.signInWithEmail(_emailCtrl.text, _passCtrl.text);
      if (!mounted) return;

      if (cred.user != null && !cred.user!.emailVerified) {
        setState(() => _emailLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: _emailCtrl.text,
              onVerified: widget.onLoginSuccess,
            ),
          ),
        );
        return;
      }

      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _emailLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_firebaseErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.length < 10) return;

    setState(() => _phoneLoading = true);
    try {
      final phoneNumber = '+91${_phoneCtrl.text.trim()}';
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) widget.onLoginSuccess();
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _phoneLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_firebaseErrorMessage(e)),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _phoneLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).otpSent)),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _phoneLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_firebaseErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).invalidOtp),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _phoneLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _phoneLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('invalid-verification-code')
                ? 'Invalid OTP. Please try again.'
                : _firebaseErrorMessage(e),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_socialLoading) return;

    setState(() => _socialLoading = true);
    try {
      await _auth.signInWithGoogle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signedInWithGoogle)),
      );
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _socialLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_firebaseErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loginWithFacebook() async {
    if (_socialLoading) return;

    setState(() => _socialLoading = true);
    try {
      await _auth.signInWithFacebook();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signedInWithFacebook)),
      );
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _socialLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_firebaseErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _firebaseErrorMessage(dynamic e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) return 'No account found for this email.';
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Incorrect password.';
    }
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    if (msg.contains('popup-closed') || msg.contains('cancelled')) {
      return 'Sign-in cancelled.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    }
    if (msg.contains('OPERATION_NOT_ALLOWED') || msg.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Please use email or Google sign-in.';
    }
    if (msg.contains('account-exists-with-different-credential')) {
      return 'An account already exists with a different sign-in method.';
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront, size: 64, color: Colors.indigo.shade400),
                const SizedBox(height: 12),
                Text(
                  l.appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by GrowthOS',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(l.loginTitle, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text(l.email),
                      selected: !_usePhone,
                      onSelected: (_) => setState(() {
                        _usePhone = false;
                        _otpSent = false;
                      }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(l.phoneLabel),
                      selected: _usePhone,
                      onSelected: (_) => setState(() {
                        _usePhone = true;
                        _otpSent = false;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (!_usePhone) ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: l.email,
                            prefixIcon: const Icon(Icons.email),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return l.emailRequired;
                            if (!v.contains('@')) return l.enterValidEmail;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l.password,
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return l.passwordRequired;
                            if (v.length < 6) return l.minSixChars;
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (_canLogin && !_emailLoading) ? _login : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              disabledBackgroundColor: Colors.indigo.shade200,
                            ),
                            child: _emailLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l.signIn,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              l.forgotPassword,
                              style: TextStyle(
                                color: Colors.indigo.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l.phoneNumber,
                      prefixIcon: const Icon(Icons.phone),
                      border: const OutlineInputBorder(),
                      prefixText: '+91 ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_otpSent)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _phoneLoading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        child: _phoneLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l.sendOtp,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    )
                  else ...[
                    TextFormField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.enterOtp,
                        prefixIcon: const Icon(Icons.pin),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _phoneLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        child: _phoneLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l.verifyOtp,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l.orContinueWith,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _socialLoading ? null : _loginWithGoogle,
                    icon: _socialLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                    label: Text(l.continueWithGoogle),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _socialLoading ? null : _loginWithFacebook,
                    icon: _socialLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.facebook, size: 22, color: Color(0xFF1877F2)),
                    label: Text(l.continueWithFacebook),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SignupScreen(onSignupSuccess: widget.onLoginSuccess),
                      ),
                    );
                  },
                  child: Text(l.dontHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
