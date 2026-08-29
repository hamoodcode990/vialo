import 'package:flutter/material.dart';

/// A cosmetic set of 9 tube/liquid colours. Never changes the board, rules,
/// or difficulty — see decant.html's PAL array and its deuteranopia-audit
/// comment (Machado et al. 2009 matrix + CIE76 pairwise distance).
class TubePalette {
  final String id;
  final String name;
  final int price; // coins; 0 = free/default
  final List<Color> colors;

  const TubePalette({
    required this.id,
    required this.name,
    required this.price,
    required this.colors,
  });

  Color operator [](int colorIndex) => colors[colorIndex % colors.length];
}

const List<TubePalette> kTubePalettes = [
  TubePalette(
    id: 'lab',
    name: 'Laboratory',
    price: 0,
    colors: [
      Color(0xFFFF5C6C),
      Color(0xFF3D9BE9),
      Color(0xFFFFC93C),
      Color(0xFF3DD151),
      Color(0xFF6A0DAD),
      Color(0xFF3DD1CD),
      Color(0xFFFF8A3D),
      Color(0xFFE8EDF2),
      Color(0xFF5D5FEF),
    ],
  ),
  TubePalette(
    id: 'hc',
    name: 'High contrast',
    price: 0,
    colors: [
      Color(0xFF0173B2),
      Color(0xFFDE8F05),
      Color(0xFF029E73),
      Color(0xFFD55E00),
      Color(0xFFCC78BC),
      Color(0xFF56B4E9),
      Color(0xFFF0E442),
      Color(0xFFFFFFFF),
      Color(0xFF949494),
    ],
  ),
  TubePalette(
    id: 'ink',
    name: 'Ink & Brass',
    price: 300,
    colors: [
      Color(0xFFC1666B),
      Color(0xFF48A9A6),
      Color(0xFFE4B363),
      Color(0xFF7FB069),
      Color(0xFF9A7AA0),
      Color(0xFF6E8FC5),
      Color(0xFFD4A276),
      Color(0xFFF4F1DE),
      Color(0xFF8A9B8E),
    ],
  ),
  TubePalette(
    id: 'neon',
    name: 'Neon',
    price: 500,
    colors: [
      Color(0xFFFF3864),
      Color(0xFF2DE2E6),
      Color(0xFFFDE047),
      Color(0xFF00FF9F),
      Color(0xFFB967FF),
      Color(0xFF01FFC3),
      Color(0xFFFF6B35),
      Color(0xFFFFFFFF),
      Color(0xFF6C5CE7),
    ],
  ),
  TubePalette(
    id: 'deep',
    name: 'Deep Sea',
    price: 800,
    colors: [
      Color(0xFF06AED5),
      Color(0xFF086788),
      Color(0xFFFFE135),
      Color(0xFF5FAD56),
      Color(0xFFDD1C1A),
      Color(0xFF7B2CBF),
      Color(0xFFFF9F1C),
      Color(0xFFF1FAEE),
      Color(0xFF4361EE),
    ],
  ),
];

TubePalette tubePaletteById(String id) =>
    kTubePalettes.firstWhere((p) => p.id == id, orElse: () => kTubePalettes.first);
