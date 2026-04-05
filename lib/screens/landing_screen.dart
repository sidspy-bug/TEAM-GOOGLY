import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../l10n/app_localizations.dart';
import 'login_screen.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LandingScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE9EDFF),
              Color(0xFFDFE6FA),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _orbitController,
                builder: (context, _) => _OrbitalLines(phase: _orbitController.value),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 900;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: _buildLeftPanel(context, l, true)),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildVisualPanel(true)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildVisualPanel(false),
                                  const SizedBox(height: 18),
                                  _buildLeftPanel(context, l, false),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context, AppLocalizations l, bool isDesktop) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(-24 * (1 - value), 0), child: child),
      ),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 32 : 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5661A8).withValues(alpha: 0.14),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A55DA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.store_mall_directory_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 10),
                Text(
                  l.appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2A60),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Start and run your business in one place',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1.04,
                letterSpacing: -0.6,
                color: Color(0xFF262E63),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Track sales, maintain inventory, and make faster decisions with a visual dashboard built for modern retail teams.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: Color(0xFF4E588D),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(onLoginSuccess: widget.onLoginSuccess),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF4A55DA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Get Early Access',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _FeatureTag(text: 'Realtime Analytics'),
                _FeatureTag(text: 'Stock Alerts'),
                _FeatureTag(text: 'OCR Billing Input'),
                _FeatureTag(text: 'AI Insights'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualPanel(bool isDesktop) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(26 * (1 - value), 0), child: child),
      ),
      child: SizedBox(
        height: isDesktop ? 620 : 490,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: isDesktop ? 20 : 2,
              bottom: isDesktop ? 60 : 40,
              child: _PhoneMock(
                width: isDesktop ? 210 : 165,
                title: 'Already have a business?',
                subtitle: 'Migrate seamlessly',
                light: const Color(0xFFF9FBFF),
                dark: const Color(0xFFE8EEFF),
                isDarkContent: true,
                previewMode: PhonePreviewMode.migration,
              ),
            ),
            Positioned(
              right: isDesktop ? 26 : 0,
              top: isDesktop ? 0 : 8,
              child: _PhoneMock(
                width: isDesktop ? 250 : 198,
                title: 'Business in one place',
                subtitle: 'Control growth with confidence',
                light: const Color(0xFF5D63F8),
                dark: const Color(0xFF303DE5),
                isDarkContent: false,
                previewMode: PhonePreviewMode.analytics,
              ),
            ),
            Positioned(
              right: isDesktop ? 0 : 12,
              top: isDesktop ? 170 : 150,
              child: Container(
                width: isDesktop ? 120 : 92,
                height: isDesktop ? 120 : 92,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0xFF6C7BFF),
                      Color(0xFF44E2FF),
                      Color(0xFFFFD451),
                      Color(0xFF6C7BFF),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: isDesktop ? 0 : 2,
              bottom: isDesktop ? 18 : 4,
              child: Container(
                width: isDesktop ? 248 : 210,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF46519F).withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Cash flow', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2A60))),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _MiniMetric(icon: Icons.south_west_rounded, amount: '80000'),
                        _MiniMetric(icon: Icons.north_east_rounded, amount: '12000'),
                        _MiniMetric(icon: Icons.trending_up_rounded, amount: '2000'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  final String text;

  const _FeatureTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xFFEDF0FF),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3D489D),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String amount;

  const _MiniMetric({required this.icon, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC5CEF7), width: 1.6),
          ),
          child: Icon(icon, color: const Color(0xFF4A55DA), size: 18),
        ),
        const SizedBox(height: 7),
        Text(
          'Rs $amount',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1F2A60)),
        ),
      ],
    );
  }
}

class _PhoneMock extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final Color light;
  final Color dark;
  final bool isDarkContent;
  final PhonePreviewMode previewMode;

  const _PhoneMock({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.light,
    required this.dark,
    required this.isDarkContent,
    required this.previewMode,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 2.05;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        color: const Color(0xFF11131F),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [light, dark],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 72,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: width > 200 ? 26 : 18,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                    color: isDarkContent ? const Color(0xFF21295D) : Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkContent
                        ? const Color(0xFF5E679D)
                        : Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _PhoneScreenPreview(
                    isDarkContent: isDarkContent,
                    mode: previewMode,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneScreenPreview extends StatelessWidget {
  final bool isDarkContent;
  final PhonePreviewMode mode;

  const _PhoneScreenPreview({required this.isDarkContent, required this.mode});

  @override
  Widget build(BuildContext context) {
    if (mode == PhonePreviewMode.migration) {
      return _buildMigrationPreview();
    }
    return _buildAnalyticsPreview();
  }

  Widget _buildMigrationPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 270;
        final gap = compact ? 5.0 : 8.0;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _animatedAppear(
                index: 0,
                child: _migrationStep(
                  icon: Icons.download_done_rounded,
                  title: 'Import Catalog',
                  subtitle: 'Auto map products and categories',
                  compact: compact,
                ),
              ),
              SizedBox(height: gap),
              _animatedAppear(
                index: 1,
                child: _migrationStep(
                  icon: Icons.group_add_rounded,
                  title: 'Map Customers',
                  subtitle: 'Bring customer history',
                  compact: compact,
                ),
              ),
              SizedBox(height: gap),
              _animatedAppear(
                index: 2,
                child: _migrationStep(
                  icon: Icons.rule_folder_outlined,
                  title: 'Verify Data',
                  subtitle: 'Validate pricing and stock',
                  compact: compact,
                ),
              ),
              SizedBox(height: gap),
              _animatedAppear(
                index: 3,
                child: Container(
                  height: compact ? 42 : 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFE7EDFF),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Migration progress: 82%',
                          style: TextStyle(
                            color: const Color(0xFF2B3577),
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF2B3577)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: gap),
              _animatedAppear(
                index: 4,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: 0.82),
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: compact ? 6 : 7,
                      backgroundColor: const Color(0xFFD6DDF9),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF5463F4)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _migrationStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool compact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FF),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 6 : 8),
      child: Row(
        children: [
          Container(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD6DDF9)),
            ),
            child: Icon(icon, size: compact ? 14 : 16, color: const Color(0xFF4655D6)),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF2A336C),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!compact)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6570A8),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPreview() {
    final cardBg = isDarkContent
        ? Colors.white.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.16);
    final textPrimary = isDarkContent ? const Color(0xFF232B63) : Colors.white;
    final textSecondary = isDarkContent
        ? const Color(0xFF606AA0)
        : Colors.white.withValues(alpha: 0.80);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sales', style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text('Rs 85K', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profit', style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text('Rs 21K', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Performance',
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                      Icon(Icons.more_horiz, size: 16, color: textSecondary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _TinyBar(height: 20, isDarkContent: isDarkContent, delayMs: 80),
                        _TinyBar(height: 28, isDarkContent: isDarkContent, delayMs: 160),
                        _TinyBar(height: 36, isDarkContent: isDarkContent, delayMs: 240),
                        _TinyBar(height: 24, isDarkContent: isDarkContent, delayMs: 320),
                        _TinyBar(height: 42, isDarkContent: isDarkContent, delayMs: 400),
                        _TinyBar(height: 34, isDarkContent: isDarkContent, delayMs: 480),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 920),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - value)),
                child: child,
              ),
            ),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkContent ? const Color(0xFFEAF0FF) : Colors.white.withValues(alpha: 0.22),
                    ),
                    child: Icon(Icons.inventory_2_rounded, size: 16, color: textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Low stock alert', style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                        Text('4 products need refill', style: TextStyle(color: textSecondary, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedAppear({required int index, required Widget child}) {
    final duration = 420 + (index * 140);
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: duration),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, builtChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: builtChild,
        ),
      ),
      child: child,
    );
  }
}

enum PhonePreviewMode { migration, analytics }

class _TinyBar extends StatelessWidget {
  final double height;
  final bool isDarkContent;
  final int delayMs;

  const _TinyBar({required this.height, required this.isDarkContent, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 620 + delayMs),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0, end: height),
          builder: (context, value, _) => Container(
            height: value,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkContent
                    ? [const Color(0xFF7282FF), const Color(0xFF95A4FF)]
                    : [const Color(0xFF8DC8FF), const Color(0xFF5C78FF)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitalLines extends StatelessWidget {
  final double phase;

  const _OrbitalLines({required this.phase});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OrbitPainter(phase: phase),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double phase;

  _OrbitPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF909AE3).withValues(alpha: 0.36);

    final center = Offset(size.width / 2, size.height * 0.34);
    final baseRadiusX = size.width * 0.43;
    final baseRadiusY = size.height * 0.08;
    final wave = (phase * math.pi * 2);

    for (int i = -2; i <= 3; i++) {
      final orbitShiftX =
          (i.isEven ? 1 : -1) * 10.0 * (0.5 + 0.5 * math.sin(wave + i));
      final alphaPulse =
          0.22 + 0.18 * (0.5 + 0.5 * math.cos(wave + (i * 0.65)));
      paint.color = const Color(0xFF909AE3).withValues(alpha: alphaPulse);
      final rect = Rect.fromCenter(
        center: Offset(center.dx + orbitShiftX, center.dy + i * 56),
        width: baseRadiusX * 2,
        height: (baseRadiusY + i.abs() * 2) * 2,
      );
      canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
