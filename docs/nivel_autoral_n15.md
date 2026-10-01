# N15 autoral — "O Topo dos Ecos" (Região III, Torre dos Ecos)

**Data:** 30 set 2026 · **Branch:** `claude/project-thread-6jbrqw` · **Cena:**
`scenes/levels/O_Pico_Esquecido.tscn` (nome legado — mudá-lo partia saves) ·
**Gerada por:** `tools/construir_n15_topo.py` (editar lá, não no `.tscn`).

Contrato: `docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md`
(N15 — LOCKED), "A Verdade": combinação de sinos, plataformas dinâmicas, ecos
de memória (plataformas ilusórias), vento intenso, destrutíveis; únicos:
plataforma final (várias fases), sinos celestiais, fragmentos de eco (ativam a
arena), estruturas em colapso; hazards: feixes de luz, plataformas instáveis,
queda com vento, destroços; fluxo A–D; todos os inimigos da região + Vyrak;
4 segredos.

## O que havia antes
Uma sala pequena (Cume com um `Coletavel` de projétil, já concedido no N10).
Saiu tudo; o Vyrak (já feito) fica.

## O que ficou — a última ascensão (3700 × ~2300 px, ao ar livre)

| Secção | Onde | O que se faz |
|---|---|---|
| **A** ascensão | terraço da base (y 1000) | 2 sinos em queda, Acólito, Sentinela; o **fosso** de 500 px com 3 pedras em colapso e vento contra; o **Sino 1** acende 4 degraus temporizados (7 s, 100 px cada) até à laje alta (y 500) |
| **B** ecos de memória | para oeste | 6 plataformas que pulsam (2,2 s sólidas/1,4 s fantasma, desfasadas) sob 3 **feixes de luz** e vento contra; Arqueiro + Gárgula na laje alta; Segredo 1 por cima; laje B2 (Autómato, Espírito) |
| **C** caminho | sobe para oeste | 4 pedras em **colapso** até à laje C1 (Construto, Sentinela, Segredo 2); **coluna de ar** ao **Altar dos Sinos** (800 px, y −700) |
| **Fragmentos** | à volta do altar | F1 elevador de vaivem → plataforma N; F2 dois balanços contra o vento → plataforma E (Segredo 3 por cima); F3 dois ecos de memória + feixe → plataforma NE |
| **Sino celestial** | altar | surdo até os 3 fragmentos estarem recolhidos; depois uma badalada (só uma) ergue a **escada de ecos** (4 degraus de 96 px) até ao chão da arena |
| **D** arena | y −1180, 1390 px | Vyrak; 2 plataformas da fase 1; 3 **plataformas finais** que só se erguem no ritual (50 %); Segredo 4 num patamar alto; porta ao fundo |

7 checkpoints, 4 segredos; inimigos: Sentinela, Acólito, Sino Flutuante,
Arqueiro, Gárgula Vitral, Autómato, Monge das Correntes, Corvo do Sino,
Espírito do Eco, Construto Vitral.

**Mobilidade que o desenho respeita** (salto duplo ~246 px, `escalar_paredes`
sem limite): ao ar livre não há paredes; a escada de ecos soma 480 px (alvo
inalcançável sem ela); todos os satélites, segredos e ecos do F3 ficam ≥ 290 px
abaixo da face de baixo do chão da arena e o parapeito do lado da porta não
desce abaixo dela (testado).

## Mecânicas novas (todas opt-in; nenhum outro nível muda)
- `FragmentoEco` (`scripts/fragmento_eco.gd`): pickup por contacto, grupo
  `fragmentos_eco`.
- `SinoTorre.fragmentos_necessarios`: sino surdo até não faltar fragmento; acorda
  uma só vez.
- `PlataformaFase2` (`scripts/plataforma_fase2.gd`): fantasma até o ritual do
  Vyrak chamar `ativar_fase2()` (`chefe_vyrak._ritual_de_ativacao`).
- `PlataformaRitmada.textura_eco`, `RaioTempestade.textura_feixe`.

## Arte (sem PNGs editados à mão)
`tools/gerar_props_n15_prancha.py` recorta a **coluna N15 do
`level_mechanics.png`** (prefixo `f_`). Céu noturno sobre o fundo `torre_ecos`
com véus escuros para as plataformas lerem, correntes a subir para a bruma,
plataforma final pendurada sob o altar e sob a arena, lua cheia com halo e
arcos por trás do Vyrak. Capturas: `docs/qa/n15_autoral/`.

## Testes
`tests/test_region03_n15_level.gd` (estrutura, inimigos, mecânicas, portões
medidos com o salto real), `teste_r3_n15_fragmentos_e_escada`,
`teste_r3_n15_ritual_ergue_a_fase2`, `teste_r3_n15_portoes_no_crivo`.

## Decisões
- Os fragmentos **não persistem** (morrer volta ao checkpoint do altar): ficam
  todos a menos de um ecrã do sino.
- O crivo não vê os fragmentos como portão: o portão real é o sino surdo
  (testado em física).
- F3 sem coluna de ar: o impulso dela levava a tocar a face do chão da arena.

## Por decidir / playtest humano
Ritmo dos ecos (2,2/1,4 s), leitura dos feixes, dificuldade dos balanços com
vento, TTK do Vyrak com as plataformas da fase 2.
