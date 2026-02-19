import 'package:flutter/material.dart';

class BatteryIndicator extends StatefulWidget {
  final double percent;
  final bool isCharging; // Aggiunto per attivare l'animazione

  const BatteryIndicator({
    super.key, 
    required this.percent, 
    this.isCharging = false,
  });

  @override
  State<BatteryIndicator> createState() => _BatteryIndicatorState();
}

class _BatteryIndicatorState extends State<BatteryIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isCharging) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BatteryIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Avvia o ferma l'animazione se cambia lo stato di carica
    if (widget.isCharging && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCharging && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color batteryColor = _getBatteryColor(widget.percent);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          height: 45,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              // SFONDO E BORDO (Guscio batteria)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    // Il bordo pulsa se è in carica
                    color: widget.isCharging 
                        ? batteryColor.withOpacity(_glowAnimation.value) 
                        : Colors.white10, 
                    width: 2,
                  ),
                ),
              ),
              
              // RIEMPIMENTO ELETTRIZZANTE
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: FractionallySizedBox(
                  widthFactor: widget.percent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          batteryColor.withOpacity(0.9),
                          batteryColor,
                          batteryColor.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          // L'ombra pulsa se è in carica
                          color: batteryColor.withOpacity(widget.isCharging ? 0.6 * _glowAnimation.value : 0.4),
                          blurRadius: widget.isCharging ? 12 * _glowAnimation.value : 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // BECCUCCIO (Polo positivo a destra)
              Positioned(
                right: -6,
                child: Container(
                  width: 5,
                  height: 16,
                  decoration: BoxDecoration(
                    color: widget.isCharging 
                        ? batteryColor.withOpacity(_glowAnimation.value) 
                        : Colors.white10,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                  ),
                ),
              ),

              // TESTO ORIZZONTALE CON 2 DECIMALI
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isCharging)
                      Icon(Icons.bolt_rounded, color: Colors.white.withOpacity(_glowAnimation.value), size: 16),
                    Text(
                      "${widget.percent.toStringAsFixed(2).replaceFirst('.', ',')}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBatteryColor(double p) {
    if (p > 75) return const Color(0xFF00E676); // Verde neon
    if (p > 25) return const Color(0xFFFFAB40); // Arancio neon
    return const Color(0xFFFF5252); // Rosso neon
  }
}