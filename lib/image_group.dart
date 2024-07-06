import 'package:flutter/material.dart';

class ImageGroup {
  final String mainImage1x;
  final String? mainImage2x;
  final String? mainImage3x;

  final Size? newSize3x;
  final Size originalSize3x;

  const ImageGroup({
    required this.mainImage1x,
    required this.originalSize3x,
    this.mainImage2x,
    this.mainImage3x,
    this.newSize3x,
  });

  ImageGroup copyWith({
    String? mainImage1x,
    String? mainImage2x,
    String? mainImage3x,
    Size? newSize3x,
    Size? originalSize3x,
  }) {
    return ImageGroup(
      mainImage1x: mainImage1x ?? this.mainImage1x,
      mainImage2x: mainImage2x ?? this.mainImage2x,
      mainImage3x: mainImage3x ?? this.mainImage3x,
      newSize3x: newSize3x ?? this.newSize3x,
      originalSize3x: originalSize3x ?? this.originalSize3x,
    );
  }
}
