import 'package:flutter/material.dart';

import 'hub/create_hero_screen.dart';
import 'hub/game_controller.dart';
import 'hub/hub_screen.dart';
import 'save/cloud_save_port.dart';
import 'save/local_save_repository.dart';
import 'save/save_service.dart';

class MidgardApp extends StatelessWidget {
  const MidgardApp({super.key, this.controller});

  final GameController? controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мидгард: Аванпост',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        useMaterial3: true,
      ),
      home: controller != null
          ? _GameRoot(controller: controller!)
          : const _BootstrapRoot(),
    );
  }
}

class _BootstrapRoot extends StatefulWidget {
  const _BootstrapRoot();

  @override
  State<_BootstrapRoot> createState() => _BootstrapRootState();
}

class _BootstrapRootState extends State<_BootstrapRoot> {
  GameController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = GameController(
      save: SaveService(
        local: LocalSaveRepository(),
        cloud: NoopCloudSavePort(),
      ),
    );
    await controller.bootstrap();
    if (mounted) {
      setState(() => _controller = controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _GameRoot(controller: _controller!);
  }
}

class _GameRoot extends StatelessWidget {
  const _GameRoot({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isBootstrapped) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.hero == null) {
          return CreateHeroScreen(controller: controller);
        }
        return HubScreen(controller: controller);
      },
    );
  }
}
