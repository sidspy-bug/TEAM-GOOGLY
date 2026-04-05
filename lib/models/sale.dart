class Sale {
  final String productId;
  final String productName;
  final String category;
  final int quantity;
  final double price; // selling price per unit
  final double costPrice; // cost price per unit
  final int currentStock;
  final DateTime date;
  final String transactionMode; // UPI / Cash / Card

  Sale({
    this.productId = '',
    required this.productName,
    required this.category,
    required this.quantity,
    required this.price,
    this.costPrice = 0,
    this.currentStock = 0,
    required this.date,
    this.transactionMode = 'Cash',
  });

  double get dailyRevenue => price * quantity;
  double get estimatedProfit => (price - costPrice) * quantity;
}
