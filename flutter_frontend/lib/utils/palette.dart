// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

final smokyBlack = Color(0xFF5A6B0F);
final drabDarkBrown = Color(0xFF262A10);
final brown = Color(0xFF54442B);
final honeyDew = Color(0xFFE8F7EE);
final pigmentGreen = Color(0xFF53A548);
final seaGreen = Color(0xFF4C934C);

class ColorPalette {
  Color primary;
  Color secondary;
  Color tertiary;
  Color? quaternary;
  Color white;
  Color black;
  Color transparent;
  List<Color> extras;
  ColorPalette(
      {required this.primary,
      required this.secondary,
      required this.tertiary,
      this.extras = const [],
      this.quaternary,
      this.white = Colors.white,
      this.black = Colors.black,
      this.transparent = Colors.transparent});

  ColorPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? quaternary,
    Color? white,
    Color? black,
  }) {
    return ColorPalette(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      quaternary: quaternary ?? this.quaternary,
      white: white ?? this.white,
      black: black ?? this.black,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'primary': primary.value,
      'secondary': secondary.value,
      'tertiary': tertiary.value,
      'quaternary': quaternary?.value,
      'white': white.value,
      'black': black.value,
    };
  }

  factory ColorPalette.fromMap(Map<String, dynamic> map) {
    return ColorPalette(
      primary: Color(map['primary'] as int),
      secondary: Color(map['secondary'] as int),
      tertiary: Color(map['tertiary'] as int),
      quaternary:
          map['quaternary'] != null ? Color(map['quaternary'] as int) : null,
      white: Color(map['white'] as int),
      black: Color(map['black'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory ColorPalette.fromJson(String source) =>
      ColorPalette.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ColorPalette(primary: $primary, secondary: $secondary, tertiary: $tertiary, quaternary: $quaternary, white: $white, black: $black)';
  }

  @override
  bool operator ==(covariant ColorPalette other) {
    if (identical(this, other)) return true;

    return other.primary == primary &&
        other.secondary == secondary &&
        other.tertiary == tertiary &&
        other.quaternary == quaternary &&
        other.white == white &&
        other.black == black;
  }

  @override
  int get hashCode {
    return primary.hashCode ^
        secondary.hashCode ^
        tertiary.hashCode ^
        quaternary.hashCode ^
        white.hashCode ^
        black.hashCode;
  }
}

ColorPalette OGPalette = ColorPalette(
  primary: const Color(0xFF4C934C), //seaGreen
  secondary: const Color(0xFFE8F7EE), //honeyDew
  tertiary: const Color(0xFF54442B), //brown
);

ColorPalette get palette => ColorPalette(
  primary:Color(0xFFD7F0FF),  
  secondary:Color(0xFFFFEFD7),
  tertiary: Color(0xFFFFD7D8),
  black: Color(0xFF1C1C1C),
  white: Color(0xFFFFFFFF),
  extras: [
    Color(0xFFd9d9d9),
    Color(0xFF484848),
    Color(0xFFABABAB),
    Color(0xFFFAFAFA),
    
  ]
);

ColorPalette defaultPalette = againPalette;

ColorPalette anotherOne = ColorPalette(
    primary: Color(0xFF322C2B),
    secondary: Color(0xFFE4C59E),
    tertiary: Color(0xFFAF8260),
    quaternary: Color(0xFF803D3B));

ColorPalette darkPalette = ColorPalette(
    primary: Color(0xFF242424),
    secondary: Color(0xFFBBBBBB),
    tertiary: Color(0xFFAF8260),
    quaternary: Color(0xFF4C6B93));

ColorPalette againPalette = ColorPalette(
    primary: Colors.white,
    secondary: Color(0xFFEAEAEA),
    tertiary: Colors.green,
    quaternary: Color(0xFF1C110A),
    extras: [
      Color(0xff293132),//0
      Color(0xffF9DC5C),//1
      Color(0xffe94f37),//2
      Colors.blue,//3
      Color(0xffD62828),//4
      Color(0xff6279B8),//5
      Color(0xff083d77),//6
      Color(0xff931F1D),//7
      Color(0xffA594F9),//8
      Colors.red,//9
      
      Color(0xffF6AE2D),//10
      
      Color(0xff401F3E),//11
      Color(0xff9D75CB),//12
    ]);


extension ColorExtensions on Color {
  String get hex => '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  String get hexRGB =>
      '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  String get rgb => 'rgb($r, $g, $b)';

  String get rgba => 'rgba($r, $g, $b, ${a.toStringAsFixed(2)})';

  List<double> get hsl {
    final r = this.r / 255.0;
    final g = this.g / 255.0;
    final b = this.b / 255.0;

    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    final delta = max - min;

    double h = 0;
    double s = 0;
    final l = (max + min) / 2;

    if (delta != 0) {
      s = l > 0.5 ? delta / (2 - max - min) : delta / (max + min);

      if (max == r) {
        h = (g - b) / delta + (g < b ? 6 : 0);
      } else if (max == g) {
        h = (b - r) / delta + 2;
      } else {
        h = (r - g) / delta + 4;
      }
      h /= 6;
    }

    return [h * 360, s * 100, l * 100];
  }

  String get hslString {
    final hslValues = hsl;
    return 'hsl(${hslValues[0].round()}, ${hslValues[1].round()}%, ${hslValues[2].round()}%)';
  }

  bool get isDark {
    final luminance = computeLuminance();
    return luminance < 0.5;
  }

  bool get isLight => !isDark;

  Color get contrastColor => isDark ? Colors.white : Colors.black;

  double get luminance => computeLuminance();

  Color withBrightness(double brightness) {
    final hslValues = hsl;
    final newL = (hslValues[2] + brightness).clamp(0, 100).toDouble();
    return _hslToColor(hslValues[0], hslValues[1], newL);
  }

  Color withSaturation(double saturation) {
    final hslValues = hsl;
    final newS = saturation.clamp(0, 100).toDouble();
    return _hslToColor(hslValues[0], newS, hslValues[2]);
  }

  Color withHue(double hue) {
    final hslValues = hsl;
    final newH = hue.clamp(0, 360).toDouble();
    return _hslToColor(newH, hslValues[1], hslValues[2]);
  }

  Color withOpacity(double opacity) {
    return withAlpha((opacity * 255).round());
  }

  Color blend(Color other, double ratio) {
    final r = (this.r * (1 - ratio) + other.r * ratio).round();
    final g = (this.g * (1 - ratio) + other.g * ratio).round();
    final b = (this.b * (1 - ratio) + other.b * ratio).round();
    final a = (this.a * (1 - ratio) + other.a * ratio).round();
    return Color.fromARGB(a, r, g, b);
  }

  Color get complementary {
    final hslValues = hsl;
    final newH = (hslValues[0] + 180) % 360;
    return _hslToColor(newH, hslValues[1], hslValues[2]);
  }

  Color get analogous {
    final hslValues = hsl;
    final newH = (hslValues[0] + 30) % 360;
    return _hslToColor(newH, hslValues[1], hslValues[2]);
  }

  List<Color> get triadic {
    final hslValues = hsl;
    final h1 = (hslValues[0] + 120) % 360;
    final h2 = (hslValues[0] + 240) % 360;
    return [
      this,
      _hslToColor(h1, hslValues[1], hslValues[2]),
      _hslToColor(h2, hslValues[1], hslValues[2]),
    ];
  }

  List<Color> get monochromatic {
    final hslValues = hsl;
    return [
      this,
      _hslToColor(hslValues[0], hslValues[1] * 0.8, hslValues[2] * 0.8),
      _hslToColor(hslValues[0], hslValues[1] * 0.6, hslValues[2] * 0.6),
      _hslToColor(hslValues[0], hslValues[1] * 0.4, hslValues[2] * 0.4),
    ];
  }

  static Color fromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  static Color fromRGB(int r, int g, int b, [double a = 1.0]) {
    return Color.fromARGB((a * 255).round(), r, g, b);
  }

  static Color fromHSL(double h, double s, double l, [double a = 1.0]) {
    return _hslToColor(h, s, l).withValues(alpha: a);
  }

  static Color _hslToColor(double h, double s, double l) {
    h = h / 360;
    s = s / 100;
    l = l / 100;

    double r, g, b;

    if (s == 0) {
      r = g = b = l;
    } else {
      hue2rgb(p, q, t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      }

      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }

    return Color.fromARGB(
        255, (r * 255).round(), (g * 255).round(), (b * 255).round());
  }
}