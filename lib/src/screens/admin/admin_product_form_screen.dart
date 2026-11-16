import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../models/product.dart';
import '../../theme/nice_theme.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../utils/navigation.dart';
import '../../widgets/discount_editor.dart';
import '../../widgets/nice_network_image.dart';
import '../../widgets/responsive.dart';
import '../../widgets/state_views.dart';

class _PickedImage {
  _PickedImage(this.file, this.bytes);
  final XFile file;
  final Uint8List bytes;
}

/// Fotos já salvas (URLs) + fotos escolhidas agora (ainda não enviadas).
class _PhotoSet {
  _PhotoSet([List<String>? urls]) : urls = urls ?? [];

  final List<String> urls;
  final List<_PickedImage> picked = [];

  bool get isEmpty => urls.isEmpty && picked.isEmpty;
}

/// Cor em edição: nome + fotos próprias.
class _ColorDraft {
  _ColorDraft({String name = '', List<String>? urls})
      : name = TextEditingController(text: name),
        photos = _PhotoSet(urls);

  final TextEditingController name;
  final _PhotoSet photos;
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
  final _technical = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController(text: '10');
  final _stock = TextEditingController(text: '0');
  final _customSize = TextEditingController();

  String _category = _categories.first;
  final List<String> _sizes = [];
  bool _featured = false;
  bool _isNew = false;
  bool _hasDiscount = false;
  DateTime? _discountStart;
  DateTime? _discountEnd;
  String? _discountError;
  final _general = _PhotoSet();
  final List<_ColorDraft> _colors = [];

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
        _technical.text = product.technicalDetails;
        _price.text = product.price.toStringAsFixed(2).replaceAll('.', ',');
        _stock.text = (product.stock ?? 0).toString();
        // Desconto ativo ou agendado volta para edição; encerrado aparece desligado.
        final status = product.discountStatus;
        _hasDiscount = status == DiscountStatus.active || status == DiscountStatus.scheduled;
        if (_hasDiscount) {
          _discount.text = product.discountPercent.toString();
          _discountStart = product.discountStartsAt;
          _discountEnd = product.discountEndsAt;
        }
        _category = _categories.contains(product.category) ? product.category : _categories.first;
        _sizes
          ..clear()
          ..addAll(product.sizes);
        _featured = product.isFeatured;
        _isNew = product.isNew;
        // `images` no banco tem todas as fotos; as gerais são as que não são de nenhuma cor.
        final colorImages = {for (final c in product.colorVariants) ...c.images};
        _general.urls.addAll(product.images.where((url) => !colorImages.contains(url)));
        for (final variant in product.colorVariants) {
          _colors.add(_ColorDraft(name: variant.name, urls: [...variant.images]));
        }
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _technical, _price, _discount, _stock, _customSize]) {
      c.dispose();
    }
    for (final color in _colors) {
      color.name.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages(_PhotoSet target) async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1800);
    final picked = <_PickedImage>[];
    for (final file in files) {
      picked.add(_PickedImage(file, await file.readAsBytes()));
    }
    if (!mounted) return;
    setState(() => target.picked.addAll(picked));
  }

  void _addCustomSize() {
    final value = _customSize.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_sizes.any((s) => s.toLowerCase() == value.toLowerCase())) _sizes.add(value);
      _customSize.clear();
    });
  }

  void _toggleSize(String size, bool selected) {
    setState(() {
      if (!selected) {
        _sizes.remove(size);
      } else if (!_sizes.contains(size)) {
        _sizes.add(size);
      }
    });
  }

  void _removeColor(int index) {
    setState(() => _colors.removeAt(index).name.dispose());
  }

  /// Tamanhos padrão na ordem P/M/G/GG, depois os personalizados na ordem em que foram criados.
  List<String> get _orderedSizes => [
        ...CatalogController.sizes.where(_sizes.contains),
        ..._sizes.where((s) => !CatalogController.sizes.contains(s)),
      ];

  Future<void> _save() async {
    final periodError = _hasDiscount ? validateDiscountPeriod(_discountStart, _discountEnd) : null;
    setState(() => _discountError = periodError);
    if (!_formKey.currentState!.validate() || periodError != null) return;
    final admin = context.read<AdminController>();
    final catalog = context.read<CatalogController>();

    final names = [for (final c in _colors) c.name.text.trim().toLowerCase()];
    if (names.toSet().length != names.length) {
      showMessage(context, 'Há cores com o mesmo nome.');
      return;
    }
    if (_general.isEmpty && _colors.every((c) => c.photos.isEmpty)) {
      showMessage(context, 'Adicione pelo menos uma foto.');
      return;
    }

    final product = Product(
      id: _existing?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      technicalDetails: _technical.text.trim(),
      price: double.parse(_price.text.trim().replaceAll(',', '.')),
      discountPercent: _hasDiscount ? int.parse(_discount.text.trim()) : 0,
      discountStartsAt: _hasDiscount ? _discountStart : null,
      discountEndsAt: _hasDiscount ? _discountEnd : null,
      category: _category,
      images: _general.urls,
      sizes: _orderedSizes,
      stock: int.parse(_stock.text.trim()),
      isFeatured: _featured,
      isNew: _isNew,
    );

    final ok = await admin.save(
      product,
      newImages: [for (final p in _general.picked) p.file],
      variants: [
        for (final c in _colors)
          VariantDraft(
            name: c.name.text.trim(),
            images: c.photos.urls,
            newFiles: [for (final p in c.photos.picked) p.file],
          ),
      ],
    );
    if (!mounted) return;
    if (ok) {
      catalog.load(force: true);
      showMessage(context, 'Produto salvo.');
      context.go('/admin/produtos');
    } else {
      showMessage(context, admin.error ?? 'Erro ao salvar.');
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
        onAction: () => context.go('/admin/produtos'),
      );
    }

    final admin = context.watch<AdminController>();
    final text = Theme.of(context).textTheme;
    String? required(String? v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null;
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    final percent = int.tryParse(_discount.text.trim());
    final customSizes = _sizes.where((s) => !CatalogController.sizes.contains(s)).toList();

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
              TextFormField(
                controller: _technical,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Detalhes técnicos (opcional)',
                  hintText: 'Um item por linha. Ex.:\nComposição: 100% algodão\nGramatura: 240 g/m²\nModelagem: oversized',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              _pair(
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Preço (R\$)'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final value = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    return value == null || value < 0 ? 'Preço inválido' : null;
                  },
                ),
                TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade em estoque'),
                  validator: (v) {
                    final value = int.tryParse((v ?? '').trim());
                    return value == null || value < 0 ? 'Número inválido' : null;
                  },
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativar desconto'),
                subtitle: const Text(
                  'Durante o período, o preço cheio aparece riscado e o produto ganha a etiqueta de desconto. '
                  'Para vários produtos de uma vez, use o painel "Descontos".',
                ),
                value: _hasDiscount,
                onChanged: (v) => setState(() => _hasDiscount = v),
              ),
              if (_hasDiscount)
                _pair(
                  TextFormField(
                    controller: _discount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Desconto (%)', suffixText: '%'),
                    onChanged: (_) => setState(() {}),
                    validator: validateDiscountPercent,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      price != null && percent != null && percent > 0 && percent <= 90
                          ? 'Preço com desconto: ${formatCurrency(price * (100 - percent) / 100)}'
                          : 'Informe preço e desconto',
                      style: text.titleSmall,
                    ),
                  ),
                ),
              if (_hasDiscount) ...[
                const SizedBox(height: 12),
                _pair(
                  DateTimeField(
                    label: 'Início do desconto',
                    value: _discountStart,
                    emptyText: 'Imediatamente',
                    onChanged: (v) => setState(() => _discountStart = v),
                  ),
                  DateTimeField(
                    label: 'Fim do desconto',
                    value: _discountEnd,
                    emptyText: 'Sem data de término',
                    onChanged: (v) => setState(() => _discountEnd = v),
                  ),
                ),
                if (_discountError != null) ...[
                  const SizedBox(height: 6),
                  Text(_discountError!, style: text.bodySmall?.copyWith(color: NiceTheme.brightRed)),
                ],
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 24),
              Text('TAMANHOS DISPONÍVEIS', style: text.labelMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final size in CatalogController.sizes)
                    FilterChip(
                      label: Text(size),
                      selected: _sizes.contains(size),
                      selectedColor: NiceTheme.red,
                      labelStyle: NiceTheme.chipLabel(selected: _sizes.contains(size)),
                      onSelected: (selected) => _toggleSize(size, selected),
                    ),
                  for (final size in customSizes)
                    InputChip(
                      label: Text(size),
                      selected: true,
                      selectedColor: NiceTheme.red,
                      labelStyle: NiceTheme.chipLabel(selected: true),
                      deleteIconColor: NiceTheme.white,
                      onDeleted: () => setState(() => _sizes.remove(size)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customSize,
                      decoration: const InputDecoration(
                        hintText: 'Outro tamanho (ex.: 38, 40, Infantil)',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addCustomSize(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _addCustomSize,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
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
              Text('CORES', style: text.labelMedium),
              const SizedBox(height: 4),
              Text(
                'Cadastre cada cor separadamente, com as próprias fotos. Na loja, ao escolher a cor, a foto grande muda para a dessa cor.',
                style: text.bodySmall,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _colors.length; i++) ...[
                _ColorCard(
                  key: ObjectKey(_colors[i]),
                  draft: _colors[i],
                  onPick: () => _pickImages(_colors[i].photos),
                  onRemove: () => _removeColor(i),
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _colors.add(_ColorDraft())),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Adicionar cor'),
                ),
              ),
              const SizedBox(height: 24),
              Text(_colors.isEmpty ? 'FOTOS' : 'FOTOS GERAIS (OPCIONAL)', style: text.labelMedium),
              const SizedBox(height: 4),
              Text(
                _colors.isEmpty
                    ? 'Produto sem variação de cor: adicione as fotos aqui.'
                    : 'Fotos que valem para todas as cores (ex.: detalhes, etiqueta).',
                style: text.bodySmall,
              ),
              const SizedBox(height: 10),
              _PhotoGrid(
                photos: _general,
                onPick: () => _pickImages(_general),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: admin.saving ? null : () => context.goBackOr('/admin/produtos'),
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

class _ColorCard extends StatelessWidget {
  const _ColorCard({
    super.key,
    required this.draft,
    required this.onPick,
    required this.onRemove,
    required this.onChanged,
  });

  final _ColorDraft draft;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NiceTheme.radius),
        border: Border.all(color: NiceTheme.softGray, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nome da cor (ex.: Preto)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome da cor' : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(tooltip: 'Remover cor', icon: const Icon(Icons.delete_outline), onPressed: onRemove),
            ],
          ),
          const SizedBox(height: 12),
          _PhotoGrid(photos: draft.photos, onPick: onPick, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.photos, required this.onPick, required this.onChanged});

  final _PhotoSet photos;
  final VoidCallback onPick;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < photos.urls.length; i++)
          _Thumb(
            child: NiceNetworkImage(url: photos.urls[i], fit: BoxFit.cover),
            onRemove: () {
              photos.urls.removeAt(i);
              onChanged();
            },
          ),
        for (var i = 0; i < photos.picked.length; i++)
          _Thumb(
            child: Image.memory(photos.picked[i].bytes, fit: BoxFit.cover),
            onRemove: () {
              photos.picked.removeAt(i);
              onChanged();
            },
          ),
        Tooltip(
          message: 'Adicionar fotos',
          child: InkWell(
            onTap: onPick,
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
        ),
      ],
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
