import 'package:flutter/material.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
  const OtpVerificationScreen({super.key, required this.email, required this.onVerified});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpCtrl = TextEditingController();
  bool _verified = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    if (_otpCtrl.text == '1234') {
      setState(() => _verified = true);
      Future.delayed(const Duration(seconds: 2), () {
        // Fire the auth callback (sets _isLoggedIn = true in MyApp)
        widget.onVerified();
        // Pop all pushed routes so the root MaterialApp home: change is visible
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Use 1234'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _verified ? Icons.check_circle : Icons.mark_email_read,
                size: 64,
                color: _verified ? Colors.green : Colors.indigo.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _verified ? 'Email Verified!' : 'Verify Your Email',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _verified
                    ? 'Redirecting to dashboard...'
                    : 'We sent a verification code to\n${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (_verified) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
              if (!_verified) ...[
                const SizedBox(height: 32),
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: const InputDecoration(
                    hintText: '1 2 3 4',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    child: const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OTP resent (mock): 1234')),
                    );
                  },
                  child: const Text('Resend Code'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
