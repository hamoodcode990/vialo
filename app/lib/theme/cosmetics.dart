import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Avatar and background cosmetics.
///
/// Avatars: 8 placeholder icons (flat vector, icon-on-gradient-tile),
/// shipped as self-contained SVGs under assets/avatars/ — the tile
/// background, gradient, and glyph are all baked into each file, so
/// AvatarGlyph just draws the SVG and clips it to match its own rounded-
/// square art direction. Still functional placeholders, not final art.
///
/// Backgrounds are a hue-rotate on the animated gradient rather than
/// separate art, ported from decant.html's BGSKINS array.
class AvatarOption {
  final String id;
  final String asset;
  const AvatarOption(this.id, this.asset);
}

const List<AvatarOption> kAvatars = [
  AvatarOption('drop_blue', 'assets/avatars/drop_blue.svg'),
  AvatarOption('drop_pink', 'assets/avatars/drop_pink.svg'),
  AvatarOption('star_gold', 'assets/avatars/star_gold.svg'),
  AvatarOption('leaf_green', 'assets/avatars/leaf_green.svg'),
  AvatarOption('bolt_purple', 'assets/avatars/bolt_purple.svg'),
  AvatarOption('flame_orange', 'assets/avatars/flame_orange.svg'),
  AvatarOption('moon_teal', 'assets/avatars/moon_teal.svg'),
  AvatarOption('heart_red', 'assets/avatars/heart_red.svg'),
];

AvatarOption avatarById(String id) =>
    kAvatars.firstWhere((a) => a.id == id, orElse: () => kAvatars.first);

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
/// rounded square (rx 44 on a 200x200 canvas — a ~0.22 corner ratio), so
/// this clips to that same ratio rather than forcing a circle.
class AvatarGlyph extends StatelessWidget {
  final AvatarOption avatar;
  final double size;
  final bool ring;

  const AvatarGlyph({super.key, required this.avatar, this.size = 38, this.ring = true});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
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
