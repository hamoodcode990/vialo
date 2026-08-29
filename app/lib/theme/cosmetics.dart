/// Avatar and background cosmetics, ported from decant.html's AVATARS and
/// BGSKINS arrays — emoji avatars need no image assets, and backgrounds are
/// a hue-rotate on the animated gradient rather than separate art.
class AvatarOption {
  final String id;
  final String emoji;
  const AvatarOption(this.id, this.emoji);
}

const List<AvatarOption> kAvatars = [
  AvatarOption('a1', '🦊'),
  AvatarOption('a2', '🐱'),
  AvatarOption('a3', '🦉'),
  AvatarOption('a4', '🐢'),
  AvatarOption('a5', '🦋'),
  AvatarOption('a6', '🐝'),
  AvatarOption('a7', '🐬'),
  AvatarOption('a8', '🦄'),
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
