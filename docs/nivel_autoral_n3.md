# N3 -- Ninho da Viuva Negra (nivel AUTORAL, COMBINE: o Pogo)

Estado: **PRONTO PARA PLAYTEST DO GM -- NAO LOCKED** (26 set 2026, sem push). Cena: `scenes/levels/Ninho_da_Viuva_Negra.tscn`
(gerada uma vez por script; agora edita-se a cena). Mesmo padrao do N1/N2: `corredor = false`, `checkpoints_autorais = true`,
`estreia_x_autoral = 1400` (placa "Pogo" quando o altar entra em ecra), `mecanica_anunciada = "pogo"`
(chaves novas `mec.pogo.nome/txt` e `hud.ability.pogo` nos 6 idiomas). Guardiao (Rainha Aracnidea) e Porta inalterados.
Nome "Ninho da Viuva Negra" e' o legacy da campanha (nao inventei nome novo).

## O Pogo (REVISTO, 26 set 2026): ataque descendente INTENCIONAL
Input: no ar, **BAIXO + ATAQUE** (`mirar_baixo` + `atacar`; no telemovel = joystick para baixo + botao de ataque, sem botao novo).
Removido o ressalto automatico (por toque em inimigo/espinhos). Maquina em `koliani.gd` (`_tratar_pogo`):
| fase | duracao | notas |
|---|---|---|
| startup | 0,07 s (~4 frames) | trava a queda a <= 260 px/s (legivel/justo a velocidade terminal); lamina translucida |
| activa | 0,20 s | mergulho a 420 px/s; **invulneravel** (o alvo e' atingido antes do contacto ferir); caixa 40x34 nos pes (espinhos) / banda de inimigo |
| recuperacao SEM acerto | 0,30 s | sem ressalto, sem espada, sem novo pogo (spam tem custo); cai em `_pogo_cd` 0,12 s ao aterrar |
| recuperacao COM acerto | 0,08 s | permite encadear |
Alvos validos: inimigos nao-chefe (dano `_dano_golpe`, critico se vulneravel, ressalto) e grupo `pogavel` (espinhos/serra: so' ressalto).
Chefes continuam a nao ser pisaveis (decisao de 3 set). Aterrar/agarrar/dano cancelam. Sem a habilidade `pogo` o input e' o ataque normal.
**Ressalto ANTES -> DEPOIS**: `FORCA_SALTO*0.7` = 409 px/s, **~60 px** (medido 56 na F1) -> `FORCA_SALTO*0.88` = 514 px/s,
**90 px medidos** (contacto->apice, teste) vs salto normal ~122 px (74 %): ha' opcoes de traversal mas nao e' um 2.o salto gratis
(exige alvo + input). Fisica geral F1 intocada (`aplicar_impulso` igual). Arte: **PLACEHOLDER** (triangulo `PogoLamina` + pose `attack`);
falta a pose/VFX propria do ataque descendente.

## Mapa (x do mundo; topo do chao = y 665; 7 400 px)
| # | Seccao | x | Papel (INTRODUCE->SAFE TEST->REPEAT->COMBINE->CHALLENGE->EXIT) |
|---|---|---|---|
| 1 | Abertura | 0-900 | movimento; gate de Dash (vao 130 sob teto, poco de retry) -- Dash ja' ensinado no N2 |
| 2 | Altar do Pogo | 1030-1720 | `Coletavel` `pogo` NO caminho (impossivel falhar); fogueira `CheckAltar` (1720) so' depois |
| 3 | Teste seguro | 1960 / 2190 | 2 tufos isolados de 64 px, **dano 3** (quase seguro), no chao: SALTAR -> BAIXO+ATAQUE -> ACERTAR -> RESSALTAR |
| 4 | Sequencia | 2470 / 2630 / 2790 | 3 tufos de 48 px com 112 px de chao seguro entre eles: encadear 3 alvos, sem exigir nada |
| 5 | Pogo + Dash | 2934-3206 + 3400 | CAMA de 272 px (dano 10) -> ilha de 194 px -> gate de Dash (poco de retry); `CheckMeio` 3620 |
| 6 | Pogo + hazard | 3700-4210 | cama 192 px, ilha com `RaizPerigo` (telegrafada, 2,6 s), cama 192 px |
| 7 | Pogo + combate | 4460-4960 | 3 goblins (patrulha curta) + 1 tufo: pisao com ressalto que encadeia; opcional (espada tambem serve) |
| 8 | Desafio final | 5560-6430 | cama 272 -> ilha com raiz -> cama 192 -> gate de Dash; `CheckFinal` 5250 (310 px antes) |
| 9 | Fecho | 6430-7350 | respiro, cache 25, segredo alto (salto+mantle, cache 40), Guardiao, Porta |
4 checkpoints autorais (300, 1720, 3620, 5250). Nenhuma cadeia de pogo sem checkpoint a menos de ~1 000 px.

## Medido (`teste_n3_autoral` e `teste_pogo_intencional`)
Pogo: sem input nos espinhos = dano, sem ressalto; com input = 0 dano, ressalto 90 px; no vazio = sem ressalto; goblin = dano + ressalto.
Piloto na CamaPogo1 (agora com BAIXO+ATAQUE):
Sem pogo, em 5 takeoffs: atravessa sempre **com dano** (10-20). Com pogo: limpo em 5 de 7 takeoffs (30 a 150 px antes da
cama); os 2 tardios (0/12 px) levam 10. Cair nas camas custa 10 (nunca morte; empurra para tras) -- por isso o pogo e'
"exigido" para atravessar SEM dano, nao um bloqueio duro (decisao: nada de morte por falhar o pogo).

## Regras cumpridas
Sem Especial/Energia, wall-jump, salto duplo, dash aereo; sem Serra/Fogo/Pendulo/Portal/Trampolim/Ritmadas/Teia (teste).
So' goblins (especie ja' aprovada). Nenhum alvo de pogo antes do altar (teste). Tres gates de dash = todos pos-N2.

## Falta / por validar por humano
Legibilidade dos espinhos (picos finos e pequenos no kit: `docs/qa/n3_autoral/`); a placa "Pogo" e' texto -- nao ha
animacao/VFX propria do ressalto de espinhos; goblins a arte legacy; raiz por poligonos (como N1/N2); dependencia global do
calendario (`pogo` so' se ganha aqui; fallback do portal para skills NAO implementado, registado). Duracao **estimada**
3-4 min (7 400 px a 240 px/s = ~31 s de corrida pura + aprendizagem/combate/gates; nao medida com humano).
Sem save no N3 sem `dash`: entrar por seletor sem o N2 deixa o gate 1 sem saida util (o poco tem degraus, sem softlock).
