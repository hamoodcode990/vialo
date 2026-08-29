/// A small fixed spacing/radius scale — never a one-off magic number at a
/// call site. Mirrors the paddings/border-radii actually used in
/// decant.html's chunky-card restyle.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
}

class AppRadius {
  AppRadius._();
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 20;
  static const double pill = 999;
}
