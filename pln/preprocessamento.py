# Mesmas regras de lib/src/nucleo/processamento_texto.dart
# Se mudar aqui mude lá também porque o teste de consistência compara os dois

import re

ACENTOS = str.maketrans('áàâãäéèêëíìîïóòôõöúùûüçñ', 'aaaaaeeeeiiiiooooouuuucn')

STOPWORDS = {
    'a', 'ao', 'aos', 'as', 'com', 'da', 'das', 'de', 'do', 'dos', 'e', 'em', 'me', 'meu', 'minha',
    'na', 'nas', 'no', 'nos', 'o', 'os', 'ou', 'para', 'pra', 'pro', 'por', 'que', 'quero', 'queria',
    'um', 'uma', 'uns', 'umas', 'tem', 'algum', 'alguma', 'procuro', 'procurando', 'preciso', 'busco',
    'mostra', 'mostrar', 'ver', 'nice', 'loja', 'voces', 'vcs', 'tipo', 'estilo', 'algo', 'coisa', 'usar',
}

# Palavras que terminam em s no singular
SEM_PLURAL = {'tenis', 'jeans', 'lapis', 'onibus', 'mais', 'menos'}

# Ordem importa: o sufixo mais longo é testado primeiro
SUFIXOS_PLURAL = [
    ('oes', 'ao'), ('aes', 'ao'), ('ais', 'al'), ('eis', 'el'), ('ois', 'ol'),
    ('ns', 'm'), ('res', 'r'), ('zes', 'z'), ('s', ''),
]

# Grafias diferentes da mesma peça viram uma palavra só
SINONIMOS = {
    'moleton': 'moletom', 'hoodie': 'moletom', 'hoody': 'moletom',
    'tee': 'camiseta', 'tshirt': 'camiseta', 'shirt': 'camiseta', 'camisa': 'camiseta',
    'jean': 'jeans',
}


def normalizar(texto):
    texto = texto.lower().translate(ACENTOS)
    return re.sub(r'[^a-z0-9]+', ' ', texto).strip()


def radical(palavra):
    if len(palavra) <= 3 or palavra in SEM_PLURAL:
        return palavra
    for sufixo, troca in SUFIXOS_PLURAL:
        if palavra.endswith(sufixo) and len(palavra) - len(sufixo) >= 2:
            return palavra[: -len(sufixo)] + troca
    return palavra


def preprocessar(texto):
    termos = []
    for palavra in normalizar(texto).split():
        if palavra in STOPWORDS:
            continue
        palavra = radical(palavra)
        termos.append(SINONIMOS.get(palavra, palavra))
    return termos
