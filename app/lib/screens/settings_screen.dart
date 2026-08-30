import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../account/account_controller.dart';
import '../monetization/monetization_controller.dart';
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Sound, match length, and restore-purchases. Port of decant.html's mute
/// toggle + best-of picker (scattered there; consolidated here as its own
/// screen per flutter_port_plan.md's Phase 4 screen list).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final ctrl = ref.read(profileControllerProvider.notifier);
    final monetize = ref.watch(monetizationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _Card(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Music and sound effects', style: TextStyle(color: AppColors.mute, fontSize: 12)),
                value: !profile.muted,
                onChanged: (on) => ctrl.setMuted(!on),
              ),
            ),
            const _Label('QUICK MATCH LENGTH'),
            _Card(
              child: Row(
                children: [
                  Expanded(child: _SegButton(label: 'Best of 3', selected: profile.bestOf == 3, onTap: () => ctrl.setBestOf(3))),
                  const SizedBox(width: 8),
                  Expanded(child: _SegButton(label: 'Best of 5', selected: profile.bestOf == 5, onTap: () => ctrl.setBestOf(5))),
                ],
              ),
            ),
            const _Label('ACCOUNT'),
            _Card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Restore purchases', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  monetize.isStoreAvailable ? 'Reapplies any past purchase (e.g. Remove Ads)' : 'Store not configured yet',
                  style: const TextStyle(color: AppColors.mute, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mute),
                onTap: () async {
                  final message = await monetize.restore();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                },
              ),
            ),
            const _Label('SYNC PROGRESS'),
            _AppleAccountCard(appleUserId: profile.appleUserId),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(text, style: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.mute)),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(color: AppColors.ink2, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.edge)),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class _SegButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.p1.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: selected ? AppColors.p1.withValues(alpha: 0.4) : AppColors.edge),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? AppColors.p1 : AppColors.txt)),
      ),
    );
  }
}

/// Sign in with Apple + iCloud progress sync (CLAUDE.md Step 7) — entirely
/// optional, never blocks play. Shows a sign-in row when unlinked, or the
/// linked state with a manual "Sync now" and "Sign out" once linked.
class _AppleAccountCard extends ConsumerWidget {
  final String? appleUserId;
  const _AppleAccountCard({required this.appleUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(accountControllerProvider);
    if (appleUserId == null) {
      return _Card(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Sign in with Apple', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text(
            'Optional — keeps progress, coins, and lives in sync across your devices',
            style: TextStyle(color: AppColors.mute, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mute),
          onTap: () => _handleSignIn(context, ctrl),
        ),
      );
    }
    return _Card(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Signed in with Apple', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Progress syncs to iCloud', style: TextStyle(color: AppColors.mute, fontSize: 12)),
            trailing: TextButton(
              onPressed: ctrl.signOut,
              child: const Text('Sign out', style: TextStyle(color: AppColors.hot, fontWeight: FontWeight.w700)),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sync now', style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.cloud_upload_outlined, color: AppColors.mute),
            onTap: () async {
              final ok = await ctrl.pushToCloud();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Progress synced to iCloud' : "Couldn't reach iCloud")),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context, AccountController ctrl) async {
    final outcome = await ctrl.signIn();
    if (!context.mounted) return;
    switch (outcome) {
      case LinkSynced():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in — progress synced to iCloud')),
        );
      case LinkNeedsRestoreChoice(remote: final remote):
        final restore = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Restore progress?'),
            content: const Text(
              "This Apple ID already has saved progress from another device. Restore it here, or keep what's on this device?",
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep this device')),
              TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restore')),
            ],
          ),
        );
        if (restore == true) {
          ctrl.restoreFromCloud(remote);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress restored from iCloud')));
          }
        } else {
          await ctrl.pushToCloud();
        }
      case LinkFailed(message: final message):
        if (message.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
    }
  }
}
