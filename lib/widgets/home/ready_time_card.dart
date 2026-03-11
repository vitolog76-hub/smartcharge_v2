import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:flutter/services.dart';  
import 'package:origo/providers/home_provider.dart';
import 'package:origo/l10n/app_localizations.dart';

class ReadyTimeCard extends StatelessWidget {
  final HomeProvider provider;

  const ReadyTimeCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return GestureDetector(
      onTap: provider.isSimulating ? null : () => _showCupertinoTimePicker(context, l10n),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.isSimulating
                        ? (provider.isChargingReal ? l10n.charging : l10n.waiting)
                        : l10n.readyAt,
                    style: TextStyle(
                      color: provider.isSimulating
                          ? (provider.isChargingReal
                              ? Colors.greenAccent
                              : Colors.orangeAccent)
                          : Colors.blueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    provider.readyTime.format(context),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: provider.isSimulating
                              ? (provider.isChargingReal
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent)
                              : Colors.blueAccent,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.calculatedOnPower(provider.wallboxPwr.toString()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: provider.isSimulating
                    ? (provider.isChargingReal
                        ? Colors.greenAccent.withOpacity(0.15)
                        : Colors.orangeAccent.withOpacity(0.15))
                    : Colors.blueAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                provider.isSimulating
                    ? (provider.isChargingReal ? Icons.bolt : Icons.timer)
                    : Icons.access_time,
                color: provider.isSimulating
                    ? (provider.isChargingReal
                        ? Colors.greenAccent
                        : Colors.orangeAccent)
                    : Colors.blueAccent,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCupertinoTimePicker(BuildContext context, AppLocalizations l10n) {
    showCupertinoModalPopup(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), // Oscura lo sfondo per focus
      builder: (BuildContext context) => Container(
        height: 340,
        margin: const EdgeInsets.all(16), // Effetto "floating" staccato dai bordi
        decoration: BoxDecoration(
          // Gradiente scuro per dare profondità alle rotelle
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1F36),
              Color(0xFF0A0F1E),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          // Bordino neon sottile
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 1. Maniglia decorativa superiore
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 2. Header Personalizzato
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(l10n.cancel, 
                        style: const TextStyle(color: Colors.white38, fontSize: 15)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Text(
                          l10n.readyAt.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.cyanAccent, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(width: 12, height: 1.5, color: Colors.cyanAccent),
                      ],
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(l10n.confirm, 
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 3. Il Selettore Cupertino (Rotelle)
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 24,
                        fontWeight: FontWeight.w300, // Look più "thin" ed elegante
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      provider.readyTime.hour,
                      provider.readyTime.minute,
                    ),
                    onDateTimeChanged: (DateTime newDateTime) {
                      // Feedback tattile di sistema ad ogni scatto
                      HapticFeedback.selectionClick();
                      provider.updateReadyTime(
                        TimeOfDay(hour: newDateTime.hour, minute: newDateTime.minute),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}