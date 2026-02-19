import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';

class ReadyTimeCard extends StatelessWidget {
  final HomeProvider provider;

  const ReadyTimeCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: provider.isSimulating ? null : () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1C1C1E),
              provider.isSimulating
                  ? (provider.isChargingReal
                      ? Colors.greenAccent.withOpacity(0.1)
                      : Colors.orangeAccent.withOpacity(0.1))
                  : Colors.blueAccent.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: provider.isSimulating
                ? (provider.isChargingReal
                    ? Colors.greenAccent.withOpacity(0.5)
                    : Colors.orangeAccent.withOpacity(0.5))
                : Colors.blueAccent.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.isSimulating
                        ? (provider.isChargingReal ? "⚡ IN CARICA" : "⏳ IN ATTESA")
                        : "🕐 PRONTA ALLE",
                    style: TextStyle(
                      color: provider.isSimulating
                          ? (provider.isChargingReal
                              ? Colors.greenAccent
                              : Colors.orangeAccent)
                          : Colors.blueAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.readyTime.format(context),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: provider.isSimulating
                              ? (provider.isChargingReal
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent)
                              : Colors.blueAccent,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
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
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: provider.readyTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueAccent,
            surface: Color(0xFF1C1C1E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) provider.updateReadyTime(picked);
  }
}