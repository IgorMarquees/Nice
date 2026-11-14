import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class StorageRepository {
  StorageRepository(this._client);

  final SupabaseClient _client;

  /// Envia a imagem (por bytes, compatível com Web) e devolve a URL pública.
  Future<String> uploadProductImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
    final path = 'products/${DateTime.now().microsecondsSinceEpoch}.$ext';
    final bucket = _client.storage.from(AppConfig.productsBucket);
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: file.mimeType ?? 'image/$ext'),
    );
    return bucket.getPublicUrl(path);
  }
}
