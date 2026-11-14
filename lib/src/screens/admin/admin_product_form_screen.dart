import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../models/product.dart';
import '../../theme/nice_theme.dart';
import '../../utils/navigation.dart';
import '../../widgets/nice_network_image.dart';
import '../../widgets/responsive.dart';
import '../../widgets/state_views.dart';

class _PickedImage {
  _PickedImage(this.file, this.bytes);
  final XFile file;
  final Uint8List bytes;
}

/// Cadastro/edição de produto (upload de fotos no Supabase Storage).
class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key, this.productId});

  /// null = novo produto.
  final String? productId;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  static final _categories = CatalogController.categories.skip(1).toList();

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _colors = TextEditingController();

  String _category = _categories.first;
  final Set<String> _sizes = {};
  bool _featured = false;
  bool _isNew = false;
  List<String> _images = [];
  final List<_PickedImage> _picked = [];

  Product? _existing;
  bool _loading = false;

  bool get _editing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _loading = true;
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final product = await context.read<AdminController>().findById(widget.productId!);
    if (!mounted) return;
    setState(() {
      _existing = product;
      if (product != null) {
        _title.text = product.title;
        _description.text = product.description;
        _price.text = product.price.toStringAsFixed(2).replaceAll('.', ',');
        _stock.text = product.stock.toString();
        _colors.text = product.colors.join(', ');
        _category = _categories.contains(product.category) ? product.category : _categories.first;
        _sizes
          ..clear()
          ..addAll(product.sizes);
        _featured = product.isFeatured;
        _isNew = product.isNew;
        _images = [...product.images];
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _price, _stock, _colors]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1800);
    final picked = <_PickedImage>[];
    for (final file in files) {
      picked.add(_PickedImage(file, await file.readAsBytes()));
    }
    if (!mounted) return;
    setState(() => _picked.addAll(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = context.read<AdminController>();
    final catalog = context.read<CatalogController>();
    final messenger = ScaffoldMessenger.of(context);

    if (_images.isEmpty && _picked.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Adicione pelo menos uma foto.')));
      return;
    }

    final product = Product(
      id: _existing?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      price: double.parse(_price.text.trim().replaceAll(',', '.')),
      category: _category,
      images: _images,
      colors: _colors.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      sizes: CatalogController.sizes.where(_sizes.contains).toList(),
      stock: int.parse(_stock.text.trim()),
      isFeatured: _featured,
      isNew: _isNew,
    );

    final ok = await admin.save(product, newImages: [for (final p in _picked) p.file]);
    if (!mounted) return;
    if (ok) {
      catalog.load(force: true);
      messenger.showSnackBar(const SnackBar(content: Text('Produto salvo.')));
      context.go('/admin');
    } else {
      messenger.showSnackBar(SnackBar(content: Text(admin.error ?? 'Erro ao salvar.')));
    }
  }

  Widget _pair(Widget a, Widget b) {
    if (context.isCompact) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 12), b]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_editing && _existing == null) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Produto não encontrado',
        actionLabel: 'Voltar',
        onAction: () => context.go('/admin'),
      );
    }

    final admin = context.watch<AdminController>();
    final text = Theme.of(context).textTheme;
    String? required(String? v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null;

    return ContentWrapper(
      maxWidth: 900,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PAINEL ADMIN', style: text.labelMedium),
              const SizedBox(height: 4),
              Text(_editing ? 'EDITAR PRODUTO' : 'NOVO PRODUTO', style: text.headlineLarge),
              const SizedBox(height: 24),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Nome do produto'),
                validator: required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: required,
              ),
              const SizedBox(height: 12),
              _pair(
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Preço (R\$)'),
                  validator: (v) {
                    final value = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    return value == null || value < 0 ? 'Preço inválido' : null;
                  },
                ),
                TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade em estoque'),
                  validator: (v) => int.tryParse((v ?? '').trim()) == null ? 'Número inválido' : null,
                ),
              ),
              const SizedBox(height: 12),
              _pair(
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                TextFormField(
                  controller: _colors,
                  decoration: const InputDecoration(labelText: 'Cores (separadas por vírgula)'),
                ),
              ),
              const SizedBox(height: 24),
              Text('TAMANHOS DISPONÍVEIS', style: text.labelMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final size in CatalogController.sizes)
                    FilterChip(
                      label: Text(size),
                      selected: _sizes.contains(size),
                      selectedColor: NiceTheme.red,
                      labelStyle: NiceTheme.chipLabel(selected: _sizes.contains(size)),
                      onSelected: (selected) => setState(() {
                        selected ? _sizes.add(size) : _sizes.remove(size);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exibir em Destaque na Home'),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exibir em Novidades'),
                value: _isNew,
                onChanged: (v) => setState(() => _isNew = v),
              ),
              const SizedBox(height: 16),
              Text('FOTOS', style: text.labelMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < _images.length; i++)
                    _Thumb(
                      child: NiceNetworkImage(url: _images[i], fit: BoxFit.cover),
                      onRemove: () => setState(() => _images.removeAt(i)),
                    ),
                  for (var i = 0; i < _picked.length; i++)
                    _Thumb(
                      child: Image.memory(_picked[i].bytes, fit: BoxFit.cover),
                      onRemove: () => setState(() => _picked.removeAt(i)),
                    ),
                  InkWell(
                    onTap: _pickImages,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: NiceTheme.lightGray,
                        borderRadius: BorderRadius.circular(NiceTheme.radius),
                        border: Border.all(color: NiceTheme.softGray, width: 1.5),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined, color: NiceTheme.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: admin.saving ? null : () => context.goBackOr('/admin'),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: admin.saving ? null : _save,
                      child: admin.saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: NiceTheme.white),
                            )
                          : const Text('SALVAR PRODUTO'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(borderRadius: BorderRadius.circular(NiceTheme.radius), child: child),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: Material(
              color: NiceTheme.charcoal,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: NiceTheme.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
