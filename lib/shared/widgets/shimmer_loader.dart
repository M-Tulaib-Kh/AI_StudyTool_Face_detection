import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 90});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.darkCard,
      highlightColor: AppColors.darkSecondary,
      child: Container(
        height: height, margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(boxShadow: AppShadows.clay, color: AppColors.darkCard, borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 4});
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(count, (i) => ShimmerCard(height: 80 + (i % 2 * 20).toDouble())),
  );
}

// Alias for backward compat — used in student_home_screen
class ShimmerLoader extends StatelessWidget {
  final double height;
  final double borderRadius;
  const ShimmerLoader({super.key, this.height = 90, this.borderRadius = 16});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.darkCard,
      highlightColor: AppColors.darkSecondary,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(boxShadow: AppShadows.clay, 
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
