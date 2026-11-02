import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// The app's custom icon set, matching the avatar mascots: bold navy outline,
/// flat fill, one highlight, one shade, app palette. Every icon in the UI that
/// used to be an emoji lives in assets/icons/.
enum AppIcons {
  addTube('add_tube'),
  bolt('bolt'),
  bulb('bulb'),
  coin('coin'),
  flame('flame'),
  gem('gem'),
  heart('heart'),
  hourglass('hourglass'),
  lock('lock'),
  map('map'),
  passPlay('pass_play'),
  play('play'),
  pour('pour'),
  scroll('scroll'),
  settings('settings'),
  sparkle('sparkle'),
  split('split'),
  star('star'),
  stats('stats'),
  store('store');

  final String file;
  const AppIcons(this.file);

  String get asset => 'assets/icons/$file.svg';
}

class AppIcon extends StatelessWidget {
  final AppIcons icon;
  final double size;
  const AppIcon(this.icon, {super.key, this.size = 18});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(icon.asset, width: size, height: size);
}

/// `40 ●`: a number, a space, and the gold coin. The one way coins are written.
class CoinAmount extends StatelessWidget {
  final int amount;
  final TextStyle? style;
  final double iconSize;
  const CoinAmount(this.amount, {super.key, this.style, this.iconSize = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$amount', style: style ?? const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        AppIcon(AppIcons.coin, size: iconSize),
      ],
    );
  }
}
