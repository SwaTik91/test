import 'package:flutter/material.dart';

import '../iap/iap_product.dart';
import 'game_controller.dart';
import 'hub_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  final GameController controller;
  final bool embedded;

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
    final theme = Theme.of(context).textTheme;

    final body = _products == null
        ? const Center(
            child: CircularProgressIndicator(color: HubTheme.accent),
          )
        : HubTabBody(
            child: ListView(
              children: [
                HubCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.diamond_outlined,
                        size: 18,
                        color: HubTheme.crystal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Кристаллы: $crystals',
                        style: HubTheme.cardTitleStyle(theme),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final product in _products!) ...[
                  _ProductCard(
                    product: product,
                    isPurchasing: _purchasingId == product.id,
                    onPurchase: () => _purchase(product),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: body,
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isPurchasing,
    required this.onPurchase,
    required this.theme,
  });

  final IapProduct product;
  final bool isPurchasing;
  final VoidCallback onPurchase;
  final TextTheme theme;

  @override
  Widget build(BuildContext context) {
    return HubCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, style: HubTheme.cardTitleStyle(theme)),
                const SizedBox(height: 2),
                Text(
                  product.description,
                  style: HubTheme.cardSubtitleStyle(theme),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.priceLabel,
                  style: HubTheme.cardSubtitleStyle(theme),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPurchasing)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: HubTheme.accent,
              ),
            )
          else
            FilledButton(
              style: HubTheme.accentButtonStyle(),
              onPressed: onPurchase,
              child: const Text('Купить'),
            ),
        ],
      ),
    );
  }
}
