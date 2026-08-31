import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/mode_tutorials.dart';
import '../theme/spacing.dart';
import '../widgets/app_button.dart';

/// A mode's how-to-play walkthrough — a short, visual PageView of
/// [TutorialStep]s. Two ways in:
///
/// - First-time, via `widgets/mode_entry.dart`'s `openMode`: pops `true` (via
///   "Let's play" or "Skip") so the caller knows to continue into the game.
/// - Replay, via the mode hub's help icon: pops normally, no game waiting.
class ModeTutorialScreen extends StatefulWidget {
  final String modeId;

  /// True when this is the auto-shown, gate-the-first-game presentation —
  /// shows "Skip" and pops `true` so the caller proceeds to the game.
  /// False (replay from the help icon) shows a plain "Close" instead.
  final bool firstTime;

  const ModeTutorialScreen({super.key, required this.modeId, this.firstTime = false});

  @override
  State<ModeTutorialScreen> createState() => _ModeTutorialScreenState();
}

class _ModeTutorialScreenState extends State<ModeTutorialScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  late final List<TutorialStep> _steps = tutorialStepsFor(widget.modeId);
  late final TutorialModeMeta _meta = tutorialMetaFor(widget.modeId);

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _finish() => Navigator.of(context).pop(widget.firstTime ? true : null);

  void _next() {
    if (_page == _steps.length - 1) {
      _finish();
      return;
    }
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Text(_meta.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_meta.name} — how to play',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _meta.color),
                    ),
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      widget.firstTime ? 'Skip' : 'Close',
                      style: const TextStyle(color: AppColors.mute, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _StepView(step: _steps[i], accent: _meta.color),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? _meta.color : AppColors.edge,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: isLast ? (widget.firstTime ? "Let's play" : 'Got it') : 'Next',
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  final TutorialStep step;
  final Color accent;
  const _StepView({required this.step, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 132,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ink2,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.outline, width: 2.5),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.16), blurRadius: 20, spreadRadius: 1)],
            ),
            child: step.visual(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.txt),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              step.body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: AppColors.mute, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
