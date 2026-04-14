import 'package:flutter/material.dart';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';
import 'package:miaomiao_fill_light/features/lighting/domain/models/filter_type.dart';

/// 滤镜托盘 Widget
class FilterTray extends StatelessWidget {
  final FilterType currentFilter;
  final ValueChanged<FilterType> onFilterSelected;
  final VoidCallback onClose;

  const FilterTray({
    super.key,
    required this.currentFilter,
    required this.onFilterSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // 拖拽手柄
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 滤镜列表
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: FilterType.values.length,
              itemBuilder: (context, index) {
                final filter = FilterType.values[index];
                final isSelected = filter == currentFilter;
                return _FilterItem(
                  filter: filter,
                  isSelected: isSelected,
                  onTap: () => onFilterSelected(filter),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final FilterType filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterItem({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 滤镜缩略图
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.vibrantPink
                      : Colors.white.withOpacity(0.2),
                  width: isSelected ? 2.5 : 1,
                ),
                gradient: _getFilterGradient(filter),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.vibrantPink.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.filter_vintage,
                  color: Colors.white.withOpacity(0.8),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 滤镜名称
            Text(
              filter.displayName,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.vibrantPink
                    : Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据滤镜类型返回预览渐变
  LinearGradient _getFilterGradient(FilterType filter) {
    switch (filter) {
      case FilterType.none:
        return const LinearGradient(
          colors: [Color(0xFFFF1493), Color(0xFFFFD1DC)],
        );
      case FilterType.grayscale:
        return const LinearGradient(
          colors: [Color(0xFF333333), Color(0xFFCCCCCC)],
        );
      case FilterType.sepia:
        return const LinearGradient(
          colors: [Color(0xFF704214), Color(0xFFD4A574)],
        );
      case FilterType.cool:
        return const LinearGradient(
          colors: [Color(0xFF0066CC), Color(0xFF99CCFF)],
        );
      case FilterType.warm:
        return const LinearGradient(
          colors: [Color(0xFFFF6600), Color(0xFFFFCC99)],
        );
      case FilterType.vintage:
        return const LinearGradient(
          colors: [Color(0xFF8B4513), Color(0xFFDEB887)],
        );
      case FilterType.vivid:
        return const LinearGradient(
          colors: [Color(0xFFFF0066), Color(0xFF00FFCC)],
        );
    }
  }
}
