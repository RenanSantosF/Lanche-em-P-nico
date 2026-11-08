# Intro FT — vinheta de abertura para todos os jogos

Pacote autocontido com a identidade **FT** (monograma F+T com nó de circuito).
Nada da Godot aparece: o boot splash fica só na cor de fundo da marca e a primeira
cena é esta intro animada (≈3 s, com jingle). Toque na tela pula a intro.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `FTIntro.tscn` / `FTIntro.gd` | Cena da intro animada (use como cena principal) |
| `FTLogo.gd` | Desenho vetorial do logo (dá pra usar em qualquer tela) |
| `ft_jingle.wav` | Som da vinheta |
| `ft_logo.png` | Logo 1024×1024 com fundo transparente |
| `ft_splash_portrait.png` / `ft_splash_landscape.png` | Pôsteres prontos (1080×1920 e 1920×1080) |
| `preview/ft_intro_vertical.mp4` / `preview/ft_intro_horizontal.mp4` | Vídeo da intro para redes sociais, lojas e trailers |

## Como usar em outro jogo Godot 4

1. Copie a pasta `ft_intro/` inteira para a raiz do projeto.
2. Em **Projeto > Configurações do Projeto**:
   - `application/run/main_scene` = `res://ft_intro/FTIntro.tscn`
   - `application/boot_splash/show_image` = **desligado**
   - `application/boot_splash/bg_color` = `#14082e`
3. Abra `FTIntro.tscn` e mude **Next Scene** para a cena inicial do seu jogo.

A próxima cena é carregada em segundo plano enquanto a intro roda, então a troca é instantânea.

## Cores da marca

- Fundo: `#14082e`
- Placa (degradê diagonal): `#ff006e` → `#8338ec` → `#3a86ff`
- Contorno: `#ffbe0b`
- Circuito / nó: `#00f5d4`
- Letras: `#ffffff` → `#fff3b0`
- Paleta de brilhos: `#ff006e`, `#ffbe0b`, `#00f5d4`, `#3a86ff`, `#fb5607`, `#8338ec`

## Regerar imagens, som e vídeos

```bash
python3 tools/gen_audio.py                                   # jingle e sons
godot --rendering-driver opengl3 -s tools/export_brand.gd    # PNGs
godot --rendering-driver opengl3 --resolution 1080x1920 \
      --write-movie intro.avi --fixed-fps 30 --quit-after 92 res://ft_intro/FTIntro.tscn
ffmpeg -i intro.avi -c:v libx264 -pix_fmt yuv420p -c:a aac ft_intro_vertical.mp4
```
