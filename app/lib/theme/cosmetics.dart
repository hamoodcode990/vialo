import 'package:flutter/material.dart';

/// Avatar and background cosmetics.
///
/// Avatars: 8 functional placeholders (icon-on-gradient-circle), standing
/// in for real hand-drawn art that hasn't been delivered into this repo
/// yet — see AvatarGlyph below for the "why pure-Flutter, not image
/// assets" note. Flag back once real SVG/PNG art exists; swapping it in
/// only means changing AvatarGlyph's build() to an Image/SvgPicture, the
/// ids and picker UI don't need to change.
///
/// Backgrounds are a hue-rotate on the animated gradient rather than
/// separate art, ported from decant.html's BGSKINS array.
class AvatarOption {
  final String id;
  final IconData icon;
  final List<Color> gradient;
  const AvatarOption(this.id, this.icon, this.gradient);
}

const List<AvatarOption> kAvatars = [
  AvatarOption('drop_blue', Icons.water_drop_rounded, [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
  AvatarOption('drop_pink', Icons.water_drop_rounded, [Color(0xFFFF8FB1), Color(0xFFE91E63)]),
  AvatarOption('star_gold', Icons.star_rounded, [Color(0xFFFFD54F), Color(0xFFF9A825)]),
  AvatarOption('leaf_green', Icons.eco_rounded, [Color(0xFF81C784), Color(0xFF2E7D32)]),
  AvatarOption('bolt_purple', Icons.bolt_rounded, [Color(0xFFB39DDB), Color(0xFF673AB7)]),
  AvatarOption('flame_orange', Icons.local_fire_department_rounded, [Color(0xFFFFB74D), Color(0xFFE65100)]),
  AvatarOption('moon_teal', Icons.nightlight_round, [Color(0xFF80CBC4), Color(0xFF00695C)]),
  AvatarOption('heart_red', Icons.favorite_rounded, [Color(0xFFEF9A9A), Color(0xFFC62828)]),
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

/// Icon-on-gradient-circle avatar rendering, shared by the header chip and
/// the profile picker grid so both stay pixel-for-pixel consistent.
class AvatarGlyph extends StatelessWidget {
  final AvatarOption avatar;
  final double size;
  final bool ring;

  const AvatarGlyph({super.key, required this.avatar, this.size = 38, this.ring = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ring ? Border.all(color: Colors.white, width: 2) : null,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: avatar.gradient),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Icon(avatar.icon, size: size * 0.52, color: Colors.white),
    );
  }
}
