# Plano de migracao da Regiao II para o quality bar da Regiao I

Estado: **PLANO -- nada construido** (26 set 2026). Nao comecar a producao dos 5 niveis antes de o GM aprovar este plano.
Referencia: `docs/regiao_1_vertical_slice.md`.

## Ponto de partida (o que ha' no repo)
| Nivel | Cena | Chefe | Estado actual |
|---|---|---|---|
| N6 | `Prisao_dos_Condenados` | Carcereiro | jornada procedural (sem `corredor=false`), pre-quality-bar |
| N7 | `Fornalha_dos_Pecadores` | Ignivar | idem |
| N8 | `Corredor_das_Execucoes` | Dama Guilhotina | `corredor=false` ja', nao autoral |
| N9 | `Ala_dos_Mortos` | Irmaos Condenados | jornada procedural |
| N10 | `A_Cela_Zero` | Guardiao dos Ceus | `corredor=false`, exame; (verificar nos worktrees/branches de Process 11/12 se ha' trabalho mais avancado antes de reescrever) |
Kit do jogador ao entrar: Dash (N2), Pogo (N3), Especial (N4), **Salto duplo (ganho no N5)**; a Regiao II e' a primeira que pode exigi-lo.

## Migracao (ordem)
0. **Auditoria previa** (meio dia): reconciliar com os branches Process 11/12 (N8 planar, N10) para nao refazer; listar por nivel o que
   ja' e' authored. Congelar a mecanica-assinatura de cada nivel (`docs/mecanicas_catalogo.md`).
1. **Desenho no papel** (`docs/nivel_autoral_n6..n10.md`, so' texto): para cada nivel -- mecanica ensinada, Teach/Develop/Combine/Challenge,
   checkpoints, lista curta de inimigos com funcao, hazard regional (prisao/fogo/execucao). N6 ensina a novidade da regiao usando o
   **salto duplo** (primeira regiao onde se pode exigir); N10 e' exame que combina tudo sem skill nova.
2. **Nivel a nivel, um de cada vez, com aprovacao do GM entre eles** (o que fez a Regiao I funcionar): N6 -> N7 -> N8 -> N9 -> N10.
   Cada um: `corredor=false` + `checkpoints_autorais`, teste `teste_nN_autoral` (alcance/piloto), capturas em `docs/qa/`.
3. **Bosses** (Carcereiro, Ignivar, Dama, Irmaos, Guardiao): reescrever para PROTEGIDO/MECANICA/EXPOSTO/RECOVER com avisos >= 0,9 s,
   janelas 1,6-2,6 s, fase 2 encadeada; medir TTK com bot perfeito (alvo 30-40 s) e "so' casca nao ganha". So' o exame (N10) tem cartao de
   fim de regiao (`REGIAO_CONCLUIDA[9] = "region.2.complete"` + 6 i18n) e recompensa de habilidade se o GM a decidir.
4. **Ferramentas**: reutilizar o padrao `nivel_com_chefe.gd` (`checkpoints_autorais`); NAO tocar em `gerador_corredor.gd` para estes niveis.
5. **Divida visual** fica registada por nivel; nao bloqueia aprovacao mecanica.

## Riscos
- N6-N9 tem jornada procedural e assinaturas de mecanica atribuidas por tabela: desenhar a mao pode partir testes de alcance/mecanica
  (`verifica_alcance`, testes 9H) -- actualiza-los por nivel.
- Saltos que dependem do salto duplo tem de ser verificados com e sem (saves que nao venceram o N5 usam modo dev/seletor).
- Special DPS (ver revisao global) muda o TTK dos bosses novos -- medir com e sem Especial.

## Decisoes pedidas ao GM
1. Ordem N6->N10 ou comecar pelo exame N10 (ja' authored)? 2. A Regiao II dá skill nova no exame? 3. Aprovar o cartao `region.2.complete`.
