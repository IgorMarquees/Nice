/// Tipo de conta.
/// O código é o valor gravado no banco.
enum PapelUsuario {
  cliente('customer'),
  admin('admin');

  const PapelUsuario(this.codigo);

  final String codigo;
}

class Usuario {
  const Usuario({
    required this.id,
    required this.email,
    required this.nome,
    this.papel = PapelUsuario.cliente,
    this.criadoEm,
  });

  final String id;
  final String email;
  final String nome;
  final PapelUsuario papel;
  final DateTime? criadoEm;

  bool get ehAdmin => papel == PapelUsuario.admin;

  Usuario copiarCom({PapelUsuario? papel}) =>
      Usuario(id: id, email: email, nome: nome, papel: papel ?? this.papel, criadoEm: criadoEm);

  factory Usuario.doPerfil(Map<String, dynamic> registro) => Usuario(
        id: registro['id'].toString(),
        email: (registro['email'] as String?) ?? '',
        nome: (registro['name'] as String?)?.trim().isNotEmpty == true ? registro['name'] as String : 'Cliente NICE',
        papel: registro['role'] == 'admin' ? PapelUsuario.admin : PapelUsuario.cliente,
        criadoEm: DateTime.tryParse(registro['created_at']?.toString() ?? '')?.toLocal(),
      );
}
