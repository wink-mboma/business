import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class NotImplementedScreen extends StatelessWidget {
  const NotImplementedScreen({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome_outlined, size: 42, color: AppColors.grey500),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey600)),
        ]),
      ),
    );
  }
}
