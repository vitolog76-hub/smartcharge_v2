import 'package:flutter/material.dart';
import 'package:origo/l10n/app_localizations.dart';  // AGGIUNGI QUESTO IMPORT
import 'package:origo/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'expandable_section.dart';

class LanguageSection extends StatelessWidget {
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onToggle;

  const LanguageSection({
    super.key,
    required this.isExpanded,
    required this.animation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;  // AGGIUNGI QUESTA RIGA
    
    return ExpandableSection(
      title: l10n.languageSection,  // CAMBIA DA "LINGUA" A l10n.languageSection
      icon: Icons.language,
      isExpanded: isExpanded,
      animation: animation,
      onTap: onToggle,
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.language, color: Colors.purple),
            ),
            title: const Text("Lingua / Language"),  // QUESTO PUOI LASCIARLO COSÌ
            subtitle: Text(_getLanguageName(localeProvider.locale)),
            trailing: DropdownButton<Locale>(
              value: localeProvider.locale,
              dropdownColor: const Color(0xFF0F172A),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  localeProvider.setLocale(newLocale);
                }
              },
              items: const [
                DropdownMenuItem(value: Locale('it', 'IT'), child: Text('🇮🇹 Italiano')),
                DropdownMenuItem(value: Locale('en', 'US'), child: Text('🇬🇧 English')),
                DropdownMenuItem(value: Locale('es', 'ES'), child: Text('🇪🇸 Español')),
                DropdownMenuItem(value: Locale('fr', 'FR'), child: Text('🇫🇷 Français')),
                DropdownMenuItem(value: Locale('de', 'DE'), child: Text('🇩🇪 Deutsch')),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'it': return 'Italiano';
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      default: return 'Italiano';
    }
  }
}