# Koliani Golden Set — arte final de produção (Execution 9B.1)

**Estado: VAZIO. Nenhum frame produzido.**

Esta pasta é o local isolado da arte **final** da Koliani. Não se mistura aqui
nada de legado: `koliani_premium_v1`, `koliani_shadowblade` e
`koliani_visual_pilot_5g` ficam onde estão e **não** são movidos para cá.

## Contrato de canvas — vale para todo o Golden Set

| Parâmetro | Valor |
|---|---|
| Canvas | **128 × 128** px por frame |
| Formato | PNG, **RGBA**, alfa real (tem de haver píxeis com alfa 0) |
| Altura da personagem em repouso | **64 px** |
| Linha dos pés (pivot) | **Y = 104** |
| Última linha opaca (baseline) | **Y = 103**, tolerância ±1 |
| Pivot | **(64, 104)** |
| Orientação | virada à **direita** |
| Escala no Godot | **1.0** (sem reamostragem) |
| `_corpo.offset` | **(0, −18)** |
| Filtro | `Nearest` (já é o omissão do projeto) |

A fórmula que fixa a linha dos pés no mundo é
`(baseline − altura_da_célula/2 + offset) × escala = 22`, onde 22 é o fundo da
caixa de colisão de 20×44. Com 128/104/−18/1.0 dá exactamente 22, o mesmo que o
rig actual — **a personagem aparece do mesmo tamanho no ecrã que hoje**
(64 px num viewport de 1280×720), por isso nada de física, câmara, colisão ou
tempos de combate precisa de mudar.

## Porquê 128 × 128

Medido nos frames actuais, não arbitrado:

- a figura em repouso ocupa 78 px na célula de 160×96 e aparece a 64 px no ecrã
  (escala 0,82) — o Golden Set desenha esses **64 px directamente**, a 1:1;
- o cabelo solto na corrida leva a caixa até **80 px de largura**;
- as poses de ataque do protótipo legado chegam a **124 px de largura** e
  **rebentam a célula de 160** (o validador acusa `CLIPPED_RIGHT`);
- as poses no ar precisam de margem por cima sem encolher a figura.

128 de largura dá 64 px para cada lado do pivot — chega para o cabelo e para o
alcance da lâmina. 128 de altura dá 40 px acima da cabeça (cabelo a levantar,
lâmina em guarda alta) e 24 px abaixo da linha dos pés.

## Regras de conteúdo

- **Corpo** pode conter corpo, rosto, roupa, cabelo, lenço e amuleto de Elara;
- **Shadowblade** acompanha a pose quando a relação mão/arma o exigir;
- **VFX vão em `vfx/`, em ficheiros próprios.** Nenhum arco de golpe, rasto,
  poeira, faísca ou aura pintado dentro de um frame de corpo. Foi esse o erro
  da `koliani_premium_v1` e não se repete;
- Shadowblade = **violeta claro e limpo**; corrupção = violeta escuro, magenta
  profundo e preto. Têm de continuar distinguíveis.

## Proibições duras (contrato congelado)

Sem chibi, sem cabeça grande, sem pernas curtas, sem rabo-de-cavalo, sem fita
de cabeça, sem cabelo curto, sem cabelo roxo a substituir o canónico. Cabelo
**sempre comprido e sempre solto**, raízes pretas e pontas vermelhas. Mesmo
rosto, mesma silhueta, mesmas proporções, mesma roupa e mesma idade aparente em
**todos** os frames, incluindo os do ar.

**Regra de aceitação medida:** nenhum frame pode perder mais de **8%** da
altura da figura em repouso (64 px → mínimo **59 px**) sem justificação de
pose. Os frames de salto actuais perdem até 18% — é o defeito que o Game Master
identificou.

## Como validar

```bash
python -m tools.production_asset_validator.cli assets/sprites/koliani_golden_set/frames/idle/manifest.json --json work/golden_set/idle.json --markdown work/golden_set/idle.md --contact-sheet work/golden_set/idle_sheet.png --scale 3
```

O `PASS` do validador é **necessário e não suficiente**: cobre alfa, canvas,
corte, baseline, pivot e consistência, mas **não** vê rabo-de-cavalo, idade,
proporções nem identidade. Isso é o Gate 2, e quem decide é o Game Master.
