import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/profile_controller.dart';
import '../../../auth/presentation/auth_routes.dart';
import '../pages/edit_profile_page.dart';
import '../pages/change_password_page.dart';
import '../pages/order_history_page.dart';
import '../pages/static_content_page.dart';
import '../pages/language_page.dart';
import 'logout_dialog.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  static const _pushPrefKey = 'buyer_push_notifications_enabled';

  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _pushNotifications =
        ref.read(keyValueStorageProvider).readBool(_pushPrefKey) ?? true;
  }

  void _setPushNotifications(bool enabled) {
    setState(() => _pushNotifications = enabled);
    ref.read(keyValueStorageProvider).writeBool(_pushPrefKey, enabled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final profileAsync = ref.watch(profileControllerProvider);
    final profile = profileAsync.asData?.value;
    final avatarUrl = profile?.avatarUrl.trim() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          l10n.profile,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243041),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 10),
          // Profile Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFF3F8FC),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person,
                            size: 30,
                            color: Color(0xFF9CA6B3),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFF9CA6B3),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                (profile?.name.isNotEmpty ?? false)
                    ? profile!.name
                    : authState.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF243041),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          _ProfileMenuItem(
            icon: Icons.edit_outlined,
            title: l10n.editProfile,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.lock_outline,
            title: l10n.changePassword,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.assignment_outlined,
            title: l10n.orderHistory,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.info_outline,
            title: l10n.aboutApp,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaticContentPage(
                  title: l10n.aboutApp,
                  content: l10n.aboutAppContent,
                ),
              ),
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaticContentPage(
                  title: l10n.privacyPolicy,
                  content: l10n.privacyPolicyContent,
                ),
              ),
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.description_outlined,
            title: l10n.termsAndConditions,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaticContentPage(
                  title: l10n.termsAndConditions,
                  content: l10n.termsAndConditionsContent,
                ),
              ),
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.language_outlined,
            title: l10n.language,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguagePage()),
            ),
          ),

          // Push Notifications Toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF243041),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.pushNotifications,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF243041),
                    ),
                  ),
                ),
                Switch(
                  value: _pushNotifications,
                  onChanged: _setPushNotifications,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF5A91C4),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE8EBF0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Log Out
          GestureDetector(
            onTap: () async {
              final confirm = await LogoutDialog.show(context);
              if (confirm == true) {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AuthRoutes.signIn,
                    (route) => false,
                  );
                }
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_outlined,
                    color: Color(0xFF5A91C4),
                    size: 22,
                  ),
                   SizedBox(width: 16),
                  Text(
                    l10n.logOut,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A91C4),
                    ),
                  ),
                   Spacer(),
                  Icon(Icons.chevron_right, color: Color(0xFF5A91C4), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF243041), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF243041),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8E98A5), size: 20),
          ],
        ),
      ),
    );
  }
}
