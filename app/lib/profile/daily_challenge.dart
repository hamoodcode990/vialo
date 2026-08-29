/// Daily-challenge streak state, ported from decant.html's `S.daily`.
class DailyChallenge {
  /// `yyyy-mm-dd`, or null if never completed.
  String? lastDate;
  int streak;

  DailyChallenge({this.lastDate, this.streak = 0});

  factory DailyChallenge.fromJson(Map<String, dynamic> json) =>
      DailyChallenge(
        lastDate: json['lastDate'] as String?,
        streak: json['streak'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'lastDate': lastDate, 'streak': streak};
}

String dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
