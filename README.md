<div align="center">

# Yoko Fantasy

**A gameplay expansion mod for Brotato**

Extending the game with new systems, combat mechanics, enemies, items, weapons, content resources, and UI behavior.

[![GDScript](https://img.shields.io/badge/GDScript-Godot-478CBF?style=flat-square)](https://godotengine.org/)
[![Mod Loader](https://img.shields.io/badge/Mod%20Loader-6.0.0-5965FF?style=flat-square)](#-installation)
[![Version](https://img.shields.io/badge/Version-0.0.1-8A9E8B?style=flat-square)](#-compatibility--dependencies)
[![License](https://img.shields.io/badge/License-MIT-9E8F7E?style=flat-square)](LICENSE)

[Overview](#-overview) · [Features](#-features) · [Installation](#-installation) · [Architecture](#-architecture) · [Development](#-development)

</div>

---

## 📖 Overview

**Yoko Fantasy** is a **Brotato Mod Loader** project written in GDScript. It integrates with the base game through targeted script extensions and custom resource definitions rather than modifying the game as a standalone project.

The project is organized around independent gameplay systems and extension points. `mod_main.gd` acts as the integration entry point, while content resources, extension scripts, and localization files provide the implementation and data used by the mod.

> **Development status:** Yoko Fantasy is under active development. The current manifest version is `0.0.1`, with Mod Loader compatibility declared as `6.0.0`.

## ✨ Features

### 🧩 Gameplay Systems

- **Job system** integrated into run data, gameplay menus, and the end-of-run flow.
- **Soul mechanics** spanning player statistics, run data, and soul-related consumables.
- **Holy mechanics** affecting items and enemy behavior.
- **Erosion mechanics** implemented through dedicated items and effects.
- **Limited-item mechanics** for restricted item pools and progression rules.

### ⚔️ Combat & Weapons

The weapon and combat extensions currently cover multiple conditional and progression-based behaviors:

- Kill-based stat progression.
- Reload triggers from shooting and critical hits.
- Conditional weapon switching.
- Lightning-chain effects on hit.
- Weapon hit procs.
- Critical-damage overflow handling.
- Structure-related stat scaling.
- Damage clamping and reflection.
- Consumable-triggered damage and stat effects.

### 👾 Enemies & World Content

- Plant-themed enemy extensions.
- World Tree interactions and damage restrictions.
- Cursed enemy behavior.
- Additional enemy spawning rules.
- Kill-triggered buffs and healing.
- Conditional enemy stat changes.
- Enemy target-detection behavior.
- Lootworm-related extensions.
- Special interactions between enemies and world entities.

### 🛒 Shop & Run Systems

- Stat-based curses when entering or rerolling the shop.
- Tier-specific weapon upgrades.
- Conversion of selected weapons into items.
- Limited-item bonuses.
- Weapon-set bonuses.
- Shop synthesis behavior.
- Additional elite and enemy spawning rules.

### 🖥️ UI & Localization

The project extends gameplay and menu UI entry points and provides reusable localized entity-stat descriptions. Localization resources are kept separately under `translations/`.

## 🚀 Installation

Yoko Fantasy is intended to be installed as a **Brotato Mod Loader** package.

### Requirements

- **Brotato**
- **Brotato Mod Loader 6.0.0** or a compatible version
- **Yoko-NewContentLoader**
- **Yoko-MoreStatsContainer**

The current `manifest.json` declares `Yoko-NewContentLoader` and `Yoko-MoreStatsContainer` as dependencies and declares Mod Loader `6.0.0` as the compatible Mod Loader version.

### From a Release

1. Install Brotato.
2. Install a compatible Brotato Mod Loader version.
3. Install the required Yoko dependencies.
4. Download a Yoko Fantasy release package.
5. Extract the mod into your Mod Loader mods directory.
6. Start Brotato and verify that the mod is loaded by Mod Loader.

### From Source

```bash
git clone https://github.com/CYoJkoY/Yoko-Fantasy.git
cd Yoko-Fantasy
```

Deploy the repository through your normal Brotato Mod Loader development workflow.

> **Important:** This repository is a mod source tree, not a standalone Godot game project. A root `project.godot` is therefore not required by this repository structure.

## ⚙️ Architecture

Yoko Fantasy uses **Mod Loader script extensions** as its primary integration mechanism.

The runtime flow is centered around `mod_main.gd`:

```text
Brotato
   │
   ▼
Brotato Mod Loader
   │
   ▼
mod_main.gd
   │
   ├── Script extensions
   │     ├── Player / Run Data
   │     ├── Weapons
   │     ├── Enemies / Spawning
   │     ├── Shop / Waves
   │     ├── Turrets / Entities
   │     └── UI / Menus
   │
   ├── Content resources
   │     ├── NewContentData.tres
   │     └── NewContentDataDLC1.tres
   │
   └── Localization
         └── translations/
```

This keeps gameplay changes close to the base-game systems they extend instead of concentrating all behavior in one script.

| Component | Responsibility |
|---|---|
| `mod_main.gd` | Mod entry point and script-extension registration |
| `FantasyNewContent.gd` | New-content integration entry point |
| `NewContentData.tres` | Main content resource definitions |
| `NewContentDataDLC1.tres` | Additional content resource definitions |
| `content/` | Content resources and supporting data |
| `extensions/` | Base-game script extensions |
| `translations/` | Localization resources |
| `manifest.json` | Mod metadata, dependencies, and compatibility information |

## 🧠 Implementation Highlights

The current extension set targets a broad range of base-game systems, including:

- Player and player-run data.
- Run data and linked statistics.
- Melee and ranged weapons.
- Enemies and neutral entities.
- Entity spawning and entity services.
- Wave management.
- Shops and shop-related progression.
- Turrets, gardens, and wandering bots.
- Gameplay and menu UI.
- Music management.

The extension-oriented structure provides three practical benefits:

1. **Localized changes** — each extension is associated with a specific game responsibility.
2. **Composable mechanics** — separate systems can interact without requiring one monolithic gameplay script.
3. **Maintainability** — individual systems can be changed without restructuring the entire mod.

## 📁 Project Structure

```text
Yoko-Fantasy/
├── 📁 .github/                 # Repository automation and metadata
├── 📁 content/                 # Content resources and data
├── 📁 extensions/              # Base-game script extensions
├── 📁 translations/            # Localization resources
├── 📄 FantasyNewContent.gd     # New-content integration
├── 📄 NewContentData.tres      # Main content resource
├── 📄 NewContentDataDLC1.tres  # Additional content resource
├── 📄 manifest.json            # Mod metadata and dependencies
├── 📄 mod_main.gd              # Mod entry point
├── 📄 .editorconfig
├── 📄 .gitattributes
├── 📄 .gitignore
├── 📄 LICENSE
└── 📄 README.md
```

## 🛠️ Development

The project is primarily written in **GDScript** and follows the Brotato Mod Loader extension model.

When implementing a new mechanic:

1. Identify the base-game system that owns the behavior.
2. Add or modify the corresponding extension under `extensions/`.
3. Register the extension in `mod_main.gd`.
4. Add new content to the appropriate resource or `content/` directory.
5. Add user-facing strings to `translations/`.
6. Test the change with the declared Mod Loader and dependency versions.

Keep gameplay logic, content definitions, UI integration, and localization separated where practical.

## 📋 Compatibility & Dependencies

The current manifest declares:

| Component | Value |
|---|---|
| Mod Loader | `6.0.0` |
| Dependency | `Yoko-NewContentLoader` |
| Dependency | `Yoko-MoreStatsContainer` |
| Mod Version | `0.0.1` |
| Author | `Yoko` |
| Compatible Game Versions | Not specified in the manifest |

Because the manifest does not currently declare a compatible Brotato game-version list, compatibility should be verified against the user's installed game, Mod Loader, and dependency versions.

## 🤝 Contributing

Bug reports, gameplay feedback, and code contributions are welcome.

When reporting a problem, include:

- Brotato version.
- Mod Loader version.
- Yoko Fantasy version.
- Versions of the required Yoko dependencies.
- A clear description of the problem.
- Reproduction steps and relevant logs when available.

For code contributions, keep changes focused and preserve the existing extension-based architecture.

## 📄 License

Yoko Fantasy is released under the **MIT License**. Copyright © 2025 CYoJkoY.

See [`LICENSE`](LICENSE) for the complete license text.

---

<div align="center">

**Yoko Fantasy** · A Brotato content expansion project by Yoko

</div>
