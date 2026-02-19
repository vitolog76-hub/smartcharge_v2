import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/widgets/battery_indicator.dart';
import 'package:smartcharge_v2/widgets/status_card.dart';

class BatteryStatusRow extends StatelessWidget {
  final HomeProvider provider;

  const BatteryStatusRow({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: BatteryIndicator(
            percent: provider.currentSoc,
            isCharging: provider.isChargingReal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: StatusCard(
            duration: provider.duration,
            energy: provider.energyNeeded,
            power: provider.wallboxPwr,
          ),
        ),
      ],
    );
  }
}