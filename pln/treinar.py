# Treina o classificador que adivinha a categoria a partir do que o cliente digita na busca
# Pipeline: texto bruto -> pré-processamento -> TF-IDF -> Naive Bayes -> categoria
# Também exporta o modelo para o app em Dart e os casos usados nos testes do Flutter

import csv
import json
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import make_pipeline

from preprocessamento import preprocessar

PASTA = Path(__file__).parent
RAIZ = PASTA.parent
RESULTADOS = PASTA / 'resultados'
ARQUIVO_DART = RAIZ / 'lib' / 'src' / 'dados' / 'modelo_categorias.dart'
CASOS_TESTE = RAIZ / 'test' / 'dados_pln' / 'casos_teste.json'

EXEMPLOS_PREPROCESSAMENTO = [
    'Moletons PRETOS com capuz',
    'quero uma camiseta oversized do Japão',
    'Calças cargo bege',
    'Bonés e anéis',
    'tem hoodie tamanho GG?',
    'T-shirt estampada',
    'calça de moletom',
    'Óculos de sol & correntes',
    'camisa sem manga',
    'jeans larga',
]


def carregar():
    with (PASTA / 'dados' / 'consultas.csv').open(encoding='utf-8') as arquivo:
        linhas = list(csv.DictReader(arquivo))
    # Consultas repetidas iriam parar no treino e no teste e inflariam a acurácia
    vistos, textos, rotulos = set(), [], []
    for linha in linhas:
        if linha['texto'] in vistos:
            continue
        vistos.add(linha['texto'])
        textos.append(linha['texto'])
        rotulos.append(linha['categoria'])
    return textos, rotulos, len(linhas)


def vetorizador():
    # O texto já chega pré-processado e separado por espaço
    return TfidfVectorizer(token_pattern=r'\S+', lowercase=False)


def salvar_matriz(matriz, classes, acuracia):
    fig, eixo = plt.subplots(figsize=(6.4, 5.4), dpi=200)
    fig.patch.set_facecolor('#151516')
    eixo.set_facecolor('#151516')
    eixo.imshow(matriz, cmap=matplotlib.colors.LinearSegmentedColormap.from_list('nice', ['#1E1E20', '#E01414']))
    for i in range(len(classes)):
        for j in range(len(classes)):
            eixo.text(j, i, matriz[i, j], ha='center', va='center', fontsize=16, fontweight='bold', color='white')
    eixo.set_xticks(range(len(classes)), classes, color='white', fontsize=10)
    eixo.set_yticks(range(len(classes)), classes, color='white', fontsize=10)
    eixo.set_xlabel('Previsto', color='#9A9A9A', fontsize=10)
    eixo.set_ylabel('Real', color='#9A9A9A', fontsize=10)
    eixo.set_title(f'Acurácia no teste: {acuracia:.1%}', color='white', fontsize=12, fontweight='bold')
    for borda in eixo.spines.values():
        borda.set_visible(False)
    eixo.tick_params(length=0)
    fig.tight_layout()
    fig.savefig(RESULTADOS / 'matriz_confusao.png', facecolor=fig.get_facecolor())
    plt.close(fig)


def numero(valor):
    return f'{valor:.8f}'


def exportar_dart(vetor, modelo):
    vocabulario = sorted(vetor.vocabulary_.items(), key=lambda par: par[1])
    classes = list(modelo.classes_)
    linhas = [
        '// Gerado por pln/treinar.py. Não edite à mão.',
        '// TF-IDF mais Naive Bayes treinados com as consultas de pln/dados/consultas.csv.',
        '',
        'const categoriasModelo = [' + ', '.join(f"'{c}'" for c in classes) + '];',
        '',
        'const logPrioriModelo = [' + ', '.join(numero(v) for v in modelo.class_log_prior_) + '];',
        '',
        'const vocabularioModelo = {',
        *[f"  '{termo}': {indice}," for termo, indice in vocabulario],
        '};',
        '',
        'const idfModelo = [',
        *[f'  {numero(v)},' for v in vetor.idf_],
        '];',
        '',
        'const logProbTermosModelo = [',
    ]
    for linha in modelo.feature_log_prob_:
        linhas.append('  [' + ', '.join(numero(v) for v in linha) + '],')
    linhas.append('];')
    ARQUIVO_DART.write_text('\n'.join(linhas) + '\n', encoding='utf-8')


def main():
    RESULTADOS.mkdir(exist_ok=True)
    textos, rotulos, total_bruto = carregar()
    preparados = [' '.join(preprocessar(t)) for t in textos]

    treino_x, teste_x, treino_y, teste_y, _, teste_texto = train_test_split(
        preparados, rotulos, textos, test_size=0.2, random_state=42, stratify=rotulos)

    vetor = vetorizador()
    x_treino = vetor.fit_transform(treino_x)
    x_teste = vetor.transform(teste_x)

    modelo = MultinomialNB(alpha=0.1)
    modelo.fit(x_treino, treino_y)
    previsto = modelo.predict(x_teste)
    acuracia = accuracy_score(teste_y, previsto)

    regressao = LogisticRegression(max_iter=2000).fit(x_treino, treino_y)
    acuracia_regressao = accuracy_score(teste_y, regressao.predict(x_teste))
    validacao = cross_val_score(make_pipeline(vetorizador(), MultinomialNB(alpha=0.1)), preparados, rotulos, cv=5)

    classes = list(modelo.classes_)
    matriz = confusion_matrix(teste_y, previsto, labels=classes)
    relatorio = classification_report(teste_y, previsto, digits=3)
    erros = [(t, r, p) for t, r, p in zip(teste_texto, teste_y, previsto) if r != p]

    texto = [
        f'Consultas no CSV: {total_bruto}  únicas: {len(textos)}',
        f'Treino: {len(treino_x)}  teste: {len(teste_x)}  vocabulário: {len(vetor.vocabulary_)} termos',
        '',
        f'Naive Bayes  acurácia no teste: {acuracia:.3f}',
        f'Naive Bayes  validação cruzada 5 partes: {validacao.mean():.3f} +- {validacao.std():.3f}',
        f'Regressão logística  acurácia no teste: {acuracia_regressao:.3f}',
        '',
        'Matriz de confusão  linhas = real  colunas = previsto',
        '                ' + ' '.join(f'{c[:10]:>10}' for c in classes),
        *[f'{c[:14]:>14}  ' + ' '.join(f'{v:>10}' for v in linha) for c, linha in zip(classes, matriz)],
        '',
        relatorio,
        'Erros no teste:',
        *[f'  "{t}"  real={r}  previsto={p}' for t, r, p in erros],
    ]
    (RESULTADOS / 'metricas.txt').write_text('\n'.join(texto) + '\n', encoding='utf-8')
    print('\n'.join(texto))

    salvar_matriz(matriz, classes, acuracia)
    exportar_dart(vetor, modelo)

    probabilidades = modelo.predict_proba(x_teste)
    CASOS_TESTE.parent.mkdir(exist_ok=True)
    CASOS_TESTE.write_text(json.dumps({
        'acuracia_python': acuracia,
        'preprocessamento': [{'texto': t, 'termos': preprocessar(t)} for t in EXEMPLOS_PREPROCESSAMENTO],
        'casos': [
            {'texto': t, 'real': r, 'previsto': p, 'confianca': round(float(np.max(pr)), 6)}
            for t, r, p, pr in zip(teste_texto, teste_y, previsto, probabilidades)
        ],
    }, ensure_ascii=False, indent=1), encoding='utf-8')
    print(f'\nModelo exportado para {ARQUIVO_DART.relative_to(RAIZ)}')


if __name__ == '__main__':
    main()
