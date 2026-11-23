# Busca inteligente: PLN do catálogo

Aqui fica o treino do modelo que a busca do catálogo usa para entender o que o cliente digitou.

O pipeline:

1. **Pré-processamento** (`preprocessamento.py`): minúsculas, sem acentos e pontuação, sem palavras vazias como "quero" e "pra", plural vira singular e grafias diferentes viram uma só (moleton e hoodie viram moletom).
2. **Vetorização** com TF-IDF.
3. **Classificador** Multinomial Naive Bayes, que adivinha a categoria da consulta (Camisetas, Moletons, Calças ou Acessórios).
4. **Avaliação** com separação de 80% para treino e 20% para teste, acurácia, validação cruzada e matriz de confusão (em `resultados/`).
5. **Exportação** do modelo para `lib/src/dados/modelo_categorias.dart`, que roda dentro do app em Android, iOS e Web sem servidor.

No app, a busca junta duas coisas:

- um índice TF-IDF dos produtos, com similaridade do cosseno e tolerância a erro de digitação (`lib/src/dados/indice_busca.dart`);
- a categoria prevista pelo modelo, que dá um bônus de relevância e aparece como atalho "Ver tudo em ..." (`lib/src/dados/classificador_categorias.dart`).

## Como treinar de novo

```bash
cd pln
pip install -r requirements.txt
python gerar_dataset.py   # só se quiser recriar o dataset
python treinar.py
cd ..
flutter test test/busca_inteligente_test.dart
```

O `treinar.py` também gera `test/dados_pln/casos_teste.json`. Esse arquivo é usado no teste do Flutter que confere se o modelo no app prevê exatamente o mesmo que o modelo do Python.

As regras de pré-processamento existem em Python e em Dart (`lib/src/nucleo/processamento_texto.dart`). Se mudar uma, mude a outra: o teste de consistência falha se as duas divergirem.

## Dataset

`dados/consultas.csv` tem 800 consultas criadas pelo grupo a partir do vocabulário da loja: peças, cores, estilos, erros de digitação e pedidos sem o nome da peça, como "algo pra esquentar no frio". A semente é fixa, então o resultado se repete a cada execução.
