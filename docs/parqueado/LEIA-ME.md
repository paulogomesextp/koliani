# Trabalho parqueado (retomar quando o Paulo disser)

## `PERFIL_niveis.patch` — redesenho de forma dos 30 níveis  ✅ APLICADO (2 set 2026)

**Já não está parqueado.** Aplicado no commit `niveis: perfil de forma por
nivel (30 caras)` — mas com a tabela `PERFIL` **re-derivada de raiz** contra
a ordem real de `EstadoJogo.NIVEIS` e a gimmick de cada nível em
`docs/niveis.md`. Os comentários da 1.ª versão do patch estavam deslizados
(idx 1/2 trocados, 10-14 a deslizar, 17/18 trocados, 20/24 errados) e os
triplos `{v,f,a}` podiam ter sido pensados para o nível errado.

O `.patch` fica aqui só como registo histórico. O que entrou no
`scripts/gerador_corredor.gd`:

- `const PERFIL` — 30 entradas `{v (verticalidade -1/0/+1), f (foco de
  câmaras), a (abertura da banda vertical 0.8..1.22)}`, uma "cara" por
  nível, alinhadas à ordem real dos níveis.
- `const FOCO_CAMARAS` + `_camara_do_foco()` — o foco enviesa ~50% das
  câmaras do acto do meio sem furar região/tier.
- `_construir` lê o `PERFIL`; `_teto_y *= _abertura`; foco "vertical" dobra
  a cadência de torre/poço/pilares.

`tools/verifica_jornada.gd` — o limiar de nº de checkpoints (que dava 29
falhas falsas desde a v0.9.16) também foi corrigido no mesmo commit.

A seguir (fora deste ficheiro): afinar os pesos `{v,f,a}` com o Paulo ao
comando, e continuar o passe nível-a-nível (mecânica-assinatura + arte).
