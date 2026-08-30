import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/mode_info.dart';
import '../theme/spacing.dart';

/// Lifetime win/loss breakdown per mode. Port of decant.html's `stats()`.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final s = profile.stats;
    final games = s.w + s.l + s.sw + s.sl + s.fw + s.fl + s.rw + s.rl;
    final wins = s.w + s.sw + s.fw + s.rw;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ModeRow(label: 'POUR', w: s.w, l: s.l, accent: modeInfoFor('pour').color),
            _ModeRow(label: 'SPLIT', w: s.sw, l: s.sl, accent: modeInfoFor('split').color),
            _ModeRow(label: 'FUSE', w: s.fw, l: s.fl, accent: modeInfoFor('fuse').color),
            _ModeRow(label: 'RECIPE', w: s.rw, l: s.rl, accent: modeInfoFor('recipe').color),
            const _Label('OVERALL'),
            Row(
              children: [
                Expanded(child: _Stat(value: '${s.bs}', label: 'best streak', color: AppColors.p2)),
                const SizedBox(width: 8),
                Expanded(child: _Stat(value: '${s.best}', label: 'most claimed')),
                const SizedBox(width: 8),
                Expanded(child: _Stat(value: '${s.pp}', label: 'pass & play')),
              ],
            ),
            const _Label('DETAILED'),
            Row(
              children: [
                Expanded(child: _Stat(value: '$games', label: 'games played')),
                const SizedBox(width: 8),
                Expanded(child: _Stat(value: games > 0 ? '${(wins / games * 100).round()}%' : '—', label: 'overall rate')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Stats are saved on this device — they\'ll be here next time you open Vialo.',
              style: TextStyle(fontSize: 12, color: AppColors.mute),
            ),
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

class _ModeRow extends StatelessWidget {
  final String label;
  final int w;
  final int l;
  final Color accent;
  const _ModeRow({required this.label, required this.w, required this.l, required this.accent});

  @override
  Widget build(BuildContext context) {
    final total = w + l;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              Text(label, style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800, color: accent)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _Stat(value: '$w', label: 'wins', color: accent)),
              const SizedBox(width: 8),
              Expanded(child: _Stat(value: '$l', label: 'losses')),
              const SizedBox(width: 8),
              Expanded(child: _Stat(value: total > 0 ? '${(w / total * 100).round()}%' : '—', label: 'rate')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const _Stat({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ink2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color ?? AppColors.txt)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.mute)),
        ],
      ),
    );
  }
}
