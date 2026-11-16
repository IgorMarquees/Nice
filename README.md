# NICE - Streetwear by Japan

Loja virtual de moda asiática e streetwear japonês, feita em Flutter com Supabase. O mesmo código roda no Android, no iOS e na Web.

![NICE](assets/web_carrosel_topo_home1_colocar_hyperlink.png)

## Sobre o projeto

A NICE é uma marca fictícia que criamos como projeto em grupo na Fatec Marília. A ideia era montar uma loja completa com a cara do streetwear japonês: preto, vermelho, kanji e muita tipografia pesada.

O app começou no Firebase e depois migramos tudo pro Supabase. Hoje o projeto tem:

- app para celular, igual no Android e no iOS
- site com layout próprio de e-commerce
- painel de administrador para cuidar de produtos, descontos e usuários
- regras de segurança direto no banco, então ninguém acessa o que não deve só mexendo no app

## O que dá pra fazer

### Na loja

- Navegar pela Home com banners, destaques e categorias
- Ver as Novidades num carrossel com até 3 peças por vez
- Buscar e filtrar produtos no Catálogo por categoria, tamanho e preço
- Ver o produto com várias fotos, escolher tamanho e cor, e as fotos mudam conforme a cor escolhida
- Ver detalhes técnicos, preço com desconto, preço no Pix e aviso de frete grátis
- Montar o carrinho, que fica salvo na conta
- Finalizar a compra escolhendo um endereço salvo ou cadastrando um novo, com o CEP preenchendo o resto sozinho
- Acompanhar os pedidos e ver a política de trocas e devoluções no perfil
- Entrar com e-mail e senha ou com Google no Android e na Web

### No painel do admin

- Cadastrar e editar produtos com fotos, cores com fotos próprias, tamanhos, estoque e detalhes técnicos
- Marcar produtos como Destaque ou Novidade
- Criar descontos com data e hora pra começar e terminar, em um produto só ou em vários de uma vez, e cancelar quando quiser
- Ver os usuários cadastrados, seus endereços e pedidos, e transformar alguém em admin
- Só o admin consegue ver o estoque

## Tecnologias

- **Flutter** e Dart
- **Supabase** pra login, banco de dados Postgres e armazenamento das fotos
- **provider** pro estado da aplicação
- **go_router** pras rotas e pra bloquear páginas de quem não está logado
- **ViaCEP** pra preencher o endereço pelo CEP
- **FakeStoreAPI** como vitrine reserva quando o banco está vazio
- **google_fonts**, **font_awesome_flutter** e **image_picker**

## Como o código está organizado

As telas nunca falam direto com o banco. O caminho é sempre tela → controller → repository → Supabase.

```
lib/
  main.dart          inicia o Supabase e os providers
  src/
    config/          chaves, regras de frete e Pix, caminhos das imagens
    theme/           cores, fontes e estilos do app inteiro
    models/          produto, carrinho, pedido, endereço e usuário
    repositories/    acesso ao Supabase e às APIs
    controllers/     estado e regras de cada parte
    router/          rotas e permissões
    screens/         telas da loja e do painel
    widgets/         componentes reaproveitados
    utils/           formatação e navegação
supabase/
  schema.sql         banco completo
  migrations/        atualizações pra quem já tem o banco criado
test/                testes automatizados
```

O layout muda conforme a plataforma e o tamanho da tela. Na Web aparece o site com menu no topo e rodapé, e no celular aparece a barra vermelha embaixo.

## Rodando na sua máquina

Você vai precisar do Flutter instalado, de uma conta no Supabase e do Chrome ou de um celular Android.

**1. Baixe o projeto**

```bash
git clone https://github.com/IgorMarquees/Nice.git
cd Nice
flutter pub get
```

**2. Rode o app**

Na Web, sempre na porta 5555:

```bash
flutter run -d chrome --web-port=5555 
```

No Android, troque `chrome` pelo id do celular que aparece em `flutter devices`.

**3. Virar admin**

Somente um administrador pode promover outros admins, pelo painel de administrador.

## Banco de dados

| Tabela | O que guarda | Quem acessa |
|---|---|---|
| profiles | nome, e-mail e se é cliente ou admin | cada um vê o seu, admin vê todos |
| products | produtos, fotos, cores, tamanhos e descontos | todo mundo vê, menos o estoque; só admin edita |
| cart_items | carrinho de cada cliente | só o dono |
| orders | pedidos com itens, endereço, frete e desconto | o cliente vê os dele, o admin vê todos |
| addresses | endereços salvos | o dono, e o admin pode consultar |

As fotos ficam no bucket `product-images` e só admin consegue enviar.

## Testes

```bash
flutter analyze
flutter test
```

Os testes abrem todas as telas em mais de 20 tamanhos de tela diferentes, como visitante e como admin, e acusam qualquer coisa quebrando o layout. Também testam busca, carrinho, checkout, troca de fotos por cor e as contas de desconto, Pix e frete.

## Regras da loja

- O desconto só vale entre a data de início e a de fim que o admin escolheu
- Pagando no Pix tem 5% de desconto nos produtos
- Frete grátis a partir de R$ 400 em produtos
- Trocas em até 30 dias com a primeira troca grátis, desistência em até 7 dias e defeito em até 90 dias

## O que ainda falta

- Integração com um meio de pagamento de verdade
- Cálculo de frete pelo CEP e baixa automática do estoque nas vendas
- Mudar o status dos pedidos


