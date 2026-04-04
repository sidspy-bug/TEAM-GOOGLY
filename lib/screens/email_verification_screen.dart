import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Modern email verification screen with animated states,
/// step indicators, and polished UI.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
  const EmailVerificationScreen({super.key, required this.email, required this.onVerified});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  final _auth = FirebaseAuth.instance;
  Timer? _pollTimer;
  bool _verified = false;
  bool _sending = false;
  bool _emailSent = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
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
    _sendVerificationEmail();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    if (_sending || _resendCooldown > 0) return;
    setState(() => _sending = true);
    try {
      await _auth.currentUser?.sendEmailVerification();
      if (mounted) {
        setState(() {
          _emailSent = true;
          _sending = false;
          _resendCooldown = 60;
        });
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('too-many-requests')
                ? 'Too many requests. Please wait.'
                : 'Failed to send email. Try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _resendCooldown--);
        if (_resendCooldown <= 0) timer.cancel();
      } else {
        timer.cancel();
      }
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        await _auth.currentUser?.reload();
        final user = _auth.currentUser;
        if (user != null && user.emailVerified) {
          _pollTimer?.cancel();
          _pulseController.stop();
          if (mounted) {
            setState(() => _verified = true);
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _manualCheck() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;
    if (user != null && user.emailVerified) {
      _pollTimer?.cancel();
      _pulseController.stop();
      setState(() => _verified = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Not verified yet. Check your inbox and click the link.')),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            margin: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GrowthOS branding (auth screens)
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
                    child: Column(
                      children: [
                        // Animated icon
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _verified
                              ? _buildSuccessIcon()
                              : _buildMailIcon(),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _verified ? 'Email Verified!' : 'Check Your Email',
                            key: ValueKey(_verified),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _verified ? (isDark ? Colors.green.shade300 : Colors.green.shade700) : (isDark ? Colors.white : Colors.grey.shade800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        if (_verified) ...[                          Text(
                            'Email verified successfully',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700, height: 1.5, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can now continue to your dashboard',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500, height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                widget.onVerified();
                                if (mounted) {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                }
                              },
                              icon: const Icon(Icons.dashboard, size: 20),
                              label: const Text('Go to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Step indicators
                          _buildSteps(),
                          const SizedBox(height: 24),

                          // Email display chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: isDark ? const Color(0xFF475569) : Colors.indigo.shade100),                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.email_outlined, size: 18, color: Colors.indigo.shade400),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    widget.email,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.indigo.shade200 : Colors.indigo.shade700,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // "I've verified" button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _manualCheck,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.verified_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('I\'ve Verified My Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Resend row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Didn\'t receive the email? ',
                                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500, fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: (_sending || _resendCooldown > 0) ? null : _sendVerificationEmail,
                                child: Text(
                                  _resendCooldown > 0
                                      ? 'Resend in ${_resendCooldown}s'
                                      : (_sending ? 'Sending...' : 'Resend'),
                                  style: TextStyle(
                                    color: (_sending || _resendCooldown > 0)
                                        ? (isDark ? const Color(0xFF475569) : Colors.grey.shade400)
                                        : Colors.indigo,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Back to login link (outside card)
                if (!_verified) ...[
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      _auth.signOut();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: Icon(Icons.arrow_back, size: 16, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
                    label: Text('Back to Login', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
                  ),
                ],

                // Spam tip
                if (!_verified && _emailSent) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.amber.shade900.withValues(alpha: 0.2) : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.amber.shade700 : Colors.amber.shade200),                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Check your spam or junk folder if you don\'t see the email in your inbox.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMailIcon() {
    return ScaleTransition(
      key: const ValueKey('mail'),
      scale: _pulseAnimation,
      child: Container(
        width: 90,
        height: 90,
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
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.mark_email_unread_rounded, size: 44, color: Colors.white),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      key: const ValueKey('success'),
      width: 90,
      height: 90,
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
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, size: 50, color: Colors.white),
    );
  }

  Widget _buildSteps() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepDot(1, 'Sent', _emailSent),
          _stepLine(_emailSent),
          _stepDot(2, 'Click link', false),
          _stepLine(false),
          _stepDot(3, 'Done', _verified),
        ],
      ),
    );
  }

  Widget _stepDot(int number, String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? Colors.green : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            border: Border.all(
              color: completed ? Colors.green : (isDark ? const Color(0xFF475569) : Colors.grey.shade300),
              width: 2,
            ),
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
      ],
    );
  }

  Widget _stepLine(bool completed) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: completed ? Colors.green.shade300 : (isDark ? const Color(0xFF475569) : Colors.grey.shade300),
    );
  }
}
