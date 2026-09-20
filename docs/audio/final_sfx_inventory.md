# Inventário final do áudio — SFX Overhaul, Prompt 4

Gerado por `tools/inventario_audio.py`. Não editar à mão.

Junta catálogo (`Som.CAMINHOS`) + ficheiros em `assets/audio/` + callsites no código do jogo. É na junção dos três que vivem os defeitos que não dão erro nenhum: uma chave sem ficheiro deixa o evento mudo em silêncio, e uma chave sem callsite é um som que ninguém toca.

`tools/` e `scripts/dev_sons.gd` não contam como uso — o painel de sons do dev toca o catálogo inteiro e mascararia todas as chaves mortas.

## Veredicto

| | |
|---|---|
| chaves no catálogo | 95 |
| **MISSING** (chave sem ficheiro) | **0** |
| UNUSED (chave sem callsite) | 0 |
| sobras de formato (`.ogg`/`.mp3` de chaves que hoje são `.wav`) | 13 |
| órfãos reais (ficheiro sem chave nenhuma) | 0 |
| duplicados byte-a-byte | 0 |

Nada é apagado por este script. Assets sem uso ficam classificados e a decisão é humana — vários são infra-estrutura adormecida de propósito.

## Catálogo

`LUFS` é integrado com gate EBU R128; sons abaixo de ~0,4 s não passam o gate e leem −70 — é a norma, não o ficheiro. Aparecem como `curto`.


### ?

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `acerto_v2` | acerto_v2.wav | wav | 0.14 | 44100 | 1 | -1.0 | curto | INTENTIONAL | 0 | — |
| `acerto_v3` | acerto_v3.wav | wav | 0.14 | 44100 | 1 | -1.0 | curto | INTENTIONAL | 0 | — |

### AMBIENCE

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `mecanismo_ciclo` | mecanismo_ciclo.wav | wav | 2.40 | 44100 | 1 | -12.5 | -28.2 | USED | 1 | scripts/tumulo_elevador.gd:18 |
| `vento_ciclo` | vento_ciclo.wav | wav | 6.00 | 44100 | 1 | -16.4 | -24.8 | USED | 1 | scripts/wind_zone.gd:30 |

### BOSS

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `chama` | chama.ogg | ogg | 1.07 | 48000 | 2 | -24.3 | -35.4 | USED | 3 | scripts/chefe_arauto_de_zeriko.gd:269 |
| `chefe_cai` | chefe_cai.wav | wav | 0.71 | 48000 | 2 | -0.1 | -12.2 | USED | 2 | scripts/chefe_base.gd:708 |
| `chefe_magia` | chefe_magia.ogg | ogg | 1.93 | 48000 | 2 | -14.6 | -31.1 | USED | 6 | scripts/chefe_base.gd:761 |
| `engrenagem` | engrenagem.ogg | ogg | 0.40 | 48000 | 2 | -0.0 | curto | USED | 3 | scripts/chefe_base.gd:760 |
| `esmagar` | esmagar.ogg | ogg | 1.18 | 44100 | 2 | 0.0 | -12.8 | USED | 16 | scripts/chefe_aerion.gd:299 |
| `feixe_vil` | feixe_vil.ogg | ogg | 1.59 | 48000 | 2 | -15.1 | -32.1 | USED | 4 | scripts/chefe_generico.gd:340 |
| `garra` | garra.ogg | ogg | 0.43 | 48000 | 2 | -3.0 | -19.7 | USED | 1 | scripts/chefe_rainha_aracnidea.gd:94 |
| `gelo` | gelo.wav | wav | 2.12 | 48000 | 2 | -0.1 | -13.9 | USED | 6 | scripts/chefe_aerion.gd:210 |
| `golpe_pesado` | golpe_pesado.ogg | ogg | 0.49 | 44100 | 2 | -0.8 | -16.9 | USED | 11 | scripts/chefe_acougueiro_real.gd:135 |
| `grito` | grito.ogg | ogg | 0.96 | 48000 | 2 | -0.8 | -10.4 | USED | 9 | scripts/chefe_aerion.gd:253 |
| `investida` | investida.wav | wav | 0.19 | 44100 | 2 | -0.1 | curto | USED | 18 | scripts/chefe_aerion.gd:144 |
| `invocar` | invocar.wav | wav | 0.88 | 44100 | 2 | -0.1 | -10.4 | USED | 18 | scripts/chefe_bispo_purpura.gd:234 |
| `lamina_cair` | lamina_cair.ogg | ogg | 0.31 | 48000 | 2 | -0.8 | curto | USED | 4 | scripts/chefe_dama_guilhotina.gd:185 |
| `meteoro` | meteoro.wav | wav | 5.14 | 44100 | 2 | -0.2 | -21.1 | USED | 1 | scripts/chefe_zeriko_final.gd:272 |
| `mudar_forma` | mudar_forma.wav | wav | 0.59 | 48000 | 2 | -0.1 | -12.7 | USED | 1 | scripts/chefe_base.gd:788 |
| `olho_carregar` | olho_carregar.wav | wav | 1.60 | 44100 | 2 | -4.2 | -15.0 | USED | 2 | scripts/chefe_olho_do_abismo.gd:161 |
| `onda` | onda.ogg | ogg | 1.18 | 48000 | 2 | -2.2 | -29.1 | USED | 9 | scripts/chefe_coracao_putrefacto.gd:217 |
| `praga` | praga.ogg | ogg | 0.69 | 48000 | 2 | -1.4 | -14.3 | USED | 11 | scripts/chefe_base.gd:759 |
| `raio` | raio.wav | wav | 5.61 | 44100 | 2 | 0.0 | -9.4 | USED | 6 | scripts/chefe_base.gd:765 |
| `sino_ataque` | sino_ataque.ogg | ogg | 0.56 | 48000 | 2 | -0.9 | -12.8 | USED | 5 | scripts/chefe_base.gd:764 |

### ENEMY

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `demonio_ataque` | demonio_ataque.ogg | ogg | 0.78 | 48000 | 2 | -0.5 | -14.9 | USED | 3 | scripts/chefe_guardiao_dos_ceus.gd:516 |
| `mob_besta_ataque` | mob_besta_ataque.ogg | ogg | 0.37 | 44100 | 1 | -1.7 | curto | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_besta_dano` | mob_besta_dano.ogg | ogg | 0.86 | 44100 | 1 | -1.9 | -17.5 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_besta_morte` | mob_besta_morte.ogg | ogg | 0.88 | 44100 | 1 | -1.6 | -16.6 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_gosma_ataque` | mob_gosma_ataque.ogg | ogg | 0.40 | 44100 | 1 | -1.8 | -21.9 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_gosma_dano` | mob_gosma_dano.ogg | ogg | 0.44 | 44100 | 1 | -2.0 | -19.4 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_gosma_morte` | mob_gosma_morte.ogg | ogg | 0.78 | 44100 | 1 | -2.1 | -21.1 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_grande_ataque` | mob_grande_ataque.ogg | ogg | 0.80 | 44100 | 1 | -1.6 | -12.2 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_grande_dano` | mob_grande_dano.ogg | ogg | 0.60 | 44100 | 1 | -2.0 | -15.0 | USED | 2 | scripts/chefe_base.gd:695 |
| `mob_grande_morte` | mob_grande_morte.ogg | ogg | 1.35 | 44100 | 1 | -2.0 | -20.4 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_humano_ataque` | mob_humano_ataque.ogg | ogg | 0.77 | 44100 | 1 | -1.8 | -10.4 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_humano_dano` | mob_humano_dano.ogg | ogg | 0.66 | 44100 | 1 | -1.8 | -13.6 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_humano_morte` | mob_humano_morte.ogg | ogg | 0.64 | 44100 | 1 | -1.8 | -15.9 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_insecto_ataque` | mob_insecto_ataque.ogg | ogg | 0.46 | 44100 | 1 | -2.0 | -21.1 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_insecto_dano` | mob_insecto_dano.ogg | ogg | 0.35 | 44100 | 1 | -1.9 | curto | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_insecto_morte` | mob_insecto_morte.ogg | ogg | 0.34 | 44100 | 1 | -1.8 | curto | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_morto_ataque` | mob_morto_ataque.ogg | ogg | 0.37 | 44100 | 1 | -1.9 | curto | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_morto_dano` | mob_morto_dano.ogg | ogg | 0.32 | 44100 | 1 | -1.6 | curto | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_morto_morte` | mob_morto_morte.ogg | ogg | 0.79 | 44100 | 1 | -2.1 | -19.6 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_voador_ataque` | mob_voador_ataque.ogg | ogg | 0.59 | 44100 | 1 | -1.7 | -22.6 | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_voador_dano` | mob_voador_dano.ogg | ogg | 0.27 | 44100 | 1 | -2.1 | curto | USED | 1 | scripts/demonio_base.gd:490~ |
| `mob_voador_morte` | mob_voador_morte.ogg | ogg | 0.46 | 44100 | 1 | -1.7 | -13.1 | USED | 1 | scripts/demonio_base.gd:490~ |

### HAZARD

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `fogo_sopro` | fogo_sopro.wav | wav | 0.62 | 44100 | 1 | -4.4 | -18.8 | USED | 1 | scripts/fogo.gd:75 |
| `lamina_passa` | lamina_passa.wav | wav | 0.34 | 44100 | 1 | -6.4 | curto | USED | 1 | scripts/pendulo_lamina.gd:156 |
| `pedra_parte` | pedra_parte.wav | wav | 0.80 | 44100 | 1 | -1.5 | -24.4 | USED | 2 | scripts/pedra_queda.gd:160 |
| `pedra_racha` | pedra_racha.wav | wav | 0.70 | 44100 | 1 | -11.2 | -26.3 | USED | 2 | scripts/pedra_queda.gd:125 |
| `raio_aviso` | raio_aviso.wav | wav | 0.62 | 44100 | 1 | -14.3 | -21.4 | USED | 1 | scripts/raio_tempestade.gd:65 |
| `raio_cai` | raio_cai.wav | wav | 1.40 | 44100 | 1 | -3.8 | -18.0 | USED | 2 | scripts/raio_tempestade.gd:80 |
| `raiz_aviso` | raiz_aviso.wav | wav | 0.55 | 44100 | 1 | -15.4 | -27.8 | USED | 1 | scripts/raiz_perigo.gd:116 |
| `raiz_irrompe` | raiz_irrompe.wav | wav | 0.62 | 44100 | 1 | -7.3 | -23.3 | USED | 2 | scripts/raiz_perigo.gd:68 |

### MECHANISM

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `mecanismo` | mecanismo.wav | wav | 0.46 | 44100 | 1 | -4.4 | -22.6 | USED | 6 | scripts/alavanca.gd:102 |
| `plataforma_surge` | plataforma_surge.wav | wav | 0.40 | 44100 | 1 | -11.9 | -27.1 | USED | 1 | scripts/plataforma_ritmada.gd:86 |
| `porta` | porta.wav | wav | 1.00 | 44100 | 2 | -0.1 | -13.4 | USED | 2 | scripts/editor_layout_toque.gd:192 |
| `portao_abre` | portao_abre.wav | wav | 0.95 | 44100 | 1 | -7.9 | -22.9 | USED | 1 | scripts/porta_trancada.gd:89 |
| `portao_fecha` | portao_fecha.wav | wav | 0.95 | 44100 | 1 | -6.3 | -23.2 | USED | 1 | scripts/porta_trancada.gd:89 |
| `sino_mecanismo` | sino_mecanismo.wav | wav | 2.30 | 44100 | 1 | -6.6 | -21.5 | USED | 1 | scripts/sino_torre.gd:60 |

### PLAYER

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `acerto` | acerto.wav | wav | 0.14 | 44100 | 1 | -1.0 | curto | USED | 5 | scripts/koliani.gd:1666 |
| `agarrar` | agarrar.ogg | ogg | 0.29 | 44100 | 1 | -1.9 | curto | USED | 2 | scripts/koliani.gd:1451 |
| `ataque` | ataque.wav | wav | 0.15 | 44100 | 1 | -1.3 | curto | USED | 4 | scripts/demonio_base.gd:177 |
| `ataque2` | ataque2.wav | wav | 0.19 | 44100 | 1 | -1.3 | curto | USED | 1 | scripts/koliani.gd:874 |
| `ataque3` | ataque3.wav | wav | 0.26 | 44100 | 1 | -1.3 | curto | USED | 1 | scripts/koliani.gd:874 |
| `ataque_forte` | ataque_forte.wav | wav | 0.40 | 44100 | 1 | -1.5 | -12.5 | USED | 1 | scripts/koliani.gd:874 |
| `aterrar` | aterrar.wav | wav | 0.20 | 44100 | 1 | -2.0 | curto | USED | 8 | scripts/koliani.gd:570 |
| `bloqueio` | bloqueio.wav | wav | 0.40 | 44100 | 1 | -1.1 | -14.8 | USED | 6 | scripts/chefe_olho_do_abismo.gd:289 |
| `dano` | dano.wav | wav | 0.46 | 44100 | 1 | -1.4 | -17.1 | USED | 49 | scripts/chefe_base.gd:233 |
| `dash` | dash.wav | wav | 0.21 | 44100 | 1 | -1.4 | curto | USED | 10 | scripts/controlos_tacteis.gd:43 |
| `lancar` | lancar.ogg | ogg | 0.45 | 44100 | 1 | -2.1 | -14.2 | USED | 4 | scripts/controlos_tacteis.gd:42 |
| `morte_koliani` | morte_koliani.wav | wav | 1.10 | 44100 | 1 | -3.7 | -14.3 | USED | 1 | scripts/koliani.gd:2759 |
| `parede` | parede.ogg | ogg | 0.60 | 44100 | 1 | -2.3 | -26.4 | USED | 2 | scripts/gerador_corredor.gd:1597 |
| `passo1` | passo1.wav | wav | 0.07 | 44100 | 1 | -1.8 | curto | USED | 1 | scripts/koliani.gd:2740~ |
| `passo2` | passo2.wav | wav | 0.07 | 44100 | 1 | -1.4 | curto | USED | 1 | scripts/koliani.gd:2740~ |
| `passo3` | passo3.wav | wav | 0.07 | 44100 | 1 | -1.2 | curto | USED | 1 | scripts/koliani.gd:2740~ |
| `projetil` | projetil.wav | wav | 0.15 | 44100 | 2 | -0.1 | curto | USED | 18 | scripts/chefe_acougueiro_real.gd:173 |
| `rolamento` | rolamento.wav | wav | 0.28 | 44100 | 1 | -1.1 | curto | USED | 1 | scripts/koliani.gd:1559 |
| `salto` | salto.wav | wav | 0.16 | 44100 | 1 | -1.4 | curto | USED | 27 | scripts/controlos_tacteis.gd:44 |
| `salto_duplo` | salto_duplo.wav | wav | 0.22 | 44100 | 1 | -1.4 | curto | USED | 8 | scripts/estado_jogo.gd:38 |

### PROGRESSION

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `apanhar` | apanhar.wav | wav | 0.40 | 44100 | 1 | -2.5 | -16.5 | USED | 6 | scripts/balao.gd:130 |
| `bau_abrir` | bau_abrir.wav | wav | 0.78 | 44100 | 1 | -1.4 | -19.4 | USED | 1 | scripts/bau_chefe.gd:80 |
| `conquista` | conquista.wav | wav | 6.12 | 44100 | 2 | -1.2 | -10.4 | USED | 2 | scripts/chefe_base.gd:710 |
| `desbloqueio` | desbloqueio.wav | wav | 1.80 | 44100 | 1 | -5.0 | -15.1 | USED | 2 | scripts/coletavel.gd:179 |
| `recompensa` | recompensa.wav | wav | 1.30 | 44100 | 1 | -2.9 | -16.2 | USED | 1 | scripts/bau_chefe.gd:84 |
| `selo` | selo.wav | wav | 1.00 | 44100 | 1 | -3.8 | -18.8 | USED | 7 | scripts/checkpoint.gd:298 |
| `transicao` | transicao.wav | wav | 1.05 | 44100 | 1 | -3.1 | -17.3 | USED | 2 | scripts/porta.gd:77 |

### UI

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `carrossel` | carrossel.wav | wav | 0.07 | 44100 | 1 | -1.1 | curto | USED | 2 | scripts/editor_layout_toque.gd:199 |
| `ui_confirmar` | ui_confirmar.wav | wav | 0.23 | 44100 | 1 | -1.0 | curto | USED | 3 | scripts/menu_inicial.gd:136 |
| `ui_mover` | ui_mover.wav | wav | 0.05 | 44100 | 1 | -1.1 | curto | USED | 3 | scripts/menu_inicial.gd:135 |
| `ui_mover_v2` | ui_mover_v2.wav | wav | 0.05 | 44100 | 1 | -1.4 | curto | INTENTIONAL | 0 | — |
| `ui_mover_v3` | ui_mover_v3.wav | wav | 0.05 | 44100 | 1 | -1.3 | curto | INTENTIONAL | 0 | — |
| `ui_negado` | ui_negado.wav | wav | 0.24 | 44100 | 1 | -1.3 | curto | USED | 3 | scripts/santuario.gd:229 |
| `ui_voltar` | ui_voltar.wav | wav | 0.20 | 44100 | 1 | -4.8 | curto | USED | 3 | scripts/menu_inicial.gd:365 |

### WORLD

| chave | ficheiro | fmt | dur | SR | ch | pico | LUFS | estado | usos | callsite |
|---|---|---|--:|--:|--:|--:|--:|---|--:|---|
| `vento_rajada` | vento_rajada.wav | wav | 0.85 | 44100 | 1 | -8.4 | -21.8 | USED | 1 | scripts/wind_zone.gd:184 |
