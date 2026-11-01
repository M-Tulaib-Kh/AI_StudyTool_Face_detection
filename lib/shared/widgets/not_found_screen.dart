import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class NotFoundScreen extends StatelessWidget {
  final String error;
  const NotFoundScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 64),
          const SizedBox(height: 16),
          const Text('Page Not Found', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error, style: const TextStyle(color: AppColors.darkMuted, fontSize: 13), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.go('/student'), child: const Text('Go Home')),
        ]),
      ),
    );
  }
}
