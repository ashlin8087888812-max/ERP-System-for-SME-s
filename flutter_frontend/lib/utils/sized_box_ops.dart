import 'package:flutter/material.dart';

extension bodmas on SizedBox {
  SizedBox _apply(num other, num Function(num a, num b) op) {
    double? newH = height != null ? op(height!, other.toDouble()) as double? : null;
    double? newW = width  != null ? op(width!,  other.toDouble()) as double? : null;

    return SizedBox(height: newH, width: newW);
  }

  SizedBox operator +(num other) => _apply(other, (a, b) => a + b);
  SizedBox operator -(num other) => _apply(other, (a, b) => a - b);
  SizedBox operator *(num other) => _apply(other, (a, b) => a * b);
  SizedBox operator /(num other) => _apply(other, (a, b) => a / b);
}
