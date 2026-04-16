# UI Design: AntWar — 蚂蚁帝国

## Style
- Widget-style: rounded container on clean light background, not fullscreen
- Rich textures via PixiJS: real soil sprites, shader lighting, particle effects
- Illustrated but grounded — ants look like ants with character, not cartoons or SVG blobs
- Colony distinction: Red = warm tones (amber/red-brown), Blue = cool tones (steel/blue-grey)
- 2.5D parallax depth in the underground
- Tunnel networks glow faintly with colony color — like living veins in the earth
- References: Widget Island fish tank app (clean, contained, polished), physical 蚂蚁生态箱

## Layout
- **Widget container** on clean light background (#f2f0ed)
- Rounded corners (28px), soft shadow — feels like an iOS widget card
- Title "蚂蚁帝国 · AntWar" above the widget, subtle
- Underground fills the widget — surface is just a thin grass strip at top

## Widget Interior
- **Top:** compact scoreboard (Red % vs Blue %, population, food)
- **Center:** the underground world — soil, tunnels, ants, battles
- **Bottom:** thin territory bar (red/blue balance), day counter, speed controls (1x/2x/5x/10x)
- All UI elements inside the widget are minimal and semi-transparent

## Event Log
- Lives OUTSIDE the widget, below it
- "View Event Log" button triggers an iOS-style sheet sliding up from bottom
- White panel with clean typography
- Timestamped entries with color-coded Red/Blue text
- Educational context in lighter italic text, left-bordered

## User Flow
1. Open aips.build/antwar → Setup: place queens, food, rocks
2. Click "Seal Tank" → observation begins
3. Watch tunnels grow, ants forage, battles happen
4. Click "View Event Log" to read what happened
5. Glance at scoreboard for who's winning
6. Adjust speed if desired
7. Win condition triggers → overlay with stats
8. "Keep watching" or "New Game"

## Visual Quality Targets
- Soil must feel textured and layered — real dirt, not gradients
- Tunnels must feel carved and organic — irregular edges, not geometric paths
- Ants must have character — visible legs, antennae, carrying animation
- Lighting must create atmosphere — warm colony glow, depth shadows
- These targets require PixiJS with texture sprites and shaders, not CSS/SVG

## Color Palette
- **Background:** clean warm grey (#f2f0ed)
- **Soil:** rich browns via texture sprites, not flat colors
- **Red colony:** warm amber glow, tunnel tint
- **Blue colony:** cool steel glow, tunnel tint
- **Surface:** dark greens, grass texture
- **UI:** semi-transparent dark inside widget, white/light for external panels

## Typography
- **Title:** Inter 500, 13px, #999, uppercase, letter-spacing 4px
- **Scoreboard:** Inter 600 (labels), JetBrains Mono (numbers)
- **Event log:** Inter 400 (text), JetBrains Mono 10px (timestamps)
- **Context:** Inter 300, 11px, italic
