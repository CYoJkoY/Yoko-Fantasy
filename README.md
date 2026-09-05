<div align="center">

  <div style="background-color: #1E1E1E; padding: 40px 20px; border-radius: 28px;">
    <div style="background: #2A2A2A; border-radius: 36px; padding: 42px 18px; margin-bottom: 28px;">
      <h1 style="color: #E6DED6; font-weight: 350; letter-spacing: 2px; margin: 18px 0 8px;">Yoko Fantasy</h1>
      <p style="color: #BEB8AE; font-size: 1.2em; max-width: 700px; margin: 0 auto;">A content-heavy Brotato mod built around new systems, enemies, weapons, items, and gameplay effects.</p>
      <p style="color: #8A9E8B; font-size: 0.95em; margin-top: 12px;">GDScript • Godot • Brotato Mod Loader 6.x</p>
    </div>

    <p>
      <img src="https://img.shields.io/badge/GDScript-Godot-8A9E8B?style=flat-square" alt="GDScript / Godot">
      <img src="https://img.shields.io/badge/Mod_Loader-6.0.0-7A8E8E?style=flat-square" alt="Mod Loader 6.0.0">
      <img src="https://img.shields.io/badge/Version-0.0.1-9E8F7E?style=flat-square" alt="Version 0.0.1">
      <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-8A9E8B?style=flat-square" alt="MIT License"></a>
    </p>

    <p style="word-spacing: 6px; margin-top: 20px;">
      <a href="#-overview" style="color: #8A9E8B; text-decoration: none; border-bottom: 1px dotted #5A6B6B;">Overview</a> &nbsp;•&nbsp;
      <a href="#-features" style="color: #8A9E8B; text-decoration: none; border-bottom: 1px dotted #5A6B6B;">Features</a> &nbsp;•&nbsp;
      <a href="#-installation" style="color: #8A9E8B; text-decoration: none; border-bottom: 1px dotted #5A6B6B;">Installation</a> &nbsp;•&nbsp;
      <a href="#-architecture" style="color: #8A9E8B; text-decoration: none; border-bottom: 1px dotted #5A6B6B;">Architecture</a> &nbsp;•&nbsp;
      <a href="#-development" style="color: #8A9E8B; text-decoration: none; border-bottom: 1px dotted #5A6B6B;">Development</a> &nbsp;•&nbsp;
      <a href="#-license" style="color: #8A9E8B; text-decoration: none; border-bottom: 1px dotted #5A6B6B;">License</a>
    </p>
  </div>

</div>

<div align="center">
  <svg width="160" height="12" viewBox="0 0 160 12" xmlns="http://www.w3.org/2000/svg" aria-label="separator">
    <path d="M2 6H158" stroke="#5A6B6B" stroke-width="1" stroke-dasharray="3 5"/>
    <circle cx="80" cy="6" r="3" fill="#8A9E8B"/>
  </svg>
</div>

## 📖 Overview

**Yoko Fantasy** is a Godot/GDScript-based content mod for **Brotato**. It extends the game through Mod Loader script extensions and custom content data, introducing additional gameplay systems, statistics, items, enemies, weapons, consumables, UI behavior, and special effects.

The project is designed as a modular content expansion rather than a standalone game. Its runtime entry point installs a collection of targeted script extensions into the base game, while resource files provide the associated content definitions. citeturn6file0

> **Note**
> This project is currently under active development. The manifest identifies the current release as `0.0.1` and requires Mod Loader `6.0.0`. citeturn5file0

## ✨ Features

### 🧩 New Gameplay Systems

The extension set contains several larger gameplay systems, including:

- **Job system** — integrates job-related behavior into run data, menus, and the end-of-run flow.
- **Soul mechanics** — introduces soul-related statistics and consumable interactions across player and run data.
- **Holy mechanics** — adds holy-related statistics and enemy interactions.
- **Erosion mechanics** — provides a dedicated item/effect framework for erosion-themed content.

These systems are distributed across multiple script extensions so individual areas of the base game can be modified without replacing the entire game implementation. citeturn6file0

### ⚔️ Combat & Weapon Extensions

Yoko Fantasy extends both melee and ranged weapon behavior with additional combat effects, including:

- Kill-based stat progression.
- Reload triggers based on shooting and critical hits.
- Conditional weapon switching.
- Lightning-chain hit effects.
- Weapon hit proc support.
- Critical-damage overflow handling.
- Additional scaling behavior for structured stats.

The same effect families are integrated into both melee and ranged weapon extensions where appropriate. citeturn6file0

### 👾 Enemies & World Content

The mod also expands enemy and world behavior with mechanics such as:

- Plant-themed enemy content.
- World Tree interactions.
- Cursed enemy behavior.
- Additional enemy spawning rules.
- Kill-triggered buffs and healing.
- Conditional enemy stat growth.
- Target detection behavior.
- Special restrictions on damaging specific entities.

These behaviors are distributed between enemy, spawner, neutral, lootworm, and related extensions. citeturn6file0

### 🛒 Shop & Run Systems

Shop and run-data extensions provide additional progression rules, including:

- Stat-based curse interactions when entering or rerolling the shop.
- Tier-specific weapon upgrades.
- Converting selected weapons into items.
- Limited-item bonuses.
- Weapon-set bonuses.
- Shop synthesis behavior.
- Additional wave and elite spawning rules.

citeturn6file0

### 🖥️ UI & Localization

The project modifies several UI entry points and provides reusable localized descriptions for entity statistics. It also contains dedicated translation resources for the mod's content. citeturn6file0

## 🚀 Installation

Yoko Fantasy is distributed as a Mod Loader package.

### Requirements

- **Brotato**
- **Godot Mod Loader 6.0.0 or compatible version**
- **Yoko New Content Loader**
- **Yoko More Stats Container**

The current manifest declares `Yoko-NewContentLoader` and `Yoko-MoreStatsContainer` as dependencies and specifies Mod Loader `6.0.0`. citeturn5file0

### From a Release Package

1. Install Brotato and a compatible version of Godot Mod Loader.
2. Install the two required Yoko dependencies:
   - `Yoko-NewContentLoader`
   - `Yoko-MoreStatsContainer`
3. Download the Yoko Fantasy release package.
4. Extract the mod into your Mod Loader mods directory.
5. Launch Brotato and allow Mod Loader to load the package.

### From Source

Clone the repository into a local development directory:

```bash
git clone https://github.com/CYoJkoY/Yoko-Fantasy.git
cd Yoko-Fantasy
```

Then deploy the repository as a Mod Loader package according to your local Brotato mod-development workflow.

> **Note**
> The repository is a mod project, not a conventional standalone Godot game. The presence of `.gd`, `.tres`, and Mod Loader-specific files reflects that architecture. citeturn4file0turn6file0

## ⚙️ Architecture

Yoko Fantasy uses Mod Loader script extensions as its primary integration mechanism. The root `mod_main.gd` establishes the mod directory and registers a collection of extension scripts through `ModLoaderMod.install_script_extension()`. citeturn6file0

The main content layers are:

| Layer | Purpose |
|---|---|
| `mod_main.gd` | Mod entry point and script-extension registration |
| `FantasyNewContent.gd` | New-content integration entry point |
| `NewContentData.tres` | Main content resource definitions |
| `NewContentDataDLC1.tres` | Additional content resource definitions |
| `content/` | Content resources and supporting data |
| `extensions/` | Script extensions applied to the base game |
| `translations/` | Localization resources |
| `manifest.json` | Mod metadata, dependencies, and compatibility information |

The repository root currently contains these major components alongside the project license and configuration files. citeturn4file0turn5file0

## 🧠 Implementation Highlights

The extension architecture separates modifications by gameplay responsibility. Instead of concentrating all behavior in a single script, the mod hooks into specific base-game systems such as the player, run data, shop, wave manager, entity spawner, weapons, turrets, and UI. citeturn6file0

This approach provides several practical advantages:

- **Localized changes** — each extension targets a specific part of the base game.
- **Composable mechanics** — systems can share effects without requiring a monolithic implementation.
- **Easier maintenance** — individual gameplay areas can be updated independently.
- **Clear integration points** — the extension list in `mod_main.gd` documents where each mechanic enters the game.

## 📁 Project Structure

```text
Yoko-Fantasy/
├── 📁 .github/
├── 📁 content/
├── 📁 extensions/
├── 📁 translations/
├── 📄 FantasyNewContent.gd
├── ⚙️ NewContentData.tres
├── ⚙️ NewContentDataDLC1.tres
├── ⚙️ manifest.json
├── 📄 mod_main.gd
├── 📄 .editorconfig
├── 📄 .gitattributes
├── 📄 .gitignore
├── 📄 LICENSE
└── 📄 README.md
```

The structure above reflects the repository's current top-level layout. citeturn4file0

## 🛠️ Development

The project is written primarily in **GDScript** and is structured for development as a Brotato Mod Loader extension package. The repository metadata identifies GDScript as its primary language. fileciteturn1file0

When adding new mechanics, keep the existing extension-oriented organization in mind:

1. Identify the base-game script or system that needs to be extended.
2. Add the corresponding extension under `extensions/`.
3. Register the extension in `mod_main.gd`.
4. Keep new content definitions in the appropriate `.tres` resources.
5. Add localization entries under `translations/` when user-facing text is introduced.
6. Verify compatibility with the declared Mod Loader and dependency versions.

For larger mechanics, follow the existing separation between gameplay systems, effects, content definitions, and UI integration. The comments in `mod_main.gd` currently document the intended responsibility of each extension. citeturn6file0

## 📋 Compatibility & Dependencies

The current manifest declares:

| Component | Requirement |
|---|---|
| Mod Loader | `6.0.0` |
| Dependency | `Yoko-NewContentLoader` |
| Dependency | `Yoko-MoreStatsContainer` |
| Current Version | `0.0.1` |
| Author | `Yoko` |

The manifest does not currently specify a compatible Brotato game-version range. citeturn5file0

## 🤝 Contributing

Contributions, bug reports, and gameplay feedback are welcome.

When reporting an issue, include:

- Brotato version.
- Mod Loader version.
- Yoko Fantasy version.
- Installed Yoko dependencies and their versions.
- A clear description of the problem.
- Reproduction steps and relevant logs when available.

For code contributions, keep changes focused and preserve the existing Mod Loader extension architecture.

## 📄 License

Yoko Fantasy is released under the **MIT License**. Copyright © 2025 CYoJkoY. See [`LICENSE`](LICENSE) for the complete license text. citeturn7file0

---

<div align="center">
  <sub>Yoko Fantasy • A Brotato content expansion project by Yoko</sub>
</div>
