class WalletModel {
  final int id;
  final double balance;
  final int userId;
  final String userName;

  const WalletModel({
    required this.id,
    required this.balance,
    required this.userId,
    required this.userName,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
    return WalletModel(
      id: _toInt(data['id']),
      balance: _toDouble(data['balance']),
      userId: _toInt(user['id']),
      userName: (user['name'] ?? '').toString(),
    );
  }
}

class WalletTransactionModel {
  final int id;
  final String type; // النص الخام من الباك زي ما هو (deposit/payment/refund...)
  final String direction;
  final double amount;
  final String? description;
  final DateTime? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    this.direction = '',
    required this.amount,
    this.description,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: _toInt(json['id']),
      type: (json['type'] ?? json['transaction_type'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString().trim().toLowerCase(),
      amount: _toDouble(json['amount']),
      description: (json['description'] ?? json['note'])?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['date']),
    );
  }

  bool get isCredit {
    if (direction == 'credit') return true;
    if (direction == 'debit') return false;

    // Compatibility fallback for older API responses that did not include
    // direction. New responses must use the authoritative server value above.
    final t = type.toLowerCase();
    const creditHints = [
      'credit',
      'deposit',
      'refund',
      'top_up',
      'topup',
      'charge',
    ];
    const debitHints = ['debit', 'payment', 'booking', 'appointment'];

    if (creditHints.any(t.contains)) return true;
    if (debitHints.any(t.contains)) return false;
    return amount >= 0;
  }

  /// وصف مبسّط للعرض لو الباك ما رجعش description واضح.
  String get displayLabel {
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }
    final t = type.toLowerCase();
    if (t.contains('refund')) return 'استرجاع رصيد';
    if (t.contains('deposit') || t.contains('top')) return 'شحن رصيد';
    if (t.contains('appointment') || t.contains('booking')) {
      return 'دفع مقابل موعد';
    }
    return isCredit ? 'إضافة رصيد' : 'خصم من الرصيد';
  }
}

class WalletTransactionsPage {
  final List<WalletTransactionModel> transactions;

  const WalletTransactionsPage({required this.transactions});

  factory WalletTransactionsPage.fromJson(dynamic json) {
    dynamic raw = json;
    if (raw is Map && raw.containsKey('data')) raw = raw['data'];
    if (raw is Map && raw.containsKey('data')) raw = raw['data'];

    final List rawList = raw is List ? raw : [];

    return WalletTransactionsPage(
      transactions: rawList
          .whereType<Map>()
          .map(
            (e) => WalletTransactionModel.fromJson(e.cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
