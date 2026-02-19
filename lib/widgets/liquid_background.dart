import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidBackground extends StatefulWidget {
  final Widget child;
  final Color color1;
  final Color color2;
  final double opacity;

  const LiquidBackground({
    super.key,
    required this.child,
    this.color1 = Colors.blue,
    this.color2 = Colors.cyan,
    this.opacity = 0.15, // 🔥 AUMENTATO
  });

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔥 SFONDO CON GRADIENTE così si vede qualcosa
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0A),
                Color(0xFF1A1A1A),
                Color(0xFF0A0A0A),
              ],
            ),
          ),
        ),
        
        // Onde animate
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: LiquidWavePainter(
                animation: _controller,
                color1: widget.color1.withOpacity(widget.opacity),
                color2: widget.color2.withOpacity(widget.opacity * 0.8),
              ),
              size: MediaQuery.of(context).size,
            );
          },
        ),
        
        // Contenuto
        widget.child,
      ],
    );
  }
}

class LiquidWavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color1;
  final Color color2;

  LiquidWavePainter({
    required this.animation,
    required this.color1,
    required this.color2,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final double progress = animation.value;
    
    // Onda 1
    final paint1 = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25) // 🔥 PIÙ BLUR
      ..color = color1;
    
    _drawWave(canvas, size, progress, 0.7, 0.08, paint1); // 🔥 AMPIEZZA AUMENTATA

    // Onda 2 - sfasata
    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30) // 🔥 PIÙ BLUR
      ..color = color2;
    
    _drawWave(canvas, size, progress + 0.3, 1.2, 0.1, paint2); // 🔥 AMPIEZZA AUMENTATA
  }

  void _drawWave(Canvas canvas, Size size, double progress, double freq, double ampFactor, Paint paint) {
    final path = Path();
    final double amplitude = size.height * ampFactor;
    final double frequency = freq * math.pi * 2 / size.width;

    path.moveTo(0, size.height * 0.6); // 🔥 POSIZIONE MODIFICATA

    for (double x = 0; x <= size.width; x += 5) {
      double y = size.height * 0.6 +
          amplitude * math.sin(frequency * x + progress * 2 * math.pi) +
          amplitude * 0.5 * math.sin(frequency * 1.5 * x + progress * 3 * math.pi);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height + 100);
    path.lineTo(0, size.height + 100);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidWavePainter oldDelegate) => true;
}