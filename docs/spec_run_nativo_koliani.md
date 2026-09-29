# Corrida da Koliani — o que falta e como entra (Execution 9H.18)

> **Estado: NATIVE ART REQUIRED.** O `run` que o jogo usa não tem passada de
> duas pernas. Não é afinação: a informação de movimento não está desenhada.

## A prova

`tools/validar_run_nativo_9h18.py` segue, em cada frame de contacto, o pé de
trás e o da frente, e mede o chão que cada um percorre ao longo do ciclo.
Numa corrida a sério os dois percorrem mais ou menos o mesmo — é o mesmo
movimento desfasado de meio ciclo.

| fonte | frames | contactos | pé de trás | pé da frente | razão | veredito |
|---|---|---|---|---|---|---|
| **`koliani_golden_set/frames/run` (o que o jogo usa)** | 10 | 4/10 (40%) | **7 px** | 29 px | **0,24** | REPROVA |
| `koliani_visual_pilot_5g/run.png` | 12 | 11/12 (92%) | 22 px | 20 px | 0,91 | passa, **mas é outra Koliani** |
| `9H15_koliani_run/frames` (candidato rejeitado) | 8 | 2/8 (25%) | 2 px | 2 px | — | REPROVA |
| `koliani_nova/run.png` | 12 | 6/12 (50%) | 9 px | 7 px | 0,78 | REPROVA |
| `koliani_shadowblade/run.png` | 5 | 2/5 (40%) | 3 px | 2 px | — | REPROVA |

Repetir com:

```bash
python tools/validar_run_nativo_9h18.py assets/sprites/koliani_golden_set/frames/run
```

Medido à parte, os pés em x relativo à anca ao longo dos 10 frames golden:
um deles vive entre −26 e −2 (sempre atrás) e o outro entre +13 e +27
(sempre à frente). Nenhum dos dois atravessa a anca. Aumentar o `fps` ou
baixar o `speed_scale` não cria a pose que falta — por isso a 9H.13 travou
aqui, e por isso a cadência por velocidade (que ficou e é boa) resolveu a
patinagem mas não a alternância.

## Fontes procuradas (e porque nenhuma serve)

- `assets/sprites/koliani_golden_set/frames/run` — a folha aprovada. Reprova.
- `assets/sprites/pixel/koliani{,_gothic,_cavaleiro,_nova,_premium_v1,_shadowblade}/run.png` — rigs antigos.
- `assets/sprites/pixel/koliani_visual_pilot_5g/run.png` — **o único com passada
  a sério**, mas é o desenho anterior (cabelo roxo, saia de chama, sem o lenço
  vermelho): trocar por ele muda a personagem, e o pedido é uma corrida melhor,
  não outra Koliani.
- `Koliani_1.0_Master_Package_v2/references/approved/05_KOLIANI_IDLE_RUN_CLEAN_v1_1.png`
  — tem uma linha RUN de **12 frames**, mas é uma folha de apresentação (xadrez
  pintado em RGB, sem alfa verdadeiro) e do mesmo desenho anterior ao Golden.
- `work/production_art_gate/9H15_koliani_run/` — candidatos gerados na 9H.15,
  já marcados `REJECTED_FOR_PRODUCTION` pela própria execução. Confirmado.
- Histórico de git e todos os ramos: não há mais nenhum ficheiro de corrida
  da Koliani além destes.

## O que é preciso desenhar

Identidade: a do Golden Set aprovado
(`work/production_art_gate/9b1_game_master_approved/koliani_golden_set_approved.png`)
— cara, cabelo, lenço vermelho, fato, proporções, paleta e a Shadowblade
inativa. **Só o ciclo de corrida muda.**

| campo | valor |
|---|---|
| frames | 10 (aceita 8 a 12) |
| tela | 128 × 128 px, RGBA com alfa a sério |
| pivô | (64, 104) |
| base dos pés | y = 103, **igual em todos os frames** (a tolerância do crivo é 2 px) |
| orientação | virada à **direita** (o jogo faz `scale.x = +olha_para`) |
| ciclo | 0,75 s — o `fps` é calculado pelo jogo a partir do número de frames |
| ficheiros | `run_001.png` … `run_010.png`, um por ficheiro |
| pasta | `assets/sprites/koliani_golden_set/frames/run_native/` |
| VFX | nenhum colado ao corpo (pó e rasto são camada à parte) |

Poses obrigatórias do ciclo:

1. contacto do pé esquerdo (pé à frente da anca, pé direito atrás);
2. amortecimento / passagem (pernas cruzadas, pés juntos por baixo da anca);
3. impulso e voo;
4. **contacto do pé direito** — a pose que hoje não existe: é a 1 com as
   pernas trocadas, desenhada, não espelhada;
5. passagem outra vez;
6. voo, e fecha.

Mais: anca a subir e descer (2–3 px), braços em oposição às pernas, nenhum
membro a mudar de tamanho entre frames, nenhum pé a deslizar no contacto.

## Como entra (drop-in, sem tocar em código)

1. largar os PNG em `assets/sprites/koliani_golden_set/frames/run_native/`;
2. `godot --headless --import`;
3. `python tools/validar_run_nativo_9h18.py assets/sprites/koliani_golden_set/frames/run_native`
   — tem de sair 0;
4. correr o jogo. `koliani.gd::_substituir_run_por_nativo()` vê a pasta,
   troca o `run` e recalcula o `fps` para o ciclo continuar a dar 0,75 s.
   O `turn`, o `run_start` e o `run_brake` passam a sair da tira nova, e a
   cadência por velocidade (`_passo_cadencia_locomocao`) continua a mandar.

Enquanto a pasta não existir, nada muda: o jogo corre com o `run` golden.
