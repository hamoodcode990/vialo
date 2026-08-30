import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../widgets/app_button.dart';

/// First-launch-only skippable overlay (CLAUDE.md Step 6): static slides,
/// shown once and gated on [PlayerProfile.onboarded]. The optional
/// interactive-tutorial variant the prompt allows for wasn't built — static
/// slides were the explicit fallback and the pragmatic scope for this pass.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final String emoji;
  final String title;
  final String body;
  const _Slide(this.emoji, this.title, this.body);
}

const _slides = [
  _Slide(
    '🧪',
    'One shared board',
    'Duel modes: two players race to claim the same board. Solo: sort it yourself against the clock.',
  ),
  _Slide(
    '🔒',
    'Claim it to score it',
    'Complete a tube or tile and it locks in — sealed, scored, and yours for the rest of the game.',
  ),
  _Slide(
    '❤️🪙',
    'Lives and coins',
    'Lives limit level attempts and refill over time. Coins buy hints, undos, and cosmetics — earned by winning.',
  ),
  _Slide(
    '✨',
    "You're ready",
    "That's the whole game. Pick a mode and start claiming.",
  ),
];

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(profileControllerProvider.notifier).completeOnboarding();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
      return;
    }
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip', style: TextStyle(color: AppColors.mute, fontWeight: FontWeight.w700)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.p1 : AppColors.edge,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: AppButton(label: isLast ? "Let's play" : 'Next', onPressed: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ink2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [BoxShadow(color: AppColors.txt.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Text(slide.emoji, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.txt),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              slide.body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: AppColors.mute, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
