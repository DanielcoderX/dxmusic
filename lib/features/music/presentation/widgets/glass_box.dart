import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBox extends StatefulWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final Gradient? gradient;

  const GlassBox({
    super.key,
    required this.child,
    this.blur = 30.0,
    this.opacity = 0.08,
    this.borderRadius,
    this.border,
    this.gradient,
  });

  @override
  State<GlassBox> createState() => _GlassBoxState();
}

class _GlassBoxState extends State<GlassBox> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Super slow, elegant light-sweep across the glass plate
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(24);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final progress = _shimmerController.value;

        // Custom refractive gradient border that sweeps light dynamically
        final borderGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.12 + 0.15 * mathShimmer(progress)),
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.12 + 0.15 * mathShimmer(progress + 0.5)),
            Colors.white.withOpacity(0.08),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );

        return ClipRRect(
          borderRadius: effectiveRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
            child: Container(
              // Outer refraction border simulated via padding and background gradient
              padding: const EdgeInsets.all(1.0),
              decoration: BoxDecoration(
                borderRadius: effectiveRadius,
                gradient: borderGradient,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: effectiveRadius,
                  gradient: widget.gradient ?? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(widget.opacity + 0.05),
                      Colors.white.withOpacity(widget.opacity + 0.02),
                      Colors.white.withOpacity(widget.opacity),
                      Colors.white.withOpacity(widget.opacity - 0.03),
                    ],
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }

  // Trigonometric wave driving organic reflection shimmers
  double mathShimmer(double progress) {
    return 0.5 + 0.5 * math.sin(progress * 2 * 3.14159265);
  }
}