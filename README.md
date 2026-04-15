# NewLife Simulation

A deep text-based life simulation game inspired by BitLife, built with **Godot 4.x** (GDScript).

## Features

- **5 Life Phases**: Baby → Child → Teen → Adult → Elder
- **Rich Event System**: 45+ events with branching choices across all phases
- **25 Careers**: From Fast Food to Doctor, Artist to Politician
- **33 Personality Traits**: Each affecting gameplay and stats
- **Full Save System**: Auto-save, 5 manual slots, completed lives archive
- **Bilingual**: English + Portuguese (BR) from day one
- **Monetization Ready**: AdMob ads + Google Play In-App Purchases

## Tech Stack

- **Engine**: Godot 4.3 (GDScript)
- **Ads**: [godot-admob-plugin](https://github.com/poingstudios/godot-admob-plugin)
- **IAP**: [godot-google-play-billing](https://github.com/godot-sdk-integrations/godot-google-play-billing)
- **Steam**: [GodotSteam](https://codeberg.org/godotsteam) (Phase 9)
- **UI Art**: ComfyUI + Stable Diffusion (DreamShaper)

## Project Structure

```
NewLife_Simulation/
├── assets/         # Fonts, icons, sounds, UI images, themes
├── data/           # JSON data (events, careers, traits, names, localization)
├── scenes/         # Godot scene files (.tscn)
├── scripts/        # GDScript source code
│   ├── autoloads/  # Singleton managers
│   ├── data_models/ # Resource classes
│   └── ui/         # Screen scripts
└── project.godot   # Project configuration
```

## Getting Started

1. Install [Godot 4.3+](https://godotengine.org/download)
2. Clone this repo
3. Open `project.godot` in Godot
4. Press F5 to run

## Target Platforms

- **Google Play Store** (primary)
- **Steam** (future)

## License

All rights reserved.
