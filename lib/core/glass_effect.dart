import 'dart:ui';
import 'package:flutter/material.dart';

class GlassEffect {
  /// Effetto frosted glass
  static Widget frostedWidget({
    required Widget child,
    double blur = 20,
    double opacity = 0.2,
    Color? color,
    double radius = 20,
    EdgeInsets? padding,
    Color borderColor = Colors.white,
    double borderWidth = 1.5,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor.withOpacity(0.3), width: borderWidth),
          ),
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }

  /// Effetto frosted glass con gradient
  static Widget gradientFrostedWidget({
    required Widget child,
    double blur = 20,
    double radius = 20,
    EdgeInsets? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.blueAccent.withOpacity(0.1),
                Colors.purple.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }

  /// Effetto scuro
  static Widget darkFrostedWidget({
    required Widget child,
    double blur = 20,
    double opacity = 0.2,
    double radius = 20,
    EdgeInsets? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 1.5),
          ),
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}