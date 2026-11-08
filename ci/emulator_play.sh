#!/usr/bin/env bash
# Joga o tutorial no emulador com toques simulados e coleta logcat + capturas.
# Coordenadas do jogo (largura 720) são multiplicadas pela escala da tela.
set -u
PKG=${PKG:-com.ferreiratecnologia.lancheempanico}
mkdir -p diag
adb wait-for-device
adb shell settings put global window_animation_scale 0 || true
# não mostrar o aviso "Viewing full screen" (ele cobre a tela e rouba os toques)
adb shell settings put secure immersive_mode_confirmations confirmed || true
adb install -r build/emu.apk
adb logcat -c

W=$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | cut -dx -f1)
H=$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | cut -dx -f2)
echo "tela ${W}x${H}"
# escala: largura da tela / 720 (a altura do jogo é H / escala)
S=$(python3 -c "print($W/720)")
GH=$(python3 -c "print(round($H/($W/720)))")
echo "escala $S, altura do jogo $GH"

tap() {  # tap X Y (coordenadas do jogo)
  local x y
  x=$(python3 -c "print(int($1*$S))"); y=$(python3 -c "print(int($2*$S))")
  adb shell input tap "$x" "$y"
  sleep "${3:-0.6}"
}
shot() { adb exec-out screencap -p > "diag/$1.png"; }
alive() {
  if adb shell pidof "$PKG" > /dev/null; then echo "[OK] app rodando: $1"; else echo "[CRASH] app FECHOU em: $1"; fi
}

adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
sleep 20
alive "abertura"
shot 01_inicio

# painel de idioma (primeira vez) -> Português (centro da tela)
MID=$(python3 -c "print($GH/2)")
tap 360 "$(python3 -c "print($MID - 76)")" 2
shot 02_menu
alive "menu"

# JOGAR (caixa do menu ancorada embaixo)
tap 360 "$(python3 -c "print($GH - 259)")" 4
shot 03_dia1
alive "começo do dia"

# layout do dia 1 (1 linha de botões)
read -r TILE_Y GRILL_Y DELIVER_Y < <(python3 - "$GH" <<'EOF'
import sys
H = float(sys.argv[1])
TOP, GRILL, WORK, TILE, GAP = 84, 110, 300, 116, 10
rows = 1
base_panel = rows * (TILE + GAP) + GAP + 12
extra = max(0, H - TOP - GRILL - WORK - base_panel - 470)
tile_h = TILE + min(40, extra * 0.4 / rows)
work_h = WORK + min(80, extra * 0.3)
panel_h = rows * (tile_h + GAP) + GAP + 12
wy = H - panel_h - work_h
print(int(wy + work_h + GAP + 6 + tile_h / 2), int(wy - GRILL + GRILL / 2), int(wy + 14 + (work_h - 46) * 0.28))
EOF
)
echo "tiles y=$TILE_Y grill y=$GRILL_Y entregar y=$DELIVER_Y"
X_PAO=94; X_CARNE=271; X_CHEDDAR=449; X_GRILL0=408

tap $X_CARNE "$TILE_Y" 1          # carne na chapa (deve ir para UMA chapa só)
shot 04_carne
tap $X_PAO "$TILE_Y" 1             # pão de baixo (só UM pão)
shot 05_pao
tap $X_CHEDDAR "$TILE_Y" 1         # cheddar em cima da carne
alive "montando"
sleep 11                           # assa (9s) + derrete
shot 06_pronta
tap $X_GRILL0 "$GRILL_Y" 1.5       # pega a carne pronta
tap $X_PAO "$TILE_Y" 1.5           # fecha
shot 07_fechado
tap 644 "$DELIVER_Y" 3             # entregar
shot 08_entregue
alive "entrega"

# joga de verdade por ~90s: carne, pão, cheddar, pega a carne, fecha e entrega
for i in 1 2 3 4 5 6; do
  tap $X_CARNE "$TILE_Y" 0.4
  tap $X_PAO "$TILE_Y" 0.4
  tap $X_CHEDDAR "$TILE_Y" 0.4
  sleep 7
  tap $X_GRILL0 "$GRILL_Y" 0.6
  tap $X_PAO "$TILE_Y" 0.6
  tap 644 "$DELIVER_Y" 2
  alive "jogando $i"
done
shot 09_jogando
sleep 20
alive "fim"
shot 10_fim

adb logcat -d > diag/logcat.txt
echo "=== trechos importantes do logcat ==="
echo "toques duplicados ignorados: $(grep -c 'toque duplicado' diag/logcat.txt)"
echo "=== desempenho ==="
grep "\[LP\] perf" diag/logcat.txt | sed 's/.*\[LP\]/[LP]/' || true
grep -E "FATAL|SIGSEGV|SIGABRT|backtrace|Abort message|godot.*(ERROR|SCRIPT)|E godot|USER ERROR|\[LP\]|Ads" diag/logcat.txt | head -120 || true
echo "=== fim ==="
exit 0
