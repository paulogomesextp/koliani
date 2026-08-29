# Como testar o Koliani (Paulo)

## Correr o jogo no PC

**Editor (recomendado para desenvolver):**
```
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" -e .
```
No editor: **F5** corre o jogo (a partir do mundo atual do save), **F6**
corre a *cena aberta* (útil para testar um nível isolado).

**Sem editor (correr como o jogador veria):**
```
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" .
```

## Controlos

| Ação | Teclado | Toque (telemóvel) |
|------|---------|-------------------|
| Andar | setas ← → ou A / D | d-pad esquerdo |
| Saltar (duplo depois de apanhar a gema do mundo 1) | Espaço ou ↑ | botão baixo-direito |
| Atacar | J | botão de ação (cima) |
| Dash | K | botão de ação (baixo) |
| Rolar | ↓ | botão de ação (esquerda) |
| Diário de pistas | I ou Tab | botão canto sup. direito |
| Fechar diário | Esc | (toca fora / botão) |

## Atalhos de depuração (só no editor / build de debug)

| Tecla | Efeito |
|-------|--------|
| F1 / F2 / F3 / F4 | saltar para o mundo 1 / 2 / 3 / 4 |
| F5 | desbloquear todas as habilidades (salto duplo, dash aéreo, partir paredes) |
| F6 | +3 vidas |
| F9 | apagar o save e recomeçar a campanha |

O save fica em
`%APPDATA%\Godot\app_userdata\Koliani\progresso.json` — apagar esse ficheiro
também recomeça do zero.

## Estado visual/áudio (2.º passe, "look Dead Cells")

Personagens são sprites SVG rim-lit com shader (flash de dano) e animação
procedural (squash/stretch, wind-up dos chefes, rastro da lâmina, frame de
impacto). Ambiente: parallax de 4 camadas com silhuetas recortadas, feixes
de luz, poeira, e passe de ecrã (contraste/saturação/**bloom** — baixa em
`Atmosfera.tscn > Grade > Passe` se estiver forte para o teu gosto).
Plataformas com shader de pedra/tijolo. SFX sintetizados + cama de
ambiente em loop. **Falta:** frames de animação a sério, música, tiles
decorados, mixagem de áudio.

## O que olhar (a jogabilidade ainda é *greybox* — layout por afinar)

- **Feel do movimento**: salto/duplo salto, corte de salto, dash, rolar.
  Os números estão em `scripts/movimento.gd` e `scripts/koliani.gd`.
- **Distâncias de salto** entre plataformas (montei sem jogar).
- **Ritmo** dos inimigos e do chefe (telegrafo → investida).
- **Fossos**: cair no vazio reaparece no checkpoint.

Anota o que estiver mal (muito curto / muito longo / injusto) que eu afino.

---

# Instalar o que falta

## 1. Modelos de export (para builds Web/APK locais, ~700 MB, uma vez)

No editor: **Editor → Gerir Modelos de Exportação → Transferir e Instalar**.
Ou, se a transferência falhar: descarregar
`Godot_v4.7.2-stable_export_templates.tpz` de
<https://godotengine.org/download/archive/4.7.2-stable/> e, no mesmo
diálogo, **Instalar a partir de ficheiro**.

Depois disto funciona:
```
& "C:\...\Godot_v4.7.2-stable_win64.exe" --headless --export-release "Web" build/web/index.html
python -m http.server 8060 --directory build/web
```

## 2. Ligar o repositório ao GitHub + CI

O agente não mexe em `git config`/`remote` — estes passos são teus:

1. Cria um repositório **vazio** no GitHub (sem README/licença).
2. No `C:\Projetos\koliani`:
   ```
   git remote add origin https://github.com/<o-teu-user>/koliani.git
   git push -u origin master
   ```
3. O workflow `.github/workflows/ci.yml` corre sozinho a cada push:
   testes → build Web → build APK (artifacts `koliani-web`, `koliani-android`).
4. A **1.ª execução** pode falhar por detalhes (versão da imagem
   `barichello/godot-ci`, nome dos presets). Manda-me o log do Actions que
   eu ajusto o YAML.

Com o CI a verde tens sempre um **APK** para instalar no telemóvel a partir
da página do Actions, sem precisar do PC ligado.
