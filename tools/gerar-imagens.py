#!/usr/bin/env python3
"""Gera em SVG o wallpaper e a tela de boas-vindas do Speedy Linux.

Uso: gerar-imagens.py LARGURA ALTURA [--text] > saida.svg
Normalmente chamado por tools/gerar-imagens.sh, que também converte para PNG.
"""
import random
import sys

W, H = int(sys.argv[1]), int(sys.argv[2])
TEXT = "--text" in sys.argv

K = H / 2160          # tudo foi desenhado para 2160px de altura
CX, CY = W / 2, H * 0.46
S = 1.25 * K          # escala do logo
CYAN = "#00A8D8"
random.seed(7)

out = []
a = out.append
a(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
a('<defs>')
a(f'''<radialGradient id="bg" cx="50%" cy="46%" r="75%">
  <stop offset="0" stop-color="#0B4C8C"/>
  <stop offset="0.35" stop-color="#062E62"/>
  <stop offset="0.75" stop-color="#03173A"/>
  <stop offset="1" stop-color="#010A1E"/>
</radialGradient>
<radialGradient id="halo" cx="50%" cy="50%" r="50%">
  <stop offset="0" stop-color="{CYAN}" stop-opacity="0.35"/>
  <stop offset="0.6" stop-color="{CYAN}" stop-opacity="0.08"/>
  <stop offset="1" stop-color="{CYAN}" stop-opacity="0"/>
</radialGradient>
<linearGradient id="fadeR" x1="0" x2="1" y1="0" y2="0">
  <stop offset="0" stop-color="{CYAN}"/>
  <stop offset="0.45" stop-color="#5CCDEB"/>
  <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
</linearGradient>
<linearGradient id="fadeL" x1="0" x2="1" y1="0" y2="0">
  <stop offset="0" stop-color="#FFFFFF" stop-opacity="0"/>
  <stop offset="0.55" stop-color="#5CCDEB"/>
  <stop offset="1" stop-color="{CYAN}"/>
</linearGradient>
<linearGradient id="streak" x1="0" x2="1" y1="0" y2="0">
  <stop offset="0" stop-color="{CYAN}" stop-opacity="0"/>
  <stop offset="0.7" stop-color="#3FC3EC" stop-opacity="0.9"/>
  <stop offset="1" stop-color="#E6F8FF" stop-opacity="1"/>
</linearGradient>
<linearGradient id="streakL" x1="0" x2="1" y1="0" y2="0">
  <stop offset="0" stop-color="#E6F8FF" stop-opacity="1"/>
  <stop offset="0.3" stop-color="#3FC3EC" stop-opacity="0.9"/>
  <stop offset="1" stop-color="{CYAN}" stop-opacity="0"/>
</linearGradient>
<filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
  <feGaussianBlur stdDeviation="18" result="b"/>
  <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
</filter>
<filter id="blur40"><feGaussianBlur stdDeviation="{40*K:.1f}"/></filter>
<radialGradient id="vignette" cx="50%" cy="50%" r="75%">
  <stop offset="0.6" stop-color="#000" stop-opacity="0"/>
  <stop offset="1" stop-color="#000" stop-opacity="0.55"/>
</radialGradient>
''')
a('</defs>')

# fundo
a(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')

# faixas diagonais suaves (luz)
for x0, w, op in [(-0.10, 260, 0.10), (-0.03, 90, 0.08), (0.76, 320, 0.07), (0.87, 120, 0.09)]:
    x = x0 * W
    a(f'<rect x="{x:.0f}" y="{-600*K:.0f}" width="{w*K:.0f}" height="{H+1200*K:.0f}" '
      f'fill="#2A8FE0" opacity="{op}" transform="rotate(35 {x:.0f} 0)" filter="url(#blur40)"/>')

# linhas de velocidade horizontais (motivo do logo)
for _ in range(int(70 * W / 3840)):
    y = random.uniform(80 * K, H - 80 * K)
    if abs(y - CY) < 470 * S and random.random() < 0.85:  # evita o miolo do logo
        continue
    length = random.uniform(300, 1500) * K
    h = random.choice([2, 3, 4, 6, 8]) * max(K, 0.6)
    op = random.uniform(0.10, 0.45)
    if random.random() < 0.5:
        x, grad = random.uniform(-200 * K, W * 0.45), "streak"
    else:
        x, grad = random.uniform(W * 0.5, W + 200 * K) - length, "streakL"
    a(f'<rect x="{x:.0f}" y="{y:.0f}" width="{length:.0f}" height="{h:.1f}" rx="{h/2:.1f}" '
      f'fill="url(#{grad})" opacity="{op:.2f}"/>')

# partículas
for _ in range(int(260 * W * H / (3840 * 2160))):
    x, y = random.uniform(0, W), random.uniform(0, H)
    r = random.choice([1.5, 2, 2.5, 3, 4, 5]) * max(K, 0.6)
    op = random.uniform(0.15, 0.8)
    col = random.choice(["#7FD8F5", "#3FB6F0", "#FFFFFF", "#4A90E2"])
    a(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r:.1f}" fill="{col}" opacity="{op:.2f}"/>')

# halo atrás do logo
a(f'<circle cx="{CX}" cy="{CY}" r="{700*S:.0f}" fill="url(#halo)"/>')
a(f'<circle cx="{CX}" cy="{CY}" r="{414*S:.0f}" fill="#021433" opacity="0.55"/>')

# ---- logo (recriado em vetor a partir de images/logo.png) ----
a(f'<g transform="translate({CX} {CY}) scale({S:.4f})">')
a(f'<circle r="414" fill="none" stroke="{CYAN}" stroke-width="36" filter="url(#glow)"/>')
pitch, bh, y0 = 27, 18, -250
top_left = [-193, -211, -228, -249, -266, -279, -266, -249, -228, -211, -193]
top_right = [221, 206, 186, 166, 151, 146, 151, 166, 186, 206, 221]
bot_right = [250, 267, 280, 267, 250, 230, 213, 195]
bot_left = [-164, -149, -139, -144, -159, -184, -204, -219]
for i, (l, r) in enumerate(zip(top_left, top_right)):
    a(f'<rect x="{l}" y="{y0 + i*pitch}" width="{r-l}" height="{bh}" fill="url(#fadeR)"/>')
for j, (l, r) in enumerate(zip(bot_left, bot_right)):
    a(f'<rect x="{l}" y="{y0 + (len(top_left)+j)*pitch}" width="{r-l}" height="{bh}" fill="url(#fadeL)"/>')
a('</g>')

# texto
if TEXT:
    ty = CY + 414 * S + 230 * K
    a(f'<text x="{CX}" y="{ty:.0f}" text-anchor="middle" font-family="Noto Sans" '
      f'font-weight="300" font-size="{120*K:.0f}" letter-spacing="{38*K:.0f}" '
      f'fill="#CDEFFC" opacity="0.92">SPEEDY LINUX</text>')

# vinheta
a(f'<rect width="{W}" height="{H}" fill="url(#vignette)"/>')
a('</svg>')
print("\n".join(out))
