/// Solo-level milestones at which each avatar unlocks ("swap in final
/// avatars + level-gated unlock system" batch). Any avatar id not listed
/// here is part of the starting roster, available from level 1.
///
/// Pure data, no Flutter — [PlayerProfile] (deliberately Flutter-free, see
/// its own doc comment) reads this directly to detect unlock crossings;
/// theme/cosmetics.dart (the UI layer) reads the same numbers for
/// AvatarOption.unlockLevel. One source of truth for both.
///
/// Numbers are snapped to Solo's chapter-start boundaries (24 levels/
/// chapter, see theme/chapters.dart) rather than the requested 25/50/100/
/// 150/200 literally, per the batch's own instruction to prefer the
/// nearest chapter boundary: 25 (already a chapter start, unchanged),
/// 50->49, 100->97, 150->145, 200->193. See the batch report for the full
/// chapter-by-chapter mapping.
const Map<String, int> kAvatarUnlockLevels = {
  'gold_fury': 25, // Chapter 2 "The Deep Sort"
  'indigo_titan': 49, // Chapter 3 "Emerald Hollow"
  'violet_void': 97, // Chapter 5 "Plum Passage"
  'coral_rage': 145, // Chapter 7 "The Long Bench"
  'lime_venom': 193, // Chapter 9 "The Amber Wing"
};

int unlockLevelFor(String avatarId) => kAvatarUnlockLevels[avatarId] ?? 1;
