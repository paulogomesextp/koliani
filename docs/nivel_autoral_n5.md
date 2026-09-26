# N5 -- Coracao da Floresta (EXAME REGIONAL + BOSS: o Coracao Putrefacto)

Estado: **PRONTO PARA PLAYTEST DO GM -- NAO LOCKED** (26 set 2026, sem push). Cena `scenes/levels/Coracao_da_Floresta.tscn`
(gerada uma vez por script; agora edita-se a cena), boss `scripts/chefe_coracao_putrefacto.gd` (reescrito), alvo de pogo
`scripts/broto_coracao.gd` (novo). Padrao N1-N4: `corredor = false`, `checkpoints_autorais`. Nenhuma skill nova, e o exame nao tem
coletaveis (o teste antigo "L5 desbloqueia Dash" foi trocado: o Dash vem do N2).

## Parte A -- exame (0-3460 px, ~2 min)
| # | Prova | x | Detalhe |
|---|---|---|---|
| A1 | Dash + plataformas | 800-930 | gate sob teto, poco de retry (igual N2-N4) |
| A2 | Pogo + travessia | 1064-1336 | cama de espinhos 272 px (so' se cruza limpa com pogo) |
| A3 | Hazard + movimento | 1336-1500 | ilha com `RaizPerigo` (2,6 s, telegrafada); `CheckPogo` 1560 |
| A4 | Combate + reposicionamento | 1720 | elite goblin de CARGA (140): dash/salto para lhe passar atras |
| A5 | Decisao de Energia | 2450-2700 | goblin + elite gosma saltadora (150): Especial (2 usos) ou espada; `CheckMeio` 2150 |
| A6 | Combinacao final | 2924-3460 | cama 272 -> ilha com raiz -> gate de Dash; `CheckFinal` 3550 |
So' goblin e gosma (4 inimigos). 4 checkpoints; **o checkpoint antes da arena esta' a 3550, dentro dela** -- morrer no boss volta aqui
(nao repete o exame).

## Parte B -- arena (3460-4560, ~1 100 px, chao continuo, 0 plataformas secundarias)
Coracao no centro (4010); Porta a' direita (4490); cache de Essencia 60. Arte de producao do Coracao (fase 1 contida, fase 2 intensificada,
erupcao na transicao) mantida.

### Ciclo: PROTEGIDO -> MECANICA -> EXPOSTO (punish) -> RECOVER
- **PROTEGIDO**: pele baca; a casca deixa passar 5 % do dano (bater sem parar nao ganha a luta). O boss so' arranca ataques com a Koliani
  e o boss em campo visual (`Som.em_vista`).
- **MECANICAS** (todas com aviso antes de haver dano):
  - **RAIZES**: 3 raizes em volta da Koliani, racha no chao 1,5 s antes de irromperem (nunca < 0,9 s). Resposta: movimento/salto. Fase 2: +2 raizes tarde.
  - **PULSO** (janela do Dash): o coracao brilha 0,95 s (0,82 s na fase 2) e duas tiras magenta piscam no chao; depois duas ondas rasteiras
    (44x40, 400 px/s) percorrem a arena. **Salta-se por cima OU atravessa-se de Dash** (invulneravel) -- medido: parado leva 18, saltar 0, dash 0.
  - **BROTOS** (alvo de Pogo): dois brotos nos flancos crescem 0,7 s; **ressaltar num (BAIXO+ATAQUE) rebenta-o, abre o nucleo de imediato e
    alonga a janela 50 %** (2,6 -> 3,9 s medido) e da' +8 Energia. Ignora-los nao castiga: o nucleo abre na mesma ao fim de 1,7 s. Nao ha' pogo
    directo no boss (os chefes continuam sem bounce, regra do GM).
- **EXPOSTO**: nucleo aberto (brilho + pulso, tom quente), o coracao NAO magoa por contacto; a espada entra por inteiro e o **Especial** rende.
  Ultimos 0,4 s: o nucleo pisca (RECOVER). Janela base 2,6 s (fase 2: 2,08 s).
- **Energia**: o Especial custa 33 (3 cargas); o nucleo absorve 40 % da onda (`RESIST_TIRO` 0,6, so' neste boss): gastar com o coracao PROTEGIDO
  desperdica-o (a casca leva 5 %). Sem Especial ganha-se na mesma.
- **FASE 1** (100 -> 50 %): RAIZES, PULSO, BROTOS, PULSO. **FASE 2** (< 50 %, entra so' com o ciclo resolvido; ROAR 0,9 s): encadeia
  RAIZES+PULSO, BROTOS, PULSO+PULSO, RAIZES+BROTOS; avisos ~15 % mais curtos, janela ~20 % mais curta, dano ~15 % maior.
  Mesmo vocabulario, sem tiros nem gravidade alterada (tirei o leque radial, a salva dirigida e a queda de entulho do boss antigo).

## Numeros (medidos em `teste_n5_autoral`, bots a 2 golpes de 50/s; Koliani invulneravel)
Vida da cena 580 -> efectiva **1 706** (x3,42 do `ChefeBase` x0,86 do alivio da Regiao I). TTK do bot perfeito (so' nas janelas) **35,5 s**,
fase 2 aos 16,6 s; com Especial (energia realista: 99 + 12/s + 5 por golpe) 19,7 s; spam 31,5 s; **so' a bater na casca nao ganha (120 s)**.
Estimativa humana: 35,5 x 1,6-2,0 = **57-71 s** depois de perceber o padrao (alvo 45-75). Janelas 1,6-2,6 s. Pior tempo no mesmo estado 2,6 s.
Nao e' sponge: ~34 golpes de espada em janelas abertas.

## Retry
`CheckFinal` (3550) e' a fogueira da arena; o boss reinicia a vida ao recarregar a cena, o exame nao se repete.

## Falta / por validar
**APPROVED ART ASSET MISSING** (placeholders por poligonos): broto (`broto_coracao.gd`), onda do pulso, tira de aviso do pulso. Sem VFX de impacto proprios
da onda. Numeros (janela, dano, vida) a olho e por medir com humano; nao ha' pose animada de "abertura do nucleo" alem do brilho. A recompensa
de fim de regiao continua a ser a de sempre: bau do chefe + **`HABILIDADE_DO_CHEFE[4] = salto_duplo`** (contrato 9H.17 C do GM, inalterado --
concede-se DEPOIS da luta, nada no N5 a exige). Se o GM nao quiser dar uma skill ao vencer o exame, e' esta entrada.
Fim da regiao: nao ha' ecra/cena de encerramento da Floresta Corrompida alem do bau e da porta -- dependencia visual por definir.
`tools/verifica_raiz_elevatoria.gd` / `verifica_camara_seiva.gd` (N4 antigo) continuam sem alvo.
