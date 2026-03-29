import 'package:flutter/material.dart';

class ColorMapper {
  static Color fromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.parse(normalized, radix: 16));
  }
}