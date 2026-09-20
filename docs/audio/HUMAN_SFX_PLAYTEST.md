# Playtest de som — checklist do Paulo

A fase automática do SFX Overhaul está fechada. O que falta é o que nenhuma
medição resolve: **ouvir**.

Não é preciso escrever muito. Para cada linha, marcar uma:

`BOM` · `ALTO DEMAIS` · `BAIXO DEMAIS` · `IRRITANTE` · `SOM ERRADO` · `OUTRO`

"IRRITANTE" é uma resposta válida e útil — quer dizer que o som está bem
escolhido e bem medido mas cansa à décima vez. Isso só se descobre a jogar.

---

## Como abrir

**Windows** (é o mais fiável, começa por aqui):

```
C:\Projetos\koliani-sfx\build\qa\Koliani-SFX-QA.exe
```

**Web** (só se quiseres confirmar o browser — o servidor tem de estar a
correr; o PC foi suspenso, por isso é preciso arrancá-lo outra vez):

```bash
cd C:\Projetos\koliani-sfx && python tools/servidor_prova_web.py build/qa/web build/qa/prova 8099
```

Depois abrir `http://localhost:8099/index.html` no Chrome. Carregar uma vez
no ecrã ("TAP TO PLAY") — o browser só deixa tocar som depois de um clique
verdadeiro.

> O áudio do Web **não ficou provado automaticamente**. O motor arranca, o
> `AudioContext` fica em `running` e não há erros de áudio na consola, mas
> não consegui medir som à saída sem uma pessoa. Se o Web vier mudo, é um
> achado, não um imprevisto — já aconteceu antes (9F).

**Android**: não há APK local — falta o SDK nesta máquina. Sai do CI.

---

## A. JOGADOR

| | som | nota |
|---|---|---|
| ☐ | salto / salto duplo | |
| ☐ | dash | |
| ☐ | combo de espada (os 4 golpes crescem?) | |
| ☐ | acerto no inimigo | |
| ☐ | escudo (activar e levar impacto) | |
| ☐ | levar dano | |
| ☐ | morte | |
| ☐ | passos (cansam?) | |

## B. INIMIGOS

| | som | nota |
|---|---|---|
| ☐ | ataques — dá para distinguir as famílias? | |
| ☐ | levar dano | |
| ☐ | morte | |
| ☐ | repetição: numa sala com 5 iguais, irrita? | |

## C. CHEFES

| | som | nota |
|---|---|---|
| ☐ | levar dano | |
| ☐ | ataques — o chefe tem identidade própria? | |
| ☐ | mudança de fase — ouve-se que mudou? | |
| ☐ | morte + conquista (empilham?) | |
| ☐ | **`esmagar`** — distorce? (ver nota no fim) | |

## D. MUNDO

| | som | nota |
|---|---|---|
| ☐ | **vento ambiente** — é o mais arriscado de todos | |
| ☐ | vento: a rajada ao entrar na zona lê-se como ataque? | |
| ☐ | sino da torre (N11) | |
| ☐ | alavancas / placas de peso | |
| ☐ | grade a abrir e a fechar | |
| ☐ | elevador (o laço vira padrão?) | |
| ☐ | perigos: plataforma a ceder, pedra, lâmina, fogo, raio | |
| ☐ | o aviso lê-se mesmo como aviso (e não como dano)? | |

## E. PROGRESSÃO

| | som | nota |
|---|---|---|
| ☐ | checkpoint | |
| ☐ | baú: abrir → prémio (os dois separam-se bem?) | |
| ☐ | desbloquear habilidade | |
| ☐ | apanhar essência / coletável | |
| ☐ | portal | |
| ☐ | fim de nível (porta) | |
| ☐ | **hierarquia**: a vitória sobre o chefe é o momento mais alto? | |

---

## Os cinco pontos onde eu apostei e posso ter errado

Não são bugs — são escolhas minhas que só se confirmam a ouvir.

1. **Vento ambiente a −26 dB.** É o primeiro som contínuo do jogo. Acima
   disto tapa os passos, abaixo disto não existe. E o ciclo é de 6 s: se se
   der a ouvir como ciclo, é para encurtar ou trocar.
2. **Laço do elevador, 2,4 s.** Curto. O rangido pode virar métrica.
3. **Sino da torre com 2,3 s de cauda.** Pode tapar o combate logo a seguir
   à badalada.
4. **`raio_cai` a −8 dB.** Pode ser demais.
5. **Alavanca, placa e elevador partilham o mesmo ficheiro** (`mecanismo`),
   só muda o tom. Pode soar a "o mesmo clique outra vez".

## Uma coisa que deixei por decidir (é tua)

**`esmagar.ogg` continua a distorcer.** Descodifica a +7,3 dBFS, acima do
máximo, e está em 16 sítios — é o ataque de chefe mais usado do jogo. Já era
assim antes deste trabalho.

Corrigi os outros dois casos iguais (`golpe_pesado`, `grito`) porque neles
dava para tirar a distorção sem mexer no peso do som. No `esmagar` não dá: o
excesso está espalhado por sete rajadas, e tirá-lo custa **1,4 dB** do que se
ouve. Mudar o peso de um som é decisão tua, não minha.

Se ao ouvir achares que distorce, é um comando:

```bash
cd C:\Projetos\koliani-sfx && python tools/corrigir_clipping_p4.py --forcar esmagar.ogg
```

Se achares que soa bem como está, fica como está.

---

## Percurso de teste (10–15 min)

Feito para tocar em quase tudo sem jogar a campanha toda. Pelo
**SELECT LEVEL** do menu dá para saltar directo a cada nível.

| # | onde | ~min | o que se ouve aqui |
|---|---|---|---|
| 1 | **N1 — Floresta Putrefata** | 3 | jogador completo (salto, dash, combo, dano, morte), inimigos da Região I, checkpoint, essência, raízes, plataformas ritmadas, porta de fim de nível |
| 2 | **N5 — chefe da Região I** | 3 | chefe: dano, ataques, fase, morte + conquista; **baú** (abrir → prémio); **desbloqueio** do salto duplo |
| 3 | **N8 — Região II** | 2 | **vento**: ambiente e rajada, planar; é aqui que se decide o ponto 1 da lista de cima |
| 4 | **N10 — Guardião dos Céus** | 2 | vento que muda de direcção a meio do combate + chefe |
| 5 | **N11 — Torre dos Sinos** | 2 | **sino mecânico**, plataformas que trocam de estado, alavancas/grades |
| 6 | **N13 — Mecanismos Antigos** | 2 | mecanismos, engrenagens, **raio** (aviso + descarga) |
| 7 | **N16 — Cemitério dos Reis** | 1 | **elevador** (arranque, laço, paragem), pedras a cair |
| 8 | qualquer nível com **portal** | 1 | travessia — uma voz só |

Se só houver tempo para três: **N1, N5 e N8.** Cobrem jogador, chefe,
progressão completa e o vento, que é a aposta maior.

---

## Depois

Basta mandar as marcas e as notas soltas. Com isso faço um passe de
correcções **baseado no que ouviste** — nada de outro passe automático, que
a partir daqui já não acrescenta nada.
