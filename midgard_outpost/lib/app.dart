import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MidgardApp extends StatelessWidget {
  const MidgardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мидгард: Аванпост',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Мидгард: Аванпост')),
      ),
    );
  }
}
