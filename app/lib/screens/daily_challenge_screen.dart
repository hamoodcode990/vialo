import 'solo_game_screen.dart';

/// One shared Solo puzzle a day — a thin wrapper over [SoloGameScreen] in
/// its daily mode.
class DailyChallengeScreen extends SoloGameScreen {
  const DailyChallengeScreen({super.key}) : super(isDaily: true);
}
