import '../nucleo/configuracao.dart';
import 'item_carrinho.dart';

/// Siglas dos 27 estados brasileiros usadas na escolha da UF.
const estadosBrasileiros = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA',
  'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

class EnderecoEntrega {
  const EnderecoEntrega({
    required this.destinatario,
    required this.cep,
    required this.rua,
    required this.numero,
    this.complemento = '',
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  final String destinatario;
  final String cep;
  final String rua;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado;

  bool get vazio => rua.isEmpty && cidade.isEmpty && cep.isEmpty;

  String get emUmaLinha {
    final textoComplemento = complemento.isEmpty ? '' : ' - $complemento';
    return '$rua, $numero$textoComplemento - $bairro, $cidade/$estado - CEP $cep';
  }

  Map<String, dynamic> paraMapa() => {
        'recipient': destinatario,
        'zip': cep,
        'street': rua,
        'number': numero,
        'complement': complemento,
        'neighborhood': bairro,
        'city': cidade,
        'state': estado,
      };

  factory EnderecoEntrega.doMapa(Map<String, dynamic> mapa) => EnderecoEntrega(
        destinatario: (mapa['recipient'] as String?) ?? '',
        cep: (mapa['zip'] as String?) ?? '',
        rua: (mapa['street'] as String?) ?? '',
        numero: (mapa['number'] as String?) ?? '',
        complemento: (mapa['complement'] as String?) ?? '',
        bairro: (mapa['neighborhood'] as String?) ?? '',
        cidade: (mapa['city'] as String?) ?? '',
        estado: (mapa['state'] as String?) ?? '',
      );
}

class EnderecoSalvo {
  /// O id fica vazio enquanto o endereço ainda não foi gravado.
  const EnderecoSalvo({required this.id, required this.rotulo, required this.endereco});

  final String id;
  final String rotulo;
  final EnderecoEntrega endereco;

  String get titulo => rotulo.isEmpty ? 'Endereço' : rotulo;

  Map<String, dynamic> paraLinha(String idUsuario) => {
        if (id.isNotEmpty) 'id': id,
        'user_id': idUsuario,
        'label': rotulo,
        ...endereco.paraMapa(),
      };

  factory EnderecoSalvo.doMapa(Map<String, dynamic> mapa) => EnderecoSalvo(
        id: mapa['id'].toString(),
        rotulo: (mapa['label'] as String?) ?? '',
        endereco: EnderecoEntrega.doMapa(mapa),
      );
}

/// Formas de pagamento aceitas.
/// O código é o valor gravado no banco.
enum FormaPagamento {
  pix('pix', 'Pix'),
  cartao('card', 'Cartão de crédito'),
  boleto('boleto', 'Boleto');

  const FormaPagamento(this.codigo, this.rotulo);
  final String codigo;
  final String rotulo;

  static FormaPagamento doCodigo(String? codigo) =>
      values.firstWhere((m) => m.codigo == codigo, orElse: () => FormaPagamento.pix);
}

class TotaisPedido {
  const TotaisPedido({required this.subtotal, required this.desconto, required this.frete});

  /// Calcula o desconto do Pix e o frete a partir do valor dos produtos.
  factory TotaisPedido.calcular(double subtotal, FormaPagamento forma) {
    final desconto = forma == FormaPagamento.pix ? _arredondar(subtotal * Configuracao.descontoPix) : 0.0;
    final frete = subtotal >= Configuracao.freteGratisAPartirDe || subtotal == 0 ? 0.0 : Configuracao.freteFixo;
    return TotaisPedido(subtotal: subtotal, desconto: desconto, frete: frete);
  }

  final double subtotal;
  final double desconto;
  final double frete;

  double get total => _arredondar(subtotal - desconto + frete);
  bool get freteGratis => frete == 0;

  static double _arredondar(double valor) => (valor * 100).roundToDouble() / 100;
}

class Pedido {
  const Pedido({
    required this.id,
    required this.situacao,
    required this.total,
    required this.formaPagamento,
    required this.itens,
    required this.endereco,
    this.idUsuario = '',
    this.subtotal,
    this.desconto = 0,
    this.frete = 0,
    this.criadoEm,
  });

  final String id;
  final String idUsuario;
  final String situacao;
  final double total;
  final double? subtotal;
  final double desconto;
  final double frete;
  final FormaPagamento formaPagamento;
  final List<ItemCarrinho> itens;
  final EnderecoEntrega endereco;
  final DateTime? criadoEm;

  String get rotuloSituacao {
    switch (situacao) {
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

  String get idCurto => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  factory Pedido.doMapa(Map<String, dynamic> mapa) {
    final itensBrutos = (mapa['items'] as List?) ?? const [];
    return Pedido(
      id: mapa['id'].toString(),
      idUsuario: mapa['user_id']?.toString() ?? '',
      situacao: (mapa['status'] as String?) ?? 'created',
      total: (mapa['total'] as num).toDouble(),
      subtotal: (mapa['subtotal'] as num?)?.toDouble(),
      desconto: (mapa['discount'] as num?)?.toDouble() ?? 0,
      frete: (mapa['shipping'] as num?)?.toDouble() ?? 0,
      formaPagamento: FormaPagamento.doCodigo(mapa['payment_method'] as String?),
      itens: [
        for (final item in itensBrutos) ItemCarrinho.doMapa(Map<String, dynamic>.from(item as Map)),
      ],
      endereco: EnderecoEntrega.doMapa(
        Map<String, dynamic>.from((mapa['address'] as Map?) ?? const {}),
      ),
      criadoEm: DateTime.tryParse(mapa['created_at']?.toString() ?? '')?.toLocal(),
    );
  }
}
