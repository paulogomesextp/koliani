# Animações dos inimigos da Região II (N6-N10) -- 1 out 2026

Pedido do Paulo: a arte está boa, as animações são fracas e precisam de mais movimento. Níveis, terreno, hitboxes, IA e balanço **não** foram tocados.

## O que mudou
`tools/animar_regiao02.py` deriva as tiras das quatro espécies comuns/guardiões (morcego_dos_ventos, sentinela_flutuante, golem_aereo, elemental_do_vento) a partir da pose aprovada (mesmo método da Região I, `animar_criaturas_9h1.py`): idle 8, run 8, attack 6, hit 4, dead 8 (antes 2/2/1/1/1). A base e as poses de ataque/morte desenhadas na prancha ficam em `<espécie>/_origem/` (`.gdignore`), por isso correr a ferramenta duas vezes dá o mesmo.
- Morcego: bater de asas por deformação das asas + balanço; ataque arma (asas no alto, recua) -> investida (pose da prancha) -> recupera; morte a cair a rodar.
- Sentinela: capa a ondular, inclina-se ao andar, recua e lança-se no ataque, dissolve-se ao morrer.
- Golem: 12 blocos de pedra a flutuar cada um com a sua fase; contrai-se, desdobra-se no ar, golpe (pose da prancha) e baque; desfaz-se em pedras ao morrer.
- Elemental: torção do turbilhão por linha, alarga-se no golpe, dissipa-se de cima para baixo.
- Guardião dos Céus (N10): o idle tinha 6 quadros com 2 pares repetidos (engasgava); refeito como ciclo contínuo de 10 quadros (`--guardiao`, `rigs.json`).
O Golem das Falésias (N6) já tinha peças a flutuar cada uma com a sua fase (diferença de ~8000 px por transição), ficou como está. Os guardiões N7-N9 são elites destas mesmas espécies, portanto herdam a revisão.

## Cuidados
O quadro 0 do idle é a base, intacta: a escala do jogo (medida nesse quadro) não muda. Todas as tiras da espécie têm a mesma largura de quadro (`teste_especies_dos_inimigos_existem`). `dead` agora demora ~0,7 s antes de o inimigo se libertar.

## Por validar (humano)
Ritmo em jogo (fps iguais aos antigos), leitura da pose do golem a "desdobrar". Antes/depois em `docs/qa/animacoes_r2/*.gif`. Suite verde, save real intacto.
