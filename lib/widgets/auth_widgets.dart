import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'device_chrome.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.backgroundAssetPath,
  });

  final Widget child;
  final String? backgroundAssetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF41553A),
              Color(0xFF6E874F),
              Color(0xFF8EA250),
            ],
          ),
        ),
        child: Stack(
          children: [
            if (backgroundAssetPath != null)
              Positioned.fill(
                child: Image.asset(
                  backgroundAssetPath!,
                  fit: BoxFit.cover,
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: backgroundAssetPath == null ? 0.12 : 0.08,
                  ),
                ),
              ),
            ),
            if (backgroundAssetPath == null) ...[
              Positioned(
                top: -50,
                left: -40,
                child: _BlurOrb(
                  color: Colors.white.withValues(alpha: 0.08),
                  size: 180,
                ),
              ),
              Positioned(
                bottom: -40,
                right: -20,
                child: _BlurOrb(
                  color: AppColors.brandGreenLight.withValues(alpha: 0.18),
                  size: 220,
                ),
              ),
            ],
            child,
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SimulatedStatusBar(backgroundColor: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
