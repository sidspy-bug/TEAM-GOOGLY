      final uniqueProducts = <String, Sale>{};
      for (final s in sales) {
        uniqueProducts[s.productId] = s;
      }
      final lowProducts = uniqueProducts.values.where((s) => s.currentStock < 10).toList()
        ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
