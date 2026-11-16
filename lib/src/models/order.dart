import '../config/app_config.dart';
import 'cart_item.dart';

/// Siglas das 27 unidades federativas (UF obrigatória da lista).
const brazilianStates = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA',
  'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

class ShippingAddress {
  const ShippingAddress({
    required this.recipient,
    required this.zip,
    required this.street,
    required this.number,
    this.complement = '',
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final String recipient;
  final String zip;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;

  bool get isEmpty => street.isEmpty && city.isEmpty && zip.isEmpty;

  String get oneLine {
    final comp = complement.isEmpty ? '' : ' - $complement';
    return '$street, $number$comp - $neighborhood, $city/$state - CEP $zip';
  }

  Map<String, dynamic> toMap() => {
        'recipient': recipient,
        'zip': zip,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
      };

  factory ShippingAddress.fromMap(Map<String, dynamic> map) => ShippingAddress(
        recipient: (map['recipient'] as String?) ?? '',
        zip: (map['zip'] as String?) ?? '',
        street: (map['street'] as String?) ?? '',
        number: (map['number'] as String?) ?? '',
        complement: (map['complement'] as String?) ?? '',
        neighborhood: (map['neighborhood'] as String?) ?? '',
        city: (map['city'] as String?) ?? '',
        state: (map['state'] as String?) ?? '',
      );
}

/// Endereço salvo no perfil (tabela `addresses`).
class SavedAddress {
  const SavedAddress({required this.id, required this.label, required this.address});

  /// Vazio = ainda não gravado.
  final String id;
  final String label;
  final ShippingAddress address;

  String get title => label.isEmpty ? 'Endereço' : label;

  Map<String, dynamic> toRow(String userId) => {
        if (id.isNotEmpty) 'id': id,
        'user_id': userId,
        'label': label,
        ...address.toMap(),
      };

  factory SavedAddress.fromMap(Map<String, dynamic> map) => SavedAddress(
        id: map['id'].toString(),
        label: (map['label'] as String?) ?? '',
        address: ShippingAddress.fromMap(map),
      );
}

enum PaymentMethod {
  pix('pix', 'Pix'),
  card('card', 'Cartão de crédito'),
  boleto('boleto', 'Boleto');

  const PaymentMethod(this.code, this.label);
  final String code;
  final String label;

  static PaymentMethod fromCode(String? code) =>
      values.firstWhere((m) => m.code == code, orElse: () => PaymentMethod.pix);
}

/// Valores do pedido: produtos, desconto do Pix, frete e total.
class OrderTotals {
  const OrderTotals({required this.subtotal, required this.discount, required this.shipping});

  factory OrderTotals.calculate(double subtotal, PaymentMethod method) {
    final discount = method == PaymentMethod.pix ? _round(subtotal * AppConfig.pixDiscount) : 0.0;
    final shipping = subtotal >= AppConfig.freeShippingThreshold || subtotal == 0 ? 0.0 : AppConfig.flatShipping;
    return OrderTotals(subtotal: subtotal, discount: discount, shipping: shipping);
  }

  final double subtotal;
  final double discount;
  final double shipping;

  double get total => _round(subtotal - discount + shipping);
  bool get freeShipping => shipping == 0;

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.total,
    required this.paymentMethod,
    required this.items,
    required this.address,
    this.userId = '',
    this.subtotal,
    this.discount = 0,
    this.shipping = 0,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String status;
  final double total;
  final double? subtotal;
  final double discount;
  final double shipping;
  final PaymentMethod paymentMethod;
  final List<CartItem> items;
  final ShippingAddress address;
  final DateTime? createdAt;

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Pago';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregue';
      case 'canceled':
        return 'Cancelado';
      default:
        return 'Pedido recebido';
    }
  }

  String get shortId => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  factory Order.fromMap(Map<String, dynamic> map) {
    final rawItems = (map['items'] as List?) ?? const [];
    return Order(
      id: map['id'].toString(),
      userId: map['user_id']?.toString() ?? '',
      status: (map['status'] as String?) ?? 'created',
      total: (map['total'] as num).toDouble(),
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      shipping: (map['shipping'] as num?)?.toDouble() ?? 0,
      paymentMethod: PaymentMethod.fromCode(map['payment_method'] as String?),
      items: [
        for (final item in rawItems) CartItem.fromMap(Map<String, dynamic>.from(item as Map)),
      ],
      address: ShippingAddress.fromMap(
        Map<String, dynamic>.from((map['address'] as Map?) ?? const {}),
      ),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal(),
    );
  }
}
