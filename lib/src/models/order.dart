import 'cart_item.dart';

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

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.total,
    required this.paymentMethod,
    required this.items,
    required this.address,
    this.createdAt,
  });

  final String id;
  final String status;
  final double total;
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
      status: (map['status'] as String?) ?? 'created',
      total: (map['total'] as num).toDouble(),
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
