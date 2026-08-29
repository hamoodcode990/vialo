/// Shared tuned constants across all four duel-mode engines.
///
/// Do not change any of these without being asked — each one fixes a real
/// bug found by simulation (see CLAUDE.md in the HTML reference implementation).
library;

const int kCap = 4;
const int kStall = 24;

/// True if [tube] is completely full and every slot holds the same colour
/// (mirrors the JS `uni` helper in decant.html).
bool isUniformFullTube(List<int> tube) {
  if (tube.length != kCap) return false;
  final first = tube[0];
  for (final v in tube) {
    if (v != first) return false;
  }
  return true;
}
