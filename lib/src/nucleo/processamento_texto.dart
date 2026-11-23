// Mesmas regras de pln/preprocessamento.py
// Se mudar aqui mude lá também porque o teste de consistência compara os dois

const _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const _semAcento = 'aaaaaeeeeiiiiooooouuuucn';

const stopwords = {
  'a', 'ao', 'aos', 'as', 'com', 'da', 'das', 'de', 'do', 'dos', 'e', 'em', 'me', 'meu', 'minha',
  'na', 'nas', 'no', 'nos', 'o', 'os', 'ou', 'para', 'pra', 'pro', 'por', 'que', 'quero', 'queria',
  'um', 'uma', 'uns', 'umas', 'tem', 'algum', 'alguma', 'procuro', 'procurando', 'preciso', 'busco',
  'mostra', 'mostrar', 'ver', 'nice', 'loja', 'voces', 'vcs', 'tipo', 'estilo', 'algo', 'coisa', 'usar',
};

/// Palavras que terminam em s no singular.
const _semPlural = {'tenis', 'jeans', 'lapis', 'onibus', 'mais', 'menos'};

/// O sufixo mais longo é testado primeiro.
const _sufixosPlural = [
  ('oes', 'ao'), ('aes', 'ao'), ('ais', 'al'), ('eis', 'el'), ('ois', 'ol'),
  ('ns', 'm'), ('res', 'r'), ('zes', 'z'), ('s', ''),
];

/// Grafias diferentes da mesma peça viram uma palavra só.
const _sinonimos = {
  'moleton': 'moletom', 'hoodie': 'moletom', 'hoody': 'moletom',
  'tee': 'camiseta', 'tshirt': 'camiseta', 'shirt': 'camiseta', 'camisa': 'camiseta',
  'jean': 'jeans',
};

final _foraDoAlfabeto = RegExp('[^a-z0-9]+');

String normalizarTexto(String texto) {
  final buffer = StringBuffer();
  for (final letra in texto.toLowerCase().split('')) {
    final i = _comAcento.indexOf(letra);
    buffer.write(i < 0 ? letra : _semAcento[i]);
  }
  return buffer.toString().replaceAll(_foraDoAlfabeto, ' ').trim();
}

String radical(String palavra) {
  if (palavra.length <= 3 || _semPlural.contains(palavra)) return palavra;
  for (final (sufixo, troca) in _sufixosPlural) {
    if (palavra.endsWith(sufixo) && palavra.length - sufixo.length >= 2) {
      return palavra.substring(0, palavra.length - sufixo.length) + troca;
    }
  }
  return palavra;
}

/// Texto bruto vira a lista de termos usada pela busca e pelo classificador.
List<String> preprocessar(String texto) => [
  for (final palavra in normalizarTexto(texto).split(' '))
    if (palavra.isNotEmpty && !stopwords.contains(palavra)) _sinonimos[radical(palavra)] ?? radical(palavra),
];

/// Distância de Levenshtein que desiste cedo quando passa do limite.
int distanciaEdicao(String a, String b, {int limite = 2}) {
  if ((a.length - b.length).abs() > limite) return limite + 1;
  var anterior = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final atual = List<int>.filled(b.length + 1, 0)..[0] = i;
    var menorDaLinha = atual[0];
    for (var j = 1; j <= b.length; j++) {
      final custo = a[i - 1] == b[j - 1] ? 0 : 1;
      atual[j] = [anterior[j] + 1, atual[j - 1] + 1, anterior[j - 1] + custo].reduce((x, y) => x < y ? x : y);
      if (atual[j] < menorDaLinha) menorDaLinha = atual[j];
    }
    if (menorDaLinha > limite) return limite + 1;
    anterior = atual;
  }
  return anterior[b.length];
}
