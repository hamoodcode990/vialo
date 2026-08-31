import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game.dart';
import '../theme/app_colors.dart';
import '../theme/mode_info.dart';
import '../theme/spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/mode_entry.dart';
import 'game_screen_router.dart';

const Map<String, String> _kDifficultyBlurb = {
  'easy': 'Blunders often',
  'normal': 'Takes every claim it sees',
  'hard': 'Looks a move ahead',
};

/// Difficulty (and, for Pour, format) picker before a Quick Match. Port of
/// decant.html's `setup()`.
class QuickMatchSetupScreen extends ConsumerStatefulWidget {
  final String modeId;
  const QuickMatchSetupScreen({super.key, required this.modeId});

  @override
  ConsumerState<QuickMatchSetupScreen> createState() => _QuickMatchSetupScreenState();
}

class _QuickMatchSetupScreenState extends ConsumerState<QuickMatchSetupScreen> {
  String format = 'standard';

  @override
  Widget build(BuildContext context) {
    final info = modeInfoFor(widget.modeId);
    return Scaffold(
      appBar: AppBar(title: Text('${info.name} — duel the machine')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (widget.modeId == 'pour') ...[
              const _SectionLabel('FORMAT'),
              Row(
                children: [
                  Expanded(child: _SegButton(label: 'Standard', selected: format == 'standard', onTap: () => setState(() => format = 'standard'))),
                  const SizedBox(width: 8),
                  Expanded(child: _SegButton(label: 'Blitz', selected: format == 'blitz', onTap: () => setState(() => format = 'blitz'))),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  format == 'standard' ? '9 colours · about 90 seconds' : '7 colours · about 60 seconds',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
                ),
              ),
            ],
            const _SectionLabel('DIFFICULTY'),
            for (final key in ['easy', 'normal', 'hard'])
              AppCard(
                onTap: () => openMode(
                  context,
                  ref,
                  modeId: widget.modeId,
                  gameBuilder: (_) => GameScreenRouter.quickMatch(modeId: widget.modeId, aiKey: key, format: format),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kAiProfiles[key]!.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(_kDifficultyBlurb[key]!, style: const TextStyle(fontSize: 11.5, color: AppColors.mute)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.mute),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(text, style: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.mute)),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.p1.withValues(alpha: 0.1) : AppColors.ink2,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: selected ? AppColors.p1 : AppColors.outline, width: selected ? 3 : 2.5),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: selected ? AppColors.p1 : AppColors.txt)),
      ),
    );
  }
}
