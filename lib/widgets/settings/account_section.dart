import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:origo/l10n/app_localizations.dart';
import 'expandable_section.dart';

class AccountSection extends StatelessWidget {
  final Future<bool?> Function() onShowLogoutConfirm;
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onToggle;

  const AccountSection({
    super.key,
    required this.onShowLogoutConfirm,
    required this.isExpanded,
    required this.animation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    
    return ExpandableSection(
      title: "ACCOUNT",
      icon: Icons.account_circle,
      isExpanded: isExpanded,
      animation: animation,
      onTap: onToggle,
      child: Column(
        children: [
          // Email (read-only)
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
                  child: const Icon(Icons.email, color: Colors.cyanAccent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.email.toUpperCase(),
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? "-",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          // Change password
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, color: Colors.cyanAccent),
            ),
            title: Text(
              l10n.changePassword,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => _showChangePasswordDialog(context, l10n),
          ),
          const Divider(color: Colors.white10),
          // Logout
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

  void _showChangePasswordDialog(BuildContext context, AppLocalizations l10n) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.changePassword,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField(currentPwController, l10n.currentPassword),
              const SizedBox(height: 12),
              _buildPasswordField(newPwController, l10n.newPassword),
              const SizedBox(height: 12),
              _buildPasswordField(confirmPwController, l10n.confirmNewPassword),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => _changePassword(
              context,
              ctx,
              l10n,
              currentPwController.text,
              newPwController.text,
              confirmPwController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }

  Future<void> _changePassword(
    BuildContext pageContext,
    BuildContext dialogContext,
    AppLocalizations l10n,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (newPassword != confirmPassword) {
      _showSnackBar(pageContext, l10n.passwordMismatch, Colors.red);
      return;
    }
    if (newPassword.length < 6) {
      _showSnackBar(pageContext, l10n.passwordTooShort, Colors.red);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      if (dialogContext.mounted) Navigator.pop(dialogContext);
      if (pageContext.mounted) {
        _showSnackBar(pageContext, l10n.passwordChanged, Colors.green);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showSnackBar(pageContext, l10n.wrongPassword, Colors.red);
      } else {
        _showSnackBar(pageContext, e.message ?? "Error", Colors.red);
      }
    } catch (e) {
      _showSnackBar(pageContext, "$e", Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}
