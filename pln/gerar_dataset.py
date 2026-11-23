# Monta o dataset de consultas de busca rotuladas com a categoria da loja
# As consultas imitam o que um cliente digita: peça com cor e estilo e às vezes com erro de digitação
# Semente fixa para o dataset sair igual em toda execução

import csv
import random
from pathlib import Path

random.seed(42)

PECAS = {
    'Camisetas': [
        'camiseta', 'camisetas', 'camisa', 'tee', 't-shirt', 'regata', 'blusinha', 'baby look',
        'camiseta oversized', 'camiseta manga longa', 'camiseta manga curta', 'camisa polo',
        'cropped', 'camiseta básica', 'camiseta estampada', 'top', 'blusa de manga curta',
        'camiseta dry fit', 'camiseta gola alta', 'camiseta longline',
    ],
    'Moletons': [
        'moletom', 'moleton', 'moletons', 'hoodie', 'blusa de frio', 'casaco', 'agasalho',
        'jaqueta', 'corta vento', 'blusão', 'canguru', 'moletom com capuz', 'moletom de zíper',
        'moletom peluciado', 'casaco de inverno', 'jaqueta bomber', 'sueter', 'blusa de lã',
        'jaqueta college', 'windbreaker',
    ],
    'Calças': [
        'calça', 'calças', 'calça cargo', 'jogger', 'calça jeans', 'jeans', 'bermuda', 'shorts',
        'calça larga', 'calça wide leg', 'calça de sarja', 'calça tactel', 'calça de moletom',
        'calça baggy', 'pantalona', 'bermuda cargo', 'short de tactel', 'calça reta',
        'calça skinny', 'parachute pants',
    ],
    'Acessórios': [
        'boné', 'bonés', 'chapéu bucket', 'bucket', 'gorro', 'touca', 'meia', 'meias', 'pochete',
        'bolsa', 'mochila', 'shoulder bag', 'corrente', 'colar', 'anel', 'anéis', 'pulseira',
        'óculos', 'cinto', 'chaveiro', 'tote bag', 'carteira', 'bandana', 'brinco',
    ],
}

# Modificadores compartilhados entre as categorias deixam o problema menos trivial
CORES = ['preto', 'preta', 'branco', 'branca', 'vermelho', 'vermelha', 'cinza', 'azul', 'verde',
         'bege', 'off white', 'grafite', 'marrom', 'roxo', 'rosa']
ESTILOS = ['oversized', 'streetwear', 'japonês', 'japonesa', 'estampa japonesa', 'anime', 'kanji',
           'minimalista', 'básico', 'tie dye', 'cyberpunk', 'tokyo', 'harajuku', 'vintage',
           'largo', 'larga', 'masculino', 'feminina', 'unissex', 'com logo', 'bordado', 'nice']
EXTRAS = ['barato', 'promoção', 'até 100 reais', 'tamanho g', 'tamanho p', 'tamanho gg', 'em oferta',
          'lançamento', 'novo', 'de algodão', 'de couro', 'de nylon']
INICIOS = ['', '', '', '', 'quero', 'procuro', 'tem', 'me mostra', 'queria um', 'preciso de',
           'busco', 'quero uma', 'vcs tem']

# Pedidos sem o nome da peça: só o contexto indica a categoria
CONTEXTO = {
    'Camisetas': ['algo leve pro calor', 'roupa pra usar no verão', 'peça pra usar por baixo da jaqueta',
                  'estampa pra usar no dia a dia', 'algo de manga curta'],
    'Moletons': ['algo pra esquentar no frio', 'roupa de inverno', 'algo com capuz',
                 'peça pra usar quando esfriar', 'roupa quente pra viagem'],
    'Calças': ['algo pra usar nas pernas', 'parte de baixo do look', 'roupa pra perna larga',
               'algo com bolsos laterais', 'peça de baixo pra andar de skate'],
    'Acessórios': ['algo pra cabeça', 'presente pequeno', 'algo pra completar o look',
                   'coisa pra guardar o celular', 'algo pra usar no pescoço'],
}


def erro_de_digitacao(palavra):
    if len(palavra) < 5:
        return palavra
    i = random.randrange(1, len(palavra) - 1)
    tipo = random.choice(['troca', 'apaga', 'dobra'])
    if tipo == 'troca':
        return palavra[:i] + palavra[i + 1] + palavra[i] + palavra[i + 2:]
    if tipo == 'apaga':
        return palavra[:i] + palavra[i + 1:]
    return palavra[:i] + palavra[i] + palavra[i:]


def consulta(categoria):
    peca = random.choice(PECAS[categoria])
    if random.random() < 0.15:
        palavras = peca.split()
        palavras[0] = erro_de_digitacao(palavras[0])
        peca = ' '.join(palavras)
    partes = [random.choice(INICIOS), peca]
    if random.random() < 0.6:
        partes.append(random.choice(CORES))
    if random.random() < 0.5:
        partes.append(random.choice(ESTILOS))
    if random.random() < 0.25:
        partes.append(random.choice(EXTRAS))
    return ' '.join(p for p in partes if p)


def main():
    linhas = []
    for categoria in PECAS:
        for _ in range(190):
            linhas.append((consulta(categoria), categoria))
        for frase in CONTEXTO[categoria]:
            linhas.append((frase, categoria))
            linhas.append((f'{random.choice(INICIOS[4:])} {frase}', categoria))
    random.shuffle(linhas)
    destino = Path(__file__).parent / 'dados' / 'consultas.csv'
    destino.parent.mkdir(exist_ok=True)
    with destino.open('w', newline='', encoding='utf-8') as arquivo:
        escritor = csv.writer(arquivo)
        escritor.writerow(['texto', 'categoria'])
        escritor.writerows(linhas)
    print(f'{len(linhas)} consultas salvas em {destino}')


if __name__ == '__main__':
    main()
