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
  String? _purchasingId;

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

  Future<void> _purchase(IapProduct product) async {
    setState(() => _purchasingId = product.id);
    final ok = await widget.controller.purchaseProduct(product.id);
    if (!mounted) {
      return;
    }
    setState(() => _purchasingId = null);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Покупка не удалась')),
      );
      return;
    }
    final message = product.kind == IapProductKind.crystals
        ? 'Получено: ${product.crystals} кристаллов'
        : 'Буст активирован на 24 часа';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crystals = widget.controller.hero?.crystals ?? 0;
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
              children: [
                Text(
                  'Кристаллы: $crystals',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ..._products!.map((product) {
                  final isPurchasing = _purchasingId == product.id;
                  return Card(
                    child: ListTile(
                      title: Text(product.title),
                      subtitle: Text(product.description),
                      trailing: isPurchasing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(product.priceLabel),
                      onTap: isPurchasing ? null : () => _purchase(product),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
