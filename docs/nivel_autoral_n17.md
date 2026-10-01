# N17 autoral — "Fundição" (Região IV, Fornalha)

**Data:** 30 set 2026 · **Branch:** `claude/project-thread-lu210k` · **Cena:**
`scenes/levels/Galeria_dos_Ossos.tscn` (nome legado) · **Gerada por:**
`tools/construir_n17_fundicao.py` (+ `tools/r4_lib.py`). Chave i18n `level.n16`.
Arte e pipeline: ver `docs/nivel_autoral_n16.md`.

## Layout (5200 × ~900 px, dois níveis: chão a 800, galeria alta a 500)
| Secção | O que se faz |
|---|---|
| A salão | Trabalhador + Lança-chamas; 1.ª poça atravessada por **3 lajes que desabam** (0,6 s; voltam em 2,6 s) |
| B forno | piso quente, Lança-chamas; **elevador de corrente 1** (sobe com o peso, 300 px) para a galeria alta |
| C poça grande | **rota alta**: galeria A (Arqueiro) → 2 **carrinhos** de trilho → galeria B, com 2 **jatos de teto** nos pontos de transferência; **rota baixa**: cair na lava (22 por 0,6 s), degraus de saída de 60+60 px |
| D salão inferior | **elevador 2 de vaivem** desce da galeria B; piso quente em fase oposta, Drone de lava, Trabalhador |
| E arena | 2 lajes que desabam em escada, arena alta (700) com piso quente, 2 jatos desencontrados e **Autómato de Fundição elite** a guardar o portão |

5 checkpoints; 3 segredos (alcova acima da galeria A; saliência a meio da poça,
200 px abaixo dos carrinhos; alcova do salão inferior). Inimigos: Trabalhador
Corrompido, Arqueiro da Fornalha, Lança-chamas, Drone de Lava, Autómato de Fundição.

## Mecânicas novas (opt-in)
`ElevadorColuna` ganhou `textura_corrente`, `textura_roldana` e `escala_roldana`
(vazios = Torre dos Ecos, nenhum nível antigo muda). O resto reutiliza
PisoQuente/JatoFornalha/LavaFornalha, PlataformaQuebra e PlataformaCorrente.

## Lições do bot (travessia real)
- Poças sem saída: o bot casual morria repetidamente na lava → **degraus de saída**
  em cada lado (60 + 60 px em vez de um muro de 120).
- Jatos de chão sob a rota dos carrinhos eram injustos (queimavam quem viajava) →
  passaram a **jatos de teto** que só apanham quem salta entre lajes.
- Paredes das poças fecham o vão sob as lajes (lição do N16).

## Travessia e testes
`tools/correr_travessia.sh res://scenes/levels/Galeria_dos_Ossos.tscn experiente normal casual`:
**os 3 perfis chegam à porta** (25 a 85 s; experiente 1 morte, normal 2, casual 10 —
o casual falha 17 % dos saltos e cai na poça grande). Teste estrutural
`tests/test_region04_n17_level.gd`. Capturas em `docs/qa/n17_autoral/`.

## Decisões (opção recomendada)
Lava não letal; rota baixa pela poça é legítima (custa vida, não tempo); o
guardião do N17 é o Autómato de Fundição elite (os chefes ficam para o N20).
