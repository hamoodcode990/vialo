/// Lifetime win/loss stats across every duel mode plus Pass & Play, ported
/// from decant.html's `S.st` and the bookkeeping in its `finish()`.
class DuelStats {
  int w, l, pp, best, streak, bs, fw, fl, sw, sl, rw, rl;

  DuelStats({
    this.w = 0,
    this.l = 0,
    this.pp = 0,
    this.best = 0,
    this.streak = 0,
    this.bs = 0,
    this.fw = 0,
    this.fl = 0,
    this.sw = 0,
    this.sl = 0,
    this.rw = 0,
    this.rl = 0,
  });

  /// Records the result of a bot duel in [kind] ('pour'/'split'/'fuse'/
  ///'recipe'), where [won] is whether the human player won and [myScore]
  /// is the human's final score (tracked as a lifetime high-water mark).
  void recordAiResult(String kind, bool won, int myScore) {
    switch (kind) {
      case 'pour':
        won ? w++ : l++;
        break;
      case 'split':
        won ? sw++ : sl++;
        break;
      case 'fuse':
        won ? fw++ : fl++;
        break;
      case 'recipe':
        won ? rw++ : rl++;
        break;
    }
    if (won) {
      streak++;
      if (streak > bs) bs = streak;
    } else {
      streak = 0;
    }
    if (myScore > best) best = myScore;
  }

  /// A completed local Pass & Play match (no win/loss tracked against the
  /// player, same as decant.html's `s.pp++`).
  void recordPassPlay() => pp++;

  factory DuelStats.fromJson(Map<String, dynamic> json) => DuelStats(
        w: json['w'] as int? ?? 0,
        l: json['l'] as int? ?? 0,
        pp: json['pp'] as int? ?? 0,
        best: json['best'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
        bs: json['bs'] as int? ?? 0,
        fw: json['fw'] as int? ?? 0,
        fl: json['fl'] as int? ?? 0,
        sw: json['sw'] as int? ?? 0,
        sl: json['sl'] as int? ?? 0,
        rw: json['rw'] as int? ?? 0,
        rl: json['rl'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'w': w,
        'l': l,
        'pp': pp,
        'best': best,
        'streak': streak,
        'bs': bs,
        'fw': fw,
        'fl': fl,
        'sw': sw,
        'sl': sl,
        'rw': rw,
        'rl': rl,
      };
}
