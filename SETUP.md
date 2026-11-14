# NICE Store — Flutter + Supabase

## 1. Aplicar o projeto
1. Copie `lib/`, `assets/banners/`, `pubspec.yaml` e `supabase/` para o seu projeto (mantenha `assets/NiceB.PSD.png` e `assets/NiceP.PSD.png`).
2. **Apague** o que sobrou do Firebase e do código antigo:
   - `lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`
   - `lib/src/auth/`, `lib/src/catalog/`, `lib/src/cart/`, `lib/src/favorites/`, `lib/src/database/`
   - `lib/src/widgets/social_button.dart`, `screens/search_screen.dart`, `favorites_screen.dart`, `signup_screen.dart`, `shop_shell.dart`
   - Plugin `com.google.gms.google-services` nos `build.gradle` do Android, se existir.
3. `flutter pub get`
4. Rodar:
   ```
   flutter run -d chrome --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```
   (mesma flag para `flutter run` no Android/iOS e `flutter build web`).

## 2. Supabase
1. SQL Editor → cole e execute `supabase/schema.sql` (tabelas, RLS, bucket `product-images`).
2. Primeiro admin: cadastre-se no app e rode  
   `update public.profiles set role = 'admin' where email = 'SEU_EMAIL';`
3. Authentication → URL Configuration:
   - Site URL: URL do site em produção (ex.: `https://nicestore.com.br`)
   - Redirect URLs: `http://localhost:*/**`, a URL de produção e `io.supabase.nicestore://login-callback/`
4. Authentication → Providers → **Google**: Client ID + Secret (Google Cloud → OAuth *Web application*; Authorized redirect URI = `https://<ref>.supabase.co/auth/v1/callback`).
5. Authentication → Providers → **Apple** (iOS): Services ID/Client ID (= Bundle ID do app para o fluxo nativo), Team ID, Key ID e a chave `.p8`.
6. Authentication → Providers → Email: decida se exige confirmação de e-mail (o app trata os dois casos).

## 3. Configuração nativa
**Android** — `android/app/src/main/AndroidManifest.xml`, dentro de `<activity android:name=".MainActivity">`:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="io.supabase.nicestore" android:host="login-callback"/>
</intent-filter>
```
**iOS** — `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array><dict>
  <key>CFBundleURLSchemes</key>
  <array><string>io.supabase.nicestore</string></array>
</dict></array>
<key>NSPhotoLibraryUsageDescription</key>
<string>Selecionar fotos de produtos (admin).</string>
```
No Xcode: Runner → Signing & Capabilities → **+ Sign in with Apple**.

**Web** — a URL usa caminhos limpos (`/produto/123`): configure o hosting para devolver `index.html` em qualquer rota (Firebase Hosting/Netlify/Vercel: rewrite `/** → /index.html`).

## 4. Regras de acesso (garantidas no banco via RLS)
- Visitante: lê produtos; carrinho/perfil → login.
- Cliente: carrinho, pedidos e perfil só dele.
- Admin (`profiles.role = 'admin'`): escreve produtos, imagens e define Destaque/Novidades.

## Observações
- Os banners em `assets/banners/` são gráficos gerados por código (fundo, skyline, kanji, torii) — não são fotos. Troque pelos arquivos finais mantendo os mesmos nomes.
- O pagamento só registra o método escolhido no pedido (não há gateway).
- Preço do pedido vem do carrinho (snapshot). Para produção, valide preços no servidor (RPC) antes de cobrar.
