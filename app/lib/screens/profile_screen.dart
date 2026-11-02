import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/level_curves.dart' show kSoloLevelCount;
import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/cosmetics.dart';
import '../theme/spacing.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_route.dart';
import '../widgets/app_toast.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Name, avatar, and a progress summary with links out to Stats/Settings.
/// Port of decant.html's `profile()`.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(profileProvider).name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final ctrl = ref.read(profileControllerProvider.notifier);
    final totalStars = profile.stars.values.fold<int>(0, (a, m) => a + m.values.fold(0, (x, y) => x + y));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _Label('NAME'),
            TextField(
              controller: _nameCtrl,
              maxLength: 16,
              decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
              onSubmitted: ctrl.setName,
              onEditingComplete: () => ctrl.setName(_nameCtrl.text),
            ),
            const _Label('AVATAR'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final a in kAvatars)
                  _AvatarTile(
                    avatar: a,
                    selected: profile.avatarId == a.id,
                    unlocked: (profile.levelProgress['solo'] ?? 1) >= a.unlockLevel,
                    onTap: () {
                      if ((profile.levelProgress['solo'] ?? 1) >= a.unlockLevel) {
                        ctrl.setAvatar(a.id);
                      } else {
                        AppToast.show('Unlocks at Solo level ${a.unlockLevel}', icon: Icons.lock_rounded);
                      }
                    },
                  ),
              ],
            ),
            const _Label('PROGRESS'),
            Row(
              children: [
                Expanded(child: _StatTile(icon: AppIcons.star, value: '$totalStars', label: 'total stars', color: AppColors.gold)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _StatTile(value: '${(profile.levelProgress['solo'] ?? 1) - 1}/$kSoloLevelCount', label: 'solo cleared', color: AppColors.p1)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _NavRow(label: 'Stats', onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const StatsScreen()))),
            _NavRow(label: 'Settings', onTap: () => Navigator.of(context).push(AppRoute(builder: (_) => const SettingsScreen()))),
          ],
        ),
      ),
    );
  }
}

/// One avatar-picker tile. Locked avatars show the actual mascot, dimmed and
/// desaturated, with a small lock badge giving the required level; tapping one
/// says when it unlocks via [onTap].
class _AvatarTile extends StatelessWidget {
  final AvatarOption avatar;
  final bool selected;
  final bool unlocked;
  final VoidCallback onTap;
  const _AvatarTile({required this.avatar, required this.selected, required this.unlocked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ink2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.violet : AppColors.outline,
            width: selected ? 3.5 : 2.5,
          ),
        ),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final art = AvatarGlyph(avatar: avatar, size: constraints.biggest.shortestSide * 0.8, ring: false);
            if (unlocked) return Center(child: art);
            return Stack(
              alignment: Alignment.center,
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(_kDesaturate),
                  child: Opacity(opacity: 0.55, child: art),
                ),
                Positioned(
                  right: 3,
                  bottom: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.outline, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.txt, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          '${avatar.unlockLevel}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.txt),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Mostly greyscale, keeping a hint of the mascot's colour.
const List<double> _kDesaturate = [
  0.40, 0.48, 0.12, 0, 0,
  0.25, 0.63, 0.12, 0, 0,
  0.25, 0.48, 0.27, 0, 0,
  0, 0, 0, 1, 0,
];

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(text, style: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.mute)),
      );
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final AppIcons? icon;
  const _StatTile({required this.value, required this.label, this.color = AppColors.txt, this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ink2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[AppIcon(icon!, size: 22), const SizedBox(width: 6)],
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mute)),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavRow({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.ink2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline, width: 3),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mute),
          ],
        ),
      ),
    );
  }
}
