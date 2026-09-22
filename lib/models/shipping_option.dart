// lib/models/shipping_option.dart

class ShippingOption {
  final int methodId;
  final String name;
  final String? description;
  final double fee;
  final double? freeOver;
  final double? feeForCart;
  final int etaDaysMin;
  final int etaDaysMax;
  final String etaLabel;

  const ShippingOption({
    required this.methodId,
    required this.name,
    this.description,
    required this.fee,
    this.freeOver,
    this.feeForCart,
    required this.etaDaysMin,
    required this.etaDaysMax,
    this.etaLabel = '',
  });
  double get effectiveFee => feeForCart ?? fee;

  factory ShippingOption.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    double? dOpt(String k) => (json[k] as num?)?.toDouble();
    return ShippingOption(
      methodId: (json['method_id'] as int?) ?? (json['id'] as int?) ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      fee: d('fee'),
      freeOver: dOpt('free_over'),
      feeForCart: dOpt('fee_for_cart'),
      etaDaysMin: json['eta_days_min'] as int? ?? 1,
      etaDaysMax: json['eta_days_max'] as int? ?? 3,
      etaLabel: json['eta_label'] as String? ?? '',
    );
  }
}
