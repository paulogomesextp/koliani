# Trabalho parqueado (retomar quando o Paulo disser)

## `PERFIL_niveis.patch` — redesenho de forma dos 30 níveis

Estado: **feito e a passar nos testes** (`tests/run_tests.gd` verde), mas
**por verificar visualmente** e o Paulo pediu para não mexer nos níveis
enquanto playtesta. Ficou parqueado, não commitado no `gerador_corredor.gd`.

O que o patch faz (só `scripts/gerador_corredor.gd`, sem quebrar
invariantes anti-softlock — `SUBIDA_MAX`, continuidade da espinha,
checkpoints):

- `const PERFIL` — 30 entradas, uma "cara" por nível: verticalidade
  (`v` -1/0/+1, substitui o ciclo rígido `_idx % 3`), foco de câmaras
  (`f`: salto / combate / maquina / vertical / gauntlet / misto) e
  abertura da banda vertical (`a` 0.8 apertado … 1.22 amplo).
- `const FOCO_CAMARAS` + `_camara_do_foco()` — o foco enviesa a seleção
  de câmaras (~50% no acto do meio) sem furar região/tier.
- `_construir` lê o `PERFIL`; `_teto_y` passa a multiplicar por `_abertura`;
  os níveis de foco "vertical" dobram a cadência de torre/poço/pilares.

Retomar:
```
git apply docs/parqueado/PERFIL_niveis.patch
```
depois **verificar com screenshots** (`tools/shot_dev_nivel.gd` em
`--window --screen 1`, um por região) e afinar os pesos antes de commit.

NB: `tools/verifica_jornada.gd` está a dar 29 FALHAS **desde antes** deste
patch — o limiar de nº de checkpoints não acompanhou a redução de ~80%
da v0.9.16. É um bug do próprio tool (não da jornada), a corrigir à parte.
