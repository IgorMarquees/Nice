import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../nucleo/configuracao.dart';

class RepositorioFotos {
  RepositorioFotos(this._conexao);

  final SupabaseClient _conexao;

  /// Envia a foto em bytes para funcionar também na web e devolve o link público.
  Future<String> enviarFotoProduto(XFile arquivo) async {
    final bytes = await arquivo.readAsBytes();
    final extensao = arquivo.name.contains('.') ? arquivo.name.split('.').last.toLowerCase() : 'jpg';
    final caminho = 'products/${DateTime.now().microsecondsSinceEpoch}.$extensao';
    final bucket = _conexao.storage.from(Configuracao.bucketProdutos);
    await bucket.uploadBinary(
      caminho,
      bytes,
      fileOptions: FileOptions(contentType: arquivo.mimeType ?? 'image/$extensao'),
    );
    return bucket.getPublicUrl(caminho);
  }
}
