import 'package:flutter/material.dart';
import 'package:origo/l10n/app_localizations.dart';
import 'expandable_section.dart';

class AccountSection extends StatelessWidget {
  final TextEditingController idController;
  final VoidCallback onImport;
  final Future<bool?> Function() onShowLogoutConfirm;
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onToggle;

  const AccountSection({
    super.key,
    required this.idController,
    required this.onImport,
    required this.onShowLogoutConfirm,
    required this.isExpanded,
    required this.animation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ExpandableSection(
      title: "ACCOUNT",
      icon: Icons.account_circle,
      isExpanded: isExpanded,
      animation: animation,
      onTap: onToggle,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_sync, color: Colors.cyanAccent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.userId.toUpperCase(),
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: idController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "ID sincronizzazione",
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onImport,
                  icon: const Icon(Icons.cloud_download, color: Colors.cyanAccent),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.redAccent),
            ),
            title: Text(
              l10n.logout,
              style: const TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              final confirm = await onShowLogoutConfirm();
              if (confirm == true) {
                // Logout gestito dalla pagina principale
              }
            },
          ),
        ],
      ),
    );
  }
}