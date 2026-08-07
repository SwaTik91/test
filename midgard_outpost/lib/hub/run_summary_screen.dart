import 'package:flutter/material.dart';

import '../run/run_rewards.dart';

class RunPlaceholderScreen extends StatelessWidget {
  const RunPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Забег'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Забег скоро', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}

class RunSummaryScreen extends StatelessWidget {
  const RunSummaryScreen({super.key, required this.rewards, this.onContinue});

  final RunRewards rewards;
  final Future<void> Function()? onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Итоги забега')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Базовый опыт: ${rewards.baseXp}'),
            Text('Проф. опыт: ${rewards.jobXp}'),
            Text('Золото: ${rewards.gold}'),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                await onContinue?.call();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('Продолжить'),
            ),
          ],
        ),
      ),
    );
  }
}
