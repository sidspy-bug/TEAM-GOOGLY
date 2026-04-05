import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

/// Modern Forgot Password screen.
/// Sends a real Firebase password-reset email and shows status feedback.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;
  bool _sent = false;
  int _resendCooldown = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _sending = false;
          _sent = true;
          _resendCooldown = 60;
        });
        _startCooldown();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e.code)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startCooldown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  String _errorMessage(String code) {
    if (code.contains('user-not-found')) return 'No account found with this email.';
    if (code.contains('invalid-email')) return 'Invalid email address.';
    if (code.contains('too-many-requests')) return 'Too many requests. Please wait before trying again.';
    return 'Failed to send reset email. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            margin: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GrowthOS branding
                Icon(Icons.storefront, size: 40, color: Colors.indigo.shade400),
                const SizedBox(height: 6),
                const Text('GrowthOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 20),

                // Main card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _sent ? _buildSentState(l) : _buildFormState(l),
                    ),
                  ),
                ),

                // Back to Login
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, size: 16, color: Colors.grey.shade500),
                  label: Text(l.backToLogin, style: TextStyle(color: Colors.grey.shade500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Form state — email input + send button
  Widget _buildFormState(AppLocalizations l) {
    return Column(
      key: const ValueKey('form'),
      children: [
        // Animated lock icon
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.indigo.shade300, Colors.indigo.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.resetPassword,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 8),
        Text(
          l.resetPasswordDesc,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
        ),
        const SizedBox(height: 28),

        // Email field
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l.email,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l.emailRequired;
              if (!v.contains('@') || !v.contains('.')) return l.enterValidEmail;
              return null;
            },
            onFieldSubmitted: (_) => _sendResetEmail(),
          ),
        ),
        const SizedBox(height: 24),

        // Send button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _sending ? null : _sendResetEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.indigo.shade200,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l.sendResetLink, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  /// Success state — email sent confirmation
  Widget _buildSentState(AppLocalizations l) {
    return Column(
      key: const ValueKey('sent'),
      children: [
        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.green.shade300, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.mark_email_read_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          l.checkYourEmail,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700),
        ),
        const SizedBox(height: 12),

        // Email chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email_outlined, size: 18, color: Colors.indigo.shade400),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _emailCtrl.text.trim(),
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo.shade700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.emailSentDesc,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Steps
        _buildSteps(l),
        const SizedBox(height: 24),

        // Back to sign in button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.login, size: 20),
            label: Text(l.backToSignIn, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resend row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l.didntReceiveEmail,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            GestureDetector(
              onTap: (_sending || _resendCooldown > 0) ? null : () {
                setState(() => _sent = false);
                _sendResetEmail();
              },
              child: Text(
                _resendCooldown > 0
                    ? l.resendInSeconds(_resendCooldown)
                    : l.resend,
                style: TextStyle(
                  color: _resendCooldown > 0 ? Colors.grey.shade400 : Colors.indigo,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Spam tip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.checkSpamTip,
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSteps(AppLocalizations l) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot(1, l.stepEmailSent, true),
        _stepLine(true),
        _stepDot(2, l.stepClickLink, false),
        _stepLine(false),
        _stepDot(3, l.stepNewPassword, false),
      ],
    );
  }

  Widget _stepDot(int number, String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? Colors.green : Colors.grey.shade200,
            border: Border.all(color: completed ? Colors.green : Colors.grey.shade300, width: 2),
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('$number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _stepLine(bool completed) {
    return Container(
      width: 36,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: completed ? Colors.green.shade300 : Colors.grey.shade300,
    );
  }
}
