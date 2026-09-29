# EXECUTION — Tirar o PIN do DEV MODE (19 set 2026)

Branch `claude/remove-devmode-pin`, a partir de `origin/master @ 7a4e586a`.
Pedido do Paulo: **o DEV MODE deixa de pedir PIN**. O modo dev fica, as
ferramentas ficam; o que sai é a porta.

Versão: **0.18.17 → 0.18.18**.

---

## 1. O que era o PIN, e o que ele não era

O PIN vivia **num único sítio**: `scripts/menu_inicial.gd`.

| Onde | O quê |
|---|---|
| `menu_inicial.gd:28` | `const PIN_DEV := "0980"` |
| `menu_inicial.gd:51-57` | `_pedir_pin_dev` + 6 membros do painel |
| `menu_inicial.gd:352-414` | `_ao_dev_mode()` construía o modal |
| `menu_inicial.gd:416-429` | `_confirmar_pin_dev()` — a validação |
| `menu_inicial.gd:431-447` | `_fechar_pin_dev()` + `_input()` (Esc) |
| `menu_inicial.gd:492-495` | `--devmode` também era desviado para o PIN |
| `assets/i18n/*.json` | 5 chaves `dev.pin_*` nos 6 catálogos |
| `tests/run_dev_pin.gd` | harness que provava o contrário |

Três coisas que a auditoria estabeleceu, e que mudaram o plano:

1. **O PIN nunca esteve no save nem na config.** Era uma constante no
   código; `estado_jogo.gd` nunca o conheceu. Por isso **não há formato de
   save a migrar nem valor legado a ignorar** — saves antigos lêem-se na
   mesma. Não se acrescentou compatibilidade nenhuma porque não havia nada
   de que ser compatível.
2. **A porta a sério continua a ser o interruptor de build**
   `koliani/qa/entrada_dev` (`project.godot`). É ele que decide se o botão
   sequer existe, e é ele que fica `false` numa build de loja. Um PIN de
   quatro dígitos escrito em claro no código-fonte de um jogo **público**
   nunca foi uma credencial: era atrito para quem desenvolve.
3. **O CI não corria o `run_dev_pin.gd`.** Só corre `run_tests.tscn` (mais
   um harness de vento) e os 9 verificadores. Uma regressão que viva só num
   harness solto não guarda nada — por isso o teste novo foi **também** para
   `run_tests.gd`.

## 2. O que mudou

- `_ao_dev_mode()` passa a `entrada_dev_disponivel()` → `ativar_modo_dev()`
  → `_ir_jogar()`. Sem painel, sem campo, sem validação.
- `--devmode` entra já em DEV MODE (antes abria o mesmo pedido de PIN).
- Código morto **removido**, não deixado a apodrecer: a constante, os seis
  membros, `_confirmar_pin_dev`, `_fechar_pin_dev`, o `_input` que só
  existia para o Esc do painel, e as 5 chaves nos 6 catálogos (750 chaves em
  cada, paridade mantida — o `teste_i18n_ficheiros_validos` exige-a).
- **NÃO** foram removidos `Frontend9H.painel_liso` nem o som `ui_negado`:
  continuam a ser usados pela Pausa e pelos controlos de toque. Verificado.

O modo dev continua a ser um **sandbox**: `ativar_modo_dev()` guarda a
campanha legítima antes de mexer em nada e `desativar_modo_dev()` repõe-a
byte a byte. Os testes exigem isso, e continuam a exigi-lo.

---

## 3. O achado: o bug do ESPAÇO **não estava corrigido**

O briefing pedia para *confirmar* que a correcção de `7a4e586a` continuava
de pé. Não continuava — e só se soube por se ter ido ver em **janela real**.

`7a4e586a` está correcta no que faz: o botão da barra deixou mesmo de ficar
com o foco. Medido:

```
QA DEV: foco depois de fechar o selector = NINGUEM
ERROR: QA DEV: o salto 1 trocou de cena -- a barra Dev morreu,
       ou seja, o nivel recarregou
```

Foco em ninguém, e o primeiro salto recarregou o nível na mesma. O foco não
era a causa.

### Causa a sério

1. `dev_barra.gd` monta o `SeletorNiveis` logo no `_ready`, dentro de um
   painel que nasce **apenas escondido** (`visible = false`);
2. em Godot, `visible = false` cala o `_gui_input` mas **não** cala o
   `_unhandled_input`;
3. `seletor_niveis.gd:790` trata `ui_accept` no `_unhandled_input` →
   `_confirmar()` → `escolhido` → `_ir_para()` → troca de cena;
4. o ESPAÇO é `saltar` **E** `ui_accept`, e saltar não consome o evento.

Cada salto em DEV MODE chegava ao selector **invisível**, que confirmava o
nível seleccionado e o recarregava — com o painel invisível o tempo todo.
**Não era sequer preciso ter clicado no botão.**

### Correcção

O painel fechado fica mesmo desligado (`PROCESS_MODE_DISABLED`), **e o
selector também**.

> **Armadilha, custou uma volta:** desligar só o painel-pai NÃO chega. O
> `SeletorNiveis` põe-se a si próprio em `PROCESS_MODE_ALWAYS` (precisa
> disso para responder com o jogo em pausa), e `ALWAYS` ignora de propósito
> o estado dos antepassados. A primeira tentativa desligou só o painel e a
> suite continuou vermelha.

`_abrir()` volta a ligar os dois antes do `configurar`, portanto o selector
responde em pausa exactamente como sempre respondeu.

### Porque é que o teste antigo não podia apanhar isto

Exigia que o **painel** não ficasse visível. O nível recarregava sem o
painel alguma vez aparecer — a asserção passava com o bug vivo. O teste
passa a vigiar o **sinal** `escolhido` (o que leva mesmo à troca de cena) e
o `indice_nivel` da sessão.

---

## 4. Provas — todas nos dois sentidos

| Prova | Com o defeito reposto | Corrigido |
|---|---|---|
| `run_tests.tscn` vs PIN | 9 asserções falham, exit 1 | verde |
| `run_dev_acesso.gd` vs PIN | 10 falhas, exit 1 | `falhas=0` |
| `run_tests.tscn` vs ESPAÇO | exit 1, falha **só** a asserção nova | verde |
| `tools/qa_dev_sem_pin.gd` (janela real) | `o salto 1 trocou de cena` | `falhas=0` |

Na prova do ESPAÇO, as asserções **antigas** continuaram verdes com o bug
reposto — é a medida exacta do ponto cego.

### Godot real (Xvfb + OpenGL3, 1280x720)

`tools/qa_dev_sem_pin.gd` abre o menu numa janela real, clica no DEV MODE
**com o rato**, entra no jogo, clica no TESTAR OUTRO NÍVEL, fecha o selector
e salta cinco vezes com teclas a sério:

- menu sem campo de texto nenhum e sem painel de acesso;
- um clique → `DEV MODE · L1`, barra Dev montada, sem PIN pelo meio;
- selector abre ao clique e fecha;
- cinco saltos: Koliani fica na **mesma instância** e em
  `x = -2370.0` antes e depois — o nível não recarregou.

Fotos em `docs/playtests/devmode_sem_pin/`.

---

## 5. O que NÃO se validou aqui, e porquê

- **Não há Windows neste contentor** (nem wine). O `.exe` foi exportado do
  master e validou-se o **conteúdo empacotado**, extraindo o `.pck` e
  correndo-o com `--main-pack`. Quem abre o executável em Windows é o Paulo.
- **A URL pública do Pages não foi aberta daqui** — a política de rede do
  contentor bloqueia `github.io`. Reporta-se o deployment e o `head_sha`
  comprovados pelo próprio GitHub, não uma validação que não houve.
- **O `.pck` não é reproduzível byte a byte** entre exportações (armadilha
  já registada na sessão anterior): comparar SHA de builds não prova
  alinhamento. A prova de que Windows e PWA são a mesma versão é o **SHA do
  commit** registado pelo GitHub.
