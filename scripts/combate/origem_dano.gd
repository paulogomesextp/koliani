class_name OrigemDano
extends RefCounted
## Contrato de origem de dano (Fase 5 da integração do Combat Lab v1.2 em
## produção -- ver `docs/plano_integracao_combate_producao.md` §3).
##
## `Koliani.receber_dano(quantidade, dir_empurrao, origem)` usa este valor
## para decidir se o dano pode disparar o Perfect Dodge
## (`CombateLab.tentativa_de_dano`, hoje só activo no Combat Lab -- em
## produção o componente nunca existe, por isso este valor ainda não muda
## nenhum comportamento jogável, só documenta a origem).
##
## Regra fixa (Game Director, execução "Controlled Combat Integration"):
## só ATAQUE e HAZARD_ATAQUE podem disparar Perfect Dodge. CONTATO,
## AMBIENTE e "" (omisso) nunca podem.

## Toque de corpo de um inimigo (colisão direta, sem golpe telegrafado).
const CONTATO := "contato"
## Golpe de um inimigo ou projétil ofensivo (bote, investida, disparo).
const ATAQUE := "ataque"
## Armadilha/perigo do cenário com dano telegrafado (lâmina, queda, etc.).
const HAZARD_ATAQUE := "hazard_ataque"
## Dano-ao-longo-do-tempo ambiental (sem-ar, ácido contínuo, etc.) --
## nunca esquivável por desenho.
const AMBIENTE := "ambiente"
