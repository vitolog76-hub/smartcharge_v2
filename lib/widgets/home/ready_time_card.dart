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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // 🔥 RIDOTTO
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
                        ? (provider.isChargingReal ? "IN CARICA" : "IN ATTESA")
                        : "PRONTA ALLE",
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
                      fontSize: 24, // 🔥 RIDOTTO da 32 a 24
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
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8), // 🔥 RIDOTTO
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
                size: 22, // 🔥 RIDOTTO
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