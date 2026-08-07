import 'package:flutter/material.dart';

import '../iap/iap_product.dart';
import 'game_controller.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<IapProduct>? _products;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await widget.controller.iap.listProducts();
    if (mounted) {
      setState(() => _products = products);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _products == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _products!.map((product) {
                return Card(
                  child: ListTile(
                    title: Text(product.title),
                    subtitle: product.crystals > 0
                        ? Text('${product.crystals} кристаллов')
                        : const Text('Скоро'),
                    trailing: Text(product.priceLabel),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
