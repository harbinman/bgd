import 'package:flutter/material.dart';

/// 滤镜类型枚举
enum FilterType {
  none,      // 原图
  grayscale, // 黑白
  sepia,     // 复古
  cool,      // 冷色调
  warm,      // 暖色调
  vintage,   // 怀旧
  vivid,     // 鲜艳
}

/// 滤镜扩展方法
extension FilterTypeExtension on FilterType {
  /// 滤镜显示名称
  String get displayName {
    switch (this) {
      case FilterType.none:
        return '原图';
      case FilterType.grayscale:
        return '黑白';
      case FilterType.sepia:
        return '复古';
      case FilterType.cool:
        return '冷色调';
      case FilterType.warm:
        return '暖色调';
      case FilterType.vintage:
        return '怀旧';
      case FilterType.vivid:
        return '鲜艳';
    }
  }

  /// 获取滤镜的 ColorFilter
  ColorFilter? get colorFilter {
    switch (this) {
      case FilterType.none:
        return null;
      case FilterType.grayscale:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      case FilterType.sepia:
        return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
        ]);
      case FilterType.cool:
        return const ColorFilter.matrix([
          0.9, 0,   0,   0, 0,
          0,   0.9, 0,   0, 0,
          0,   0,   1.1, 0, 0,
          0,   0,   0,   1, 0,
        ]);
      case FilterType.warm:
        return const ColorFilter.matrix([
          1.1, 0,   0,   0, 0,
          0,   1.0, 0,   0, 0,
          0,   0,   0.8, 0, 0,
          0,   0,   0,   1, 0,
        ]);
      case FilterType.vintage:
        return const ColorFilter.matrix([
          0.6, 0.3, 0.1, 0, 0,
          0.2, 0.7, 0.1, 0, 0,
          0.2, 0.3, 0.5, 0, 0,
          0,   0,   0,   1, 0,
        ]);
      case FilterType.vivid:
        return const ColorFilter.matrix([
          1.3, 0,   0,   0, 0,
          0,   1.3, 0,   0, 0,
          0,   0,   1.3, 0, 0,
          0,   0,   0,   1, 0,
        ]);
    }
  }
}
