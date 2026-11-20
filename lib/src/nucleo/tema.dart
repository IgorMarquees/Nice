import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema da marca.
/// Nenhuma tela cria cor ou fonte por conta própria.
class TemaNice {
  TemaNice._();

  static const vermelho = Color(0xFFB50000);
  static const vermelhoVivo = Color(0xFFE01414);
  static const vermelhoEscuro = Color(0xFF750000);
  static const preto = Color(0xFF0B0B0C);
  static const grafite = Color(0xFF202020);
  static const cinzaSuave = Color(0xFFE8E8E8);
  static const cinzaClaro = Color(0xFFF4F4F4);
  static const cinzaMedio = Color(0xFF858585);
  static const cinzaTexto = Color(0xFF777777);
  static const branco = Color(0xFFFFFFFF);
  static const sucesso = Color(0xFF1B7F3B);
  static const transparente = Color(0x00000000);
  static const cinzaEscuro = Color(0xFF4A4A4A);
  static const vermelhoSuave = Color(0xFFC46A6A);
  static const cinzaSecao = Color(0xFFF7F7F5);
  static const linhaRodape = Color(0xFF2E2E2E);
  static const veu = Color(0x8A000000);

  static const raio = 8.0;
  static const raioPilula = 28.0;
  static const larguraMaximaConteudo = 1280.0;
  static const larguraTablet = 640.0;
  static const larguraComputador = 1024.0;

  static const sombraLateral = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xCC000000), Color(0x00000000)],
  );
  static const sombraInferior = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0xCC000000)],
  );
  static const sombraSuperior = [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -8))];
  static const sombraSuave = [BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 4))];

  static const degradeRodape = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cinzaSecao, Color(0xFF8A8A8A), preto],
    stops: [0, 0.45, 1],
  );

  static TextStyle _titulo(
    double tamanho, {
    FontWeight peso = FontWeight.w900,
    double altura = 1.05,
    double espacamento = -0.5,
  }) =>
      GoogleFonts.archivo(fontSize: tamanho, fontWeight: peso, height: altura, letterSpacing: espacamento, color: grafite);

  static TextStyle _texto(
    double tamanho, {
    FontWeight peso = FontWeight.w400,
    Color cor = grafite,
    double altura = 1.45,
    double espacamento = 0,
  }) => GoogleFonts.inter(fontSize: tamanho, fontWeight: peso, color: cor, height: altura, letterSpacing: espacamento);

  static TextTheme _estilosTexto() {
    return TextTheme(
      displayLarge: _titulo(72),
      displayMedium: _titulo(52),
      displaySmall: _titulo(34),
      headlineLarge: _titulo(32, peso: FontWeight.w800),
      headlineMedium: _titulo(26, peso: FontWeight.w800),
      headlineSmall: _titulo(22, peso: FontWeight.w800),
      titleLarge: _titulo(18, peso: FontWeight.w800, altura: 1.2, espacamento: 0),
      titleMedium: _texto(16, peso: FontWeight.w800, cor: vermelho),
      titleSmall: _texto(14, peso: FontWeight.w700),
      bodyLarge: _texto(16, altura: 1.55),
      bodyMedium: _texto(14),
      bodySmall: _texto(12, cor: cinzaTexto),
      labelLarge: _texto(14, peso: FontWeight.w700, espacamento: 0.4),
      labelMedium: _texto(12, peso: FontWeight.w700, cor: vermelho, espacamento: 1.2),
      labelSmall: _texto(10, peso: FontWeight.w600, cor: cinzaTexto),
    );
  }

  static TextStyle rotuloChip({required bool selecionado}) =>
      _texto(13, peso: FontWeight.w700, cor: selecionado ? branco : cinzaTexto);

  static TextStyle sobretituloSecao({bool grande = true}) =>
      _texto(grande ? 18 : 14, peso: FontWeight.w500, cor: vermelhoVivo, altura: 1.2);

  /// Título fino cinza e em caixa alta.
  /// A versão pequena é usada no app.
  static TextStyle tituloSecao({bool grande = true, bool pequeno = false}) =>
      _texto(pequeno ? 24 : (grande ? 54 : 30), peso: FontWeight.w300, cor: cinzaEscuro, altura: 0.95, espacamento: -0.5);

  static TextStyle nomeProduto({bool grande = true}) =>
      _texto(grande ? 24 : 16, peso: FontWeight.w700, cor: vermelho, altura: 1.15, espacamento: -0.2);

  static TextStyle subtituloProduto({bool grande = true}) => _texto(grande ? 15 : 12, cor: vermelhoSuave, altura: 1.3);

  static TextStyle preco({bool grande = false}) =>
      _texto(grande ? 28 : 16, peso: grande ? FontWeight.w800 : FontWeight.w600, cor: vermelho, altura: 1.2);

  static TextStyle precoAntigo({bool grande = false}) => _texto(
    grande ? 18 : 13,
    cor: cinzaTexto,
    altura: 1.2,
  ).copyWith(decoration: TextDecoration.lineThrough, decorationColor: cinzaTexto);

  static TextStyle selo() => _texto(11, peso: FontWeight.w800, cor: branco, espacamento: 0.6, altura: 1.1);

  static TextStyle espacado({Color cor = branco}) => _texto(13, peso: FontWeight.w500, cor: cor, espacamento: 4);

  static TextStyle tituloRodape() => _titulo(44, espacamento: -0.5).copyWith(color: branco);

  static TextStyle linkRodape() => _texto(16, cor: cinzaSuave);

  static TextStyle kanji() => _texto(30, peso: FontWeight.w400, cor: grafite, altura: 1.15);

  static TextStyle tituloDestaque({bool grande = true}) =>
      _texto(grande ? 38 : 28, peso: FontWeight.w500, cor: grafite, altura: 1.05, espacamento: 0.5);

  static TextStyle linkEspacado() => _texto(13, peso: FontWeight.w700, cor: grafite, espacamento: 2);

  static TextStyle rotuloCategoria({bool grande = true}) =>
      _texto(grande ? 30 : 18, peso: FontWeight.w600, cor: branco, altura: 1.1);

  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: vermelho,
      primary: vermelho,
      secondary: grafite,
      surface: branco,
      error: vermelhoVivo,
    );
    final bordaCampo = OutlineInputBorder(borderRadius: BorderRadius.circular(raio), borderSide: BorderSide.none);

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: branco,
      textTheme: _estilosTexto(),
      dividerTheme: const DividerThemeData(color: cinzaSuave, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: branco,
        foregroundColor: grafite,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _titulo(18, peso: FontWeight.w800, espacamento: 0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: vermelho,
          foregroundColor: branco,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(raio)),
          textStyle: _texto(14, peso: FontWeight.w800, espacamento: 0.6),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: grafite,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: cinzaSuave, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(raio)),
          textStyle: _texto(14, peso: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: vermelho,
          textStyle: _texto(13, peso: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cinzaClaro,
        hintStyle: _texto(14, cor: cinzaTexto),
        labelStyle: _texto(14, cor: cinzaTexto),
        border: bordaCampo,
        enabledBorder: bordaCampo,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(raio),
          borderSide: const BorderSide(color: vermelho, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(raio),
          borderSide: const BorderSide(color: vermelhoVivo),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(raio),
          borderSide: const BorderSide(color: vermelhoVivo, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cinzaClaro,
        selectedColor: vermelho,
        showCheckmark: false,
        side: BorderSide.none,
        labelStyle: rotuloChip(selecionado: false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(raioPilula)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected) ? branco : cinzaMedio,
        ),
        trackColor: WidgetStateProperty.resolveWith((estados) => estados.contains(WidgetState.selected) ? vermelho : cinzaSuave),
        trackOutlineColor: const WidgetStatePropertyAll(transparente),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: grafite,
        contentTextStyle: _texto(14, cor: branco),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(raio)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: branco,
        titleTextStyle: _titulo(20, peso: FontWeight.w800, espacamento: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(raio)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: branco, showDragHandle: true),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: vermelho),
      sliderTheme: const SliderThemeData(
        activeTrackColor: vermelho,
        thumbColor: vermelho,
        inactiveTrackColor: cinzaSuave,
        overlayColor: Color(0x1FB50000),
      ),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(vermelho)),
      bottomAppBarTheme: const BottomAppBarThemeData(color: vermelho, surfaceTintColor: transparente),
    );
  }
}
