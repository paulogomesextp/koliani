# N6 -- As Falesias Abertas (nivel AUTORAL, Regiao II: o VENTO como mecanica regional)

Estado: **PRONTO PARA PLAYTEST DO GM -- NAO LOCKED** (26 set 2026, sem push). Cena `scenes/levels/Prisao_dos_Condenados.tscn`
(nome de ficheiro legacy mantido: mudar partia saves/testes; o jogador le "The Open Cliffs"). Gerada uma vez por script; agora edita-se a cena.
Padrao N1-N5: `corredor = false`, `checkpoints_autorais`, `estreia_x_autoral = 260`, `mecanica_anunciada = "rajada"` (chaves `mec.rajada.*` nos 6 i18n).
Aprovado pelo GM: Golem das Falesias como GUARDIAO, `dash_aereo` fora, sem skills novas. N7-N10 intactos.

## Decisoes aplicadas
- **Guardiao**: o no `Guardiao` e' o actor `ChefeCarcereiro.tscn` -- que JA' era o Golem das Falesias (rig `golem_falesias`, `guard.golem_falesias`;
  a identidade do Carcereiro tinha saido; so' o nome do ficheiro/classe ficou, por causa de uids). Foi promovido de `Chefe` a `Guardiao`
  (como o Ghorak no N1): sela a porta, **nao grava boss derrotado**, nao da' bau nem habilidade. Vida: novo `@export vida_minima` em
  `chefe_carcereiro.gd` (540 -> 175 nesta cena; efectiva ~609 apos a escala do `ChefeBase`, ~35 % do que o boss antigo valia). Dividida a divida: renomear
  `ChefeCarcereiro` -> `ChefeGolemFalesias` fica para uma limpeza propria (mexe em cenas/uids/testes).
- **`dash_aereo` removido** do N6 (o `Coletavel` saiu). O sistema `dash_aereo` continua no codigo (`HABILIDADES_TODAS`, koliani.gd); **marcado para decisao
  futura** (onde, se algum sitio, se ganha).
- Fogos de prisao (`FogoMeio`/`FogoChefe`) removidos; as 3 `PlataformaCorrente` reduzidas a UMA, fora de qualquer zona de vento.

## ACHADO IMPORTANTE -- o vento so' se sente com intensidade > 1300
Em `movimento.gd` a desaceleracao no ar (`DESACEL_AR`) e' 1300 px/s^2 e o vento soma velocidade ANTES de o controlo da Koliani a comer.
Medido com a Koliani parada no ar: **intensidade 420 -> vx 7 px/s (dx 4 px em 0,6 s); 1400 -> 20 px/s; 1600 -> ~160 px/s aos 0,4 s (dx 43); 1900 -> dx 52**.
As rajadas herdadas do N6/N9/... (420/520) eram assim **imperceptiveis**. O N6 usa agora 1500-1800 (`vmax` 120-170): no chao continua a nao
mexer (atrito 2200), no ar desloca 40-60 px por salto. **Aviso para N7-N10**: as zonas de vento actuais dessas cenas tem o mesmo problema
(N7 updrafts usam outro sistema, `soprar_para_cima`; N8/N9 usam `WindZone` horizontal a 4xx) -- rever quando cada um for reconstruido.

## Mapa (x do mundo; chao y 700 (topo 670); 6 100 px; vazio = mar de nuvens, cair = morte)
| Sec. | x | Papel | Conteudo | Checkpoint |
|---|---|---|---|---|
| A Teach | 0-1000 | ler o vento sem risco | chao firme; 2 zonas CONTINUAS fracas (a favor 300-700, contra 700-1000, 1500/120); 2 degraus de ensaio (saltar e VER a deriva); nada mata | `CheckInicio` 300 |
| B Develop | 1000-2350 | vento + salto | 4 pontes estreitas (150 px, vaos 120) sobre o vazio; rajada a favor PULSADA (1,6 s on/1,2 s off, 1700/170); descanso 300 px | `CheckAntesPonte` 960, `CheckPonte` 2130 |
| C Combine | 2350-3590 | vento + combate | bifurcacao: ALTA (4 plataformas, vento contra pulsado 1800/150, `CacheAlta` 24 Essencia) / BAIXA (abrigada, laje 420 px com elite golem de carga, 165); morcego a voar no meio | `CheckReencontro` 3420 |
| D Challenge | 3590-4900 | prova final | ponte longa: 2 plataformas em vento a favor, UMA plataforma movel fora do vento, 2 plataformas em vento contra; morcego sobre a ponte | (o anterior) |
| E Guardiao | 4900-5900 | fecho | chao continuo 1000 px, `CacheFecho` 32, Golem (vida efectiva ~609), vento fraco pulsado, Porta 5860 | `CheckFinal` 5000 (dentro da arena) |
5 checkpoints; o troco mais longo (2130->3420) tem a bifurcacao. Inimigos: 1 elite + 2 morcegos + o Guardiao. So' kit real: salto simples chega a tudo; o salto duplo/dash
ajudam contra o vento (nao exigidos).

## Medido (`teste_n6_autoral`, suite completa PASS, save real intacto)
Estrutura (sem jornada, Guardiao≠Chefe, 5 checkpoints, 7 zonas, so' 2 continuas, ambas as direcoes, 1 plataforma movel, 0 `Coletavel`, sem scripts alheios),
vaos <= 140 e subidas <= 104 em todas as cadeias, plataforma movel fora do vento, Guardiao 400-900 de vida, porta selada ate' ele cair, sem boss gravado,
sem `escalar_paredes`/`dash_aereo`, e **o vento desloca mesmo a Koliani no ar nos dois sentidos**.
`tools/bot_gauntlet.gd ... 5`: chega a` porta (5 823 px em ~60 s); pausa de 22 s perto de x 4755 (ultimo degrau, vento contra) -- o bot nao le lulas; um humano espera o intervalo
(sem o vento D2 a pausa e' 9 s, portanto e' sobretudo do bot). Capturas: `docs/qa/n6_autoral/`. Duracao **estimada** 3-4 min (nao medida com humano).

## Falta / por validar (playtest do GM)
Se 1500-1800 se le bem (a favor: encurta/estende o salto; contra: pede o intervalo); se o vento contra do percurso alto e' justo; TTK do Golem (~609 de vida; nao medido com
bot); arte: props de fundo herdados (gargula, pilares) e guia do vento sao placeholder; `baseline_geometria` do N6 por refazer (a geometria mudou de proposito).
Renomear `ChefeCarcereiro`. Decisao futura do `dash_aereo`.
