import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidBackground extends StatefulWidget {
  final Color dominantColor;
  final Color accentColor;
  final Widget? child;

  const LiquidBackground({
    super.key,
    required this.dominantColor,
    required this.accentColor,
    this.child,
  });

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground> with TickerProviderStateMixin {
  late final AnimationController _timeController;
  
  // Interactive gesture dynamics
  Offset _touchPosition = Offset.zero;
  Offset _smoothTouch = Offset.zero;
  bool _isInteracting = false;
  double _orbScale = 1.0;

  @override
  void initState() {
    super.initState();
    // Continuous ambient drift loop
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        setState(() {
          _isInteracting = true;
          _touchPosition = event.localPosition;
          _orbScale = 1.25; // Orbs swell slightly on touch
        });
      },
      onPointerMove: (event) {
        setState(() {
          _touchPosition = event.localPosition;
        });
      },
      onPointerUp: (event) {
        setState(() {
          _isInteracting = false;
          _orbScale = 1.0;
        });
      },
      onPointerCancel: (event) {
        setState(() {
          _isInteracting = false;
          _orbScale = 1.0;
        });
      },
      child: Stack(
        children: [
          // Base obsidian color
          Container(color: const Color(0xFF060608)),

          // Shifting fluid mesh orbs
          AnimatedBuilder(
            animation: _timeController,
            builder: (context, _) {
              final angle = _timeController.value * 2 * math.pi;

              // Smoothly interpolate the touch point to prevent sudden jumping
              if (_isInteracting) {
                _smoothTouch = Offset(
                  lerpDouble(_smoothTouch.dx, _touchPosition.dx, 0.08)!,
                  lerpDouble(_smoothTouch.dy, _touchPosition.dy, 0.08)!,
                );
              } else {
                // Return to screen center when not touching
                _smoothTouch = Offset(
                  lerpDouble(_smoothTouch.dx, size.width / 2, 0.05)!,
                  lerpDouble(_smoothTouch.dy, size.height / 2, 0.05)!,
                );
              }

              // Map smooth touch coordinates to alignment offset bounds [-0.8, 0.8]
              final touchAlign = Alignment(
                ((_smoothTouch.dx / size.width) * 2 - 1) * 0.8,
                ((_smoothTouch.dy / size.height) * 2 - 1) * 0.8,
              );

              // Orb 1 Alignment: Base rotation + touch displacement
              final orb1Align = Alignment(
                0.5 * math.cos(angle) + touchAlign.x * 0.4,
                0.4 * math.sin(angle) - 0.2 + touchAlign.y * 0.4,
              );

              // Orb 2 Alignment: Inverse rotation + touch displacement
              final orb2Align = Alignment(
                0.4 * math.cos(angle + math.pi) + touchAlign.x * 0.5,
                0.5 * math.sin(angle + math.pi) + 0.3 + touchAlign.y * 0.5,
              );

              // Orb 3 Alignment: Faster shifting pattern + touch displacement
              final orb3Align = Alignment(
                0.3 * math.sin(angle * 1.8) + touchAlign.x * 0.6,
                0.3 * math.cos(angle * 1.8) + touchAlign.y * 0.6,
              );

              // Dynamic orb size breathing
              final pulse = 1.0 + 0.08 * math.sin(angle * 4.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Orb 1 (Dominant color, ambient backing)
                  AnimatedAlign(
                    alignment: orb1Align,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      width: size.width * 0.95 * _orbScale * pulse,
                      height: size.width * 0.95 * _orbScale * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.dominantColor.withOpacity(0.38),
                      ),
                    ),
                  ),

                  // Orb 2 (Accent color, highlights)
                  AnimatedAlign(
                    alignment: orb2Align,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      width: size.width * 0.85 * _orbScale * pulse,
                      height: size.width * 0.85 * _orbScale * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor.withOpacity(0.28),
                      ),
                    ),
                  ),

                  // Orb 3 (Accent blended center)
                  AnimatedAlign(
                    alignment: orb3Align,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      width: size.width * 0.65 * _orbScale * pulse,
                      height: size.width * 0.65 * _orbScale * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.dominantColor.withOpacity(0.22),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // High diffusion blur layer
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                  ),
                ),
              ),
            ),
          ),

          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
