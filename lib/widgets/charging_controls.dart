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

 // 🔥 AGGIUNTO SOLO + E - AI LATI DEI TEXTFIELD ORIGINALI
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
            // Intestazione (Invariata)
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
            
            // RangeSlider (Invariato)
            RangeSlider(
              values: RangeValues(provider.currentSoc, provider.targetSoc),
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: Colors.greenAccent,
              inactiveColor: Colors.greenAccent.withOpacity(0.2),
              onChanged: provider.isSimulating
                  ? null
                  : (RangeValues newValues) {
                      provider.updateCurrentSoc(newValues.start);
                      provider.updateTargetSoc(newValues.end);
                      setState(() {});
                    },
            ),
            
            // Riga Input con l'aggiunta dei tasti + e -
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- SOC INIZIALE CON TASTI ---
                  Expanded(
                    child: Row(
                      children: [
                        _buildSmallButton(Icons.remove, Colors.orangeAccent, () {
                          if (provider.currentSoc > 0) {
                            provider.updateCurrentSoc(provider.currentSoc - 1);
                            setState(() {});
                          }
                        }),
                        Expanded(
                          child: TextField(
                            controller: startController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: const InputDecoration(isDense: true, border: InputBorder.none, suffixText: '%'),
                            onSubmitted: (v) => provider.updateCurrentSoc(double.tryParse(v) ?? provider.currentSoc),
                          ),
                        ),
                        _buildSmallButton(Icons.add, Colors.orangeAccent, () {
                          if (provider.currentSoc < provider.targetSoc - 1) {
                            provider.updateCurrentSoc(provider.currentSoc + 1);
                            setState(() {});
                          }
                        }),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),

                  // --- SOC FINALE CON TASTI ---
                  Expanded(
                    child: Row(
                      children: [
                        _buildSmallButton(Icons.remove, Colors.greenAccent, () {
                          if (provider.targetSoc > provider.currentSoc + 1) {
                            provider.updateTargetSoc(provider.targetSoc - 1);
                            setState(() {});
                          }
                        }),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: const InputDecoration(isDense: true, border: InputBorder.none, suffixText: '%'),
                            onSubmitted: (v) => provider.updateTargetSoc(double.tryParse(v) ?? provider.targetSoc),
                          ),
                        ),
                        _buildSmallButton(Icons.add, Colors.greenAccent, () {
                          if (provider.targetSoc < 100) {
                            provider.updateTargetSoc(provider.targetSoc + 1);
                            setState(() {});
                          }
                        }),
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