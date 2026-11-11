import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../catalog/catalog_controller.dart';
import '../theme/nice_theme.dart';
import '../widgets/nice_logo.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final catalog = context.watch<CatalogController>();
    final products = catalog.products;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverList.list(
              children: [
                const Center(child: NiceLogo(compact: true)),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bem-Vindo, ${auth.user?.name ?? 'Ale'}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: NiceTheme.textGray,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Notificacoes',
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  onChanged: catalog.search,
                  decoration: const InputDecoration(
                    hintText: 'Encontre seu Drip...',
                    prefixIcon: Icon(Icons.search, color: NiceTheme.red),
                    filled: true,
                    fillColor: NiceTheme.softGray,
                  ),
                ),
                const SizedBox(height: 34),
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.checkroom, size: 52, color: NiceTheme.charcoal),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Defina seu estilo. Domine as ruas', style: TextStyle(color: NiceTheme.red, fontWeight: FontWeight.w800)),
                            SizedBox(height: 8),
                            Text('Autenticidade, atitude e design urbano em cada detalhe', style: TextStyle(color: Color(0xFFD96F6F))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 42),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Escolhas do momento', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: NiceTheme.textGray)),
                          const Text('O que esta dominando as ruas'),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Veja tudo')),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          if (catalog.loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverGrid.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) => ProductCard(product: products[index]),
              ),
            ),
        ],
      ),
    );
  }
}
