# Plano de melhoria N1–N20 — Fase A + B2 (3 out 2026)

Origem: `docs/qa/full_game_review/PROMPT_CHATGPT_PLANO_N1_N20.md` (opção 2 do
Paulo: âmbito N1–N20). Decisões tomadas no arranque: DEC-011 a DEC-014 em
`docs/decisoes.md` (nomes canónicos; 2 guardiões + boss por região; 1–2 salas
que fecham até limpar; N11 refeito agora). Branch `plano-n1-n19`, worktree
`C:\Projetos\koliani-plano`.

## Feito

| Tarefa | Commit | Resultado |
|---|---|---|
| A0/A1 | (origin `4e9e1fdf`, outra sessão) | Mesmo diagnóstico que o meu: 4 falhas = Shadowblade duplicada (bug), 5 = teste da Pausa obsoleto. Integrado por rebase; a minha versão duplicada saiu. |
| A2 | `feat(loja): placeholders fora da grelha` | `LojaCatalogo.visivel_na_loja()`; dados intactos. |
| A3 | `fix(i18n): nomes canonicos…` | Região I "Floresta Sagrada", IV "Fornalha", boss N5 "Guardião Verde" nos 6 idiomas (`level.n00` acompanha). Seletor sem texto escrito à mão (11 chaves `selector.*`). Ids internos iguais. |
| A5 | `fix(dev): "DEVELOPER MODE" fora das builds publicas` | O interruptor `koliani/qa/entrada_dev` manda sempre que existe; o CI desliga-o antes de exportar Web/APK/Windows. As builds locais do Paulo continuam com a entrada. |
| B2 | `feat(combate): hitstop v2 local…` | `combate_hitstop_v2` (opt-in por nível): congela só a animação da Koliani e o alvo, 35/60/80 ms; câmara e fundo continuam. Ligado em N1–N5 e N11. |
| A4 + D6 | `feat(n11): Entrada dos Ecos refeita…` | N11 de raiz (`tools/construir_n11_entrada.py`, ~6 700 px) + `ArenaSelada` (componente novo) + bot que tem as habilidades da campanha e toca sinos. Ver `docs/nivel_autoral_n11.md`. |

## Medido

- Suite completa: ver o fim deste ficheiro (corrida final).
- Travessia física N11: experiente 102 s / 7 mortes; normal 150 s / 12;
  casual 342 s / 29 — os três à porta. Crivo de alcance 100 níveis: 0
  inalcançáveis.

## Armadilhas (o que custou a descobrir)

1. **O teste do Coração (N5) só passava por acaso.** `_coracao_luta` corre a
   6× (`Engine.time_scale = 6`) e media em frames/60. O hitstop v1, ao
   primeiro golpe levado, repunha o `time_scale` a **1,0** — a luta seguia a
   1× e as contas batiam. Com o v2 o tempo global não mexe e tudo saía 6×
   mais curto (pulso 0,15 s em vez de 0,9 s). Agora mede em segundos de jogo.
   Moral: qualquer teste que corra a `time_scale` ≠ 1 e conte frames está a
   medir o hitstop, não o jogo.
2. **`AguaVenenosa` posiciona-se pelo centro** (topo = y − altura/2): uma
   rede a 1 000 por cima de um vazio a 1 120 com altura 340 MATA.
3. **O bot oficial não sabia tocar sinos** — atravessava pontes de eco por
   acertar no sino a meio de lutas. E um golpe perdido desliga a ponte.
4. **Outra sessão a trabalhar o mesmo plano**: o A0/A1 chegou ao origin a
   meio desta execução. Fazer `git fetch` antes de cada tarefa do plano.
5. `tools/correr_testes.ps1` precisa de `-ExecutionPolicy Bypass` nesta
   máquina; a suite completa leva ~20 min. `SO_TESTE=<nome>` corre só um.
6. `tools/correr_travessia.sh` chama `python3`, que no Windows não existe —
   usar um shim `python3 -> python` no PATH (não se mudou o script: o CI é
   Linux).

## Por fazer (ordem do plano)

B1 encontros (N1, N2, N16, N17 primeiro; `ArenaSelada` já existe) → B4
guardiões 2+boss (DEC-012: N1, N3, N6, N8, N13, N16, N18 perdem o guardião;
o Ghorak a ~500 HP) → B5 curva (N7) → B8 SFX da Região IV → B6 toque → B7
narrativa → B3 comportamentos → C* → D*.

HUMAN PLAYTEST REQUIRED: N11 inteiro; hitstop v2 em N1–N5 (sente-se peso?
parece engasgo?); nomes novos no seletor.
