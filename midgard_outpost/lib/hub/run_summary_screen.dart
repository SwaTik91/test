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

class RunSummaryScreen extends StatefulWidget {
  const RunSummaryScreen({super.key, required this.rewards, this.onContinue});

  final RunRewards rewards;
  final Future<void> Function()? onContinue;

  @override
  State<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends State<RunSummaryScreen> {
  bool _isLeaving = false;

  Future<void> _finishAndLeave() async {
    if (_isLeaving) {
      return;
    }
    _isLeaving = true;

    await widget.onContinue?.call();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _finishAndLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Итоги забега'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _finishAndLeave,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Базовый опыт: ${widget.rewards.baseXp}'),
              Text('Проф. опыт: ${widget.rewards.jobXp}'),
              Text('Золото: ${widget.rewards.gold}'),
              const Spacer(),
              FilledButton(
                onPressed: _finishAndLeave,
                child: const Text('Продолжить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
