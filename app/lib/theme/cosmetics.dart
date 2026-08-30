import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../profile/avatar_unlocks.dart';

/// Avatar and background cosmetics.
///
/// Avatars: 8 final mascot characters (bold vector, aggressive/competitive
/// style, dark neon-alchemy palette matching the app's own theme), shipped
/// as self-contained SVGs under assets/avatars/ — the tile background,
/// outline, and glyph are all baked into each file, so AvatarGlyph just
/// draws the SVG and clips it to match its own rounded-square art
/// direction. 3 are available from the start; the rest unlock at Solo
/// level milestones — see [unlockLevel] / avatar_unlocks.dart — this is
/// cosmetic/profile only and never gates any duel mode or difficulty.
///
/// Backgrounds are a hue-rotate on the animated gradient rather than
/// separate art, ported from decant.html's BGSKINS array.
class AvatarOption {
  final String id;
  final String asset;

  /// Solo level at which this becomes available; 1 = starting roster.
  final int unlockLevel;

  AvatarOption(this.id, this.asset) : unlockLevel = unlockLevelFor(id);
}

final List<AvatarOption> kAvatars = [
  // Starting roster — available from level 1, no unlock needed.
  AvatarOption('emerald_shard', 'assets/avatars/emerald_shard.svg'),
  AvatarOption('rose_fang', 'assets/avatars/rose_fang.svg'),
  AvatarOption('cyan_blitz', 'assets/avatars/cyan_blitz.svg'),
  // Level-gated — see avatar_unlocks.dart for the exact milestones (snapped
  // to Solo's chapter-start boundaries).
  AvatarOption('gold_fury', 'assets/avatars/gold_fury.svg'),
  AvatarOption('indigo_titan', 'assets/avatars/indigo_titan.svg'),
  AvatarOption('violet_void', 'assets/avatars/violet_void.svg'),
  AvatarOption('coral_rage', 'assets/avatars/coral_rage.svg'),
  AvatarOption('lime_venom', 'assets/avatars/lime_venom.svg'),
];

AvatarOption avatarById(String id) =>
    kAvatars.firstWhere((a) => a.id == id, orElse: () => kAvatars.first);

/// "gold_fury" -> "Gold Fury" — every avatar id is already a clean
/// snake_case name, so title-casing it is all display copy needs.
String avatarDisplayName(String id) =>
    id.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

/// A background skin: [hueDegrees] rotates the animated brand-wash gradient,
/// mirroring the HTML's `hue-rotate()` CSS filter approach.
class BackgroundSkin {
  final String id;
  final String name;
  final int price;
  final double hueDegrees;
  const BackgroundSkin(this.id, this.name, this.price, this.hueDegrees);
}

const List<BackgroundSkin> kBackgroundSkins = [
  BackgroundSkin('bg1', 'Atelier', 0, 0),
  BackgroundSkin('bg2', 'Rose Garden', 300, -25),
  BackgroundSkin('bg3', 'Verdant', 300, 70),
];

BackgroundSkin backgroundSkinById(String id) => kBackgroundSkins.firstWhere(
      (b) => b.id == id,
      orElse: () => kBackgroundSkins.first,
    );

/// Avatar tile rendering, shared by the header chip and the profile picker
/// grid so both stay pixel-for-pixel consistent. The SVG art is already a
/// rounded square (rx 36 on a 200x200 canvas, inset 4px — a ~0.18 corner
/// ratio), so this clips to that same ratio rather than forcing a circle.
class AvatarGlyph extends StatelessWidget {
  final AvatarOption avatar;
  final double size;
  final bool ring;

  const AvatarGlyph({super.key, required this.avatar, this.size = 38, this.ring = true});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.18;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: ring ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SvgPicture.asset(avatar.asset, width: size, height: size, fit: BoxFit.cover),
      ),
    );
  }
}
