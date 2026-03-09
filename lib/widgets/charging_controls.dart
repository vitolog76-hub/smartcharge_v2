import 'package:flutter/material.dart';
import 'package:origo/providers/home_provider.dart';
import 'package:origo/l10n/app_localizations.dart';

class ChargingControls extends StatelessWidget {
  final HomeProvider provider;

  const ChargingControls({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 🔥 POTENZA (SENZA input manuale)
              _buildPowerSlider(l10n),
              
              const SizedBox(height: 16),
              
              // 🔥 RANGESLIDER con INPUT MANUALE per SOC
              _buildRangeSliderWithInput(l10n),
            ],
          );
        },
      ),
    );
  }

  // 🔥 Slider per la potenza (senza input manuale)
  Widget _buildPowerSlider(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: Colors.blueAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              l10n.power,
              style: TextStyle(
                color: Colors.blueAccent.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Text(
                "${provider.wallboxPwr.toStringAsFixed(1)} kW",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildSmallButton(Icons.remove, Colors.blueAccent, () {
              if (provider.wallboxPwr - 0.1 >= 1.0) {
                provider.updateWallboxPwr(provider.wallboxPwr - 0.1);
              }
            }),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.blueAccent.withOpacity(0.1),
                  thumbColor: Colors.blueAccent,
                ),
                child: Slider(
                  value: provider.wallboxPwr,
                  min: 1.0,
                  max: 22.0,
                  onChanged: provider.isSimulating 
                      ? (v) {} 
                      : (newValue) => provider.updateWallboxPwr(newValue),
                ),
              ),
            ),
            _buildSmallButton(Icons.add, Colors.blueAccent, () {
              if (provider.wallboxPwr + 0.1 <= 22.0) {
                provider.updateWallboxPwr(provider.wallboxPwr + 0.1);
              }
            }),
          ],
        ),
      ],
    );
  }

  // 🔥 RangeSlider con INPUT MANUALE per SOC
  Widget _buildRangeSliderWithInput(AppLocalizations l10n) {
    final TextEditingController startController = TextEditingController(
      text: provider.currentSoc.toInt().toString()
    );
    final TextEditingController endController = TextEditingController(
      text: provider.targetSoc.toInt().toString()
    );

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intestazione
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.battery_charging_full, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    l10n.batteryRange,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            // RangeSlider
            RangeSlider(
              values: RangeValues(provider.currentSoc, provider.targetSoc),
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: Colors.greenAccent,
              inactiveColor: Colors.greenAccent.withOpacity(0.2),
              labels: RangeLabels(
                '${provider.currentSoc.toInt()}%',
                '${provider.targetSoc.toInt()}%',
              ),
              onChanged: provider.isSimulating
                  ? null
                  : (RangeValues newValues) {
                      if (newValues.start != provider.currentSoc) {
                        provider.updateCurrentSoc(newValues.start);
                        startController.text = newValues.start.toInt().toString();
                      }
                      if (newValues.end != provider.targetSoc) {
                        provider.updateTargetSoc(newValues.end);
                        endController.text = newValues.end.toInt().toString();
                      }
                    },
            ),
            
            // Input manuali per SOC Iniziale e Finale
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Input SOC Iniziale
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: startController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.orangeAccent.withOpacity(0.3)),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.orangeAccent.withOpacity(0.3)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.orangeAccent),
                              ),
                              suffixText: '%',
                              suffixStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                            ),
                            onSubmitted: (newValue) {
                              int? parsed = int.tryParse(newValue);
                              if (parsed != null) {
                                int clamped = parsed.clamp(0, provider.targetSoc.toInt() - 1);
                                provider.updateCurrentSoc(clamped.toDouble());
                                startController.text = clamped.toString();
                              } else {
                                startController.text = provider.currentSoc.toInt().toString();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Input SOC Finale
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.3)),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.3)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.greenAccent),
                              ),
                              suffixText: '%',
                              suffixStyle: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                            ),
                            onSubmitted: (newValue) {
                              int? parsed = int.tryParse(newValue);
                              if (parsed != null) {
                                int clamped = parsed.clamp(provider.currentSoc.toInt() + 1, 100);
                                provider.updateTargetSoc(clamped.toDouble());
                                endController.text = clamped.toString();
                              } else {
                                endController.text = provider.targetSoc.toInt().toString();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}